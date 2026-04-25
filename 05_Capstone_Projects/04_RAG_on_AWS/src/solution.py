"""
Project 04: RAG System on AWS — COMPLETE SOLUTION
==================================================
Full implementation of:
  - RAG API (FastAPI + pgvector + sentence-transformers + Anthropic Claude)
  - Ingestion worker (S3 download + pdfplumber + embed + upsert to pgvector)

Usage (local):
  pip install fastapi uvicorn psycopg2-binary pgvector sentence-transformers
      pdfplumber boto3 anthropic python-multipart

  export DB_HOST=localhost DB_PASSWORD=secret
  uvicorn solution:app --reload --port 8000

  # Run ingestion locally:
  S3_BUCKET=my-bucket S3_KEY=documents/test.pdf python solution.py ingest
"""

import os
import sys
import json
import logging
import tempfile
from contextlib import asynccontextmanager
from typing import Optional

import boto3
import psycopg2
import anthropic
import pdfplumber
import numpy as np
from fastapi import FastAPI, HTTPException
from pgvector.psycopg2 import register_vector
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

# ── Configuration ─────────────────────────────────────────────────────────────

DB_HOST     = os.environ.get("DB_HOST", "localhost")
DB_PORT     = int(os.environ.get("DB_PORT", "5432"))
DB_NAME     = os.environ.get("DB_NAME", "ragdb")
DB_USER     = os.environ.get("DB_USER", "appuser")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")  # injected by ECS Secrets Manager

MODEL_NAME      = os.environ.get("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
EMBEDDING_DIM   = 384  # ← all-MiniLM-L6-v2 produces 384-dimensional embeddings
TOP_K           = int(os.environ.get("TOP_K", "5"))
CHUNK_SIZE      = int(os.environ.get("CHUNK_SIZE", "512"))
CHUNK_OVERLAP   = int(os.environ.get("CHUNK_OVERLAP", "50"))
ANTHROPIC_MODEL = os.environ.get("ANTHROPIC_MODEL", "claude-3-haiku-20240307")

# ── Database helpers ──────────────────────────────────────────────────────────

def get_db_connection():
    """Return a new psycopg2 connection with pgvector registered."""
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        sslmode="require",          # ← always require SSL to RDS
        connect_timeout=10,
    )
    register_vector(conn)           # ← teaches psycopg2 to read/write VECTOR columns
    return conn

def ensure_schema(conn):
    """Create tables and indexes if they don't exist yet."""
    with conn.cursor() as cur:
        cur.execute("CREATE EXTENSION IF NOT EXISTS vector")

        cur.execute("""
            CREATE TABLE IF NOT EXISTS embeddings (
                id          SERIAL PRIMARY KEY,
                doc_id      TEXT NOT NULL,
                chunk_index INT  NOT NULL,
                chunk_text  TEXT NOT NULL,
                embedding   VECTOR(%s) NOT NULL,   -- pgvector column type
                created_at  TIMESTAMPTZ DEFAULT NOW(),
                UNIQUE (doc_id, chunk_index)
            )
        """, (EMBEDDING_DIM,))

        # IVFFlat index — approximate nearest-neighbor, much faster than exact search
        # lists = sqrt(row_count) is a good starting point
        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_embeddings_cosine
            ON embeddings USING ivfflat (embedding vector_cosine_ops)
            WITH (lists = 50)
        """)

        cur.execute("""
            CREATE INDEX IF NOT EXISTS idx_embeddings_doc_id
            ON embeddings (doc_id)
        """)

    conn.commit()
    logger.info("Schema ready")

# ── Text processing ───────────────────────────────────────────────────────────

def extract_text_from_pdf(path: str) -> str:
    """Extract all text from a PDF using pdfplumber."""
    pages = []
    with pdfplumber.open(path) as pdf:
        for i, page in enumerate(pdf.pages):
            text = page.extract_text()
            if text:
                pages.append(text)
    return "\n\n".join(pages)

def chunk_text(text: str, chunk_size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    """Split text into overlapping word-count chunks for consistent embedding coverage."""
    words = text.split()
    if not words:
        return []

    chunks = []
    i = 0
    while i < len(words):
        chunk = " ".join(words[i : i + chunk_size])
        if chunk.strip():
            chunks.append(chunk)
        i += chunk_size - overlap  # ← slide by (chunk_size - overlap) to create overlap

    return chunks

# ── App state (loaded at startup) ─────────────────────────────────────────────

_model: Optional[SentenceTransformer] = None
_conn  = None
_anthropic_client: Optional[anthropic.Anthropic] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load heavy resources once at startup, clean up on shutdown."""
    global _model, _conn, _anthropic_client

    logger.info("Loading embedding model: %s", MODEL_NAME)
    _model = SentenceTransformer(MODEL_NAME)  # ← reads from ~/.cache if pre-downloaded

    logger.info("Connecting to Postgres at %s", DB_HOST)
    _conn = get_db_connection()
    ensure_schema(_conn)

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if api_key:
        _anthropic_client = anthropic.Anthropic(api_key=api_key)
        logger.info("Anthropic client ready")
    else:
        logger.warning("ANTHROPIC_API_KEY not set — will return raw chunks instead of LLM answer")

    yield  # ← server runs here

    if _conn:
        _conn.close()

# ── FastAPI App ───────────────────────────────────────────────────────────────

app = FastAPI(title="RAG API", version="1.0.0", lifespan=lifespan)

class QueryRequest(BaseModel):
    question: str
    top_k: Optional[int] = TOP_K

class QueryResponse(BaseModel):
    answer: str
    sources: list[str]
    chunks_used: int

@app.get("/health")
def health():
    db_ok = False
    try:
        with _conn.cursor() as cur:
            cur.execute("SELECT 1")
        db_ok = True
    except Exception:
        pass
    return {"status": "ok" if db_ok else "degraded", "db": db_ok}

@app.post("/query", response_model=QueryResponse)
def query(request: QueryRequest):
    """Embed the question, retrieve top-k chunks, generate an answer."""
    if _model is None:
        raise HTTPException(status_code=503, detail="Embedding model not loaded")
    if _conn is None:
        raise HTTPException(status_code=503, detail="Database not connected")

    # 1. Embed the question using the same model used during ingestion
    question_embedding = _model.encode(request.question).tolist()

    # 2. Query pgvector: cosine similarity (lower distance = more similar)
    with _conn.cursor() as cur:
        cur.execute(
            """
            SELECT chunk_text, doc_id,
                   1 - (embedding <=> %s::vector) AS similarity
            FROM embeddings
            ORDER BY embedding <=> %s::vector
            LIMIT %s
            """,
            (question_embedding, question_embedding, request.top_k)
        )
        results = cur.fetchall()

    if not results:
        return QueryResponse(
            answer="No relevant documents found. Please upload documents first.",
            sources=[],
            chunks_used=0,
        )

    chunks    = [row[0] for row in results]
    doc_ids   = list(dict.fromkeys(row[1] for row in results))  # deduplicated, order preserved
    context   = "\n\n---\n\n".join(f"[Source: {row[1]}]\n{row[0]}" for row in results)

    # 3. Generate answer with Claude (or return raw chunks if no API key)
    if _anthropic_client:
        message = _anthropic_client.messages.create(
            model=ANTHROPIC_MODEL,
            max_tokens=1024,
            messages=[{
                "role": "user",
                "content": (
                    f"Answer the question using ONLY the context below. "
                    f"If the answer isn't in the context, say so.\n\n"
                    f"Context:\n{context}\n\n"
                    f"Question: {request.question}"
                )
            }]
        )
        answer = message.content[0].text
    else:
        # Fallback: return the top chunk directly
        answer = f"(No LLM configured) Top result:\n\n{chunks[0]}"

    return QueryResponse(
        answer=answer,
        sources=doc_ids,
        chunks_used=len(chunks),
    )

@app.get("/documents")
def list_documents():
    """List all ingested documents and their chunk counts."""
    if _conn is None:
        raise HTTPException(status_code=503, detail="Database not connected")
    with _conn.cursor() as cur:
        cur.execute("SELECT doc_id, COUNT(*) as chunks FROM embeddings GROUP BY doc_id ORDER BY doc_id")
        rows = cur.fetchall()
    return {"documents": [{"doc_id": r[0], "chunks": r[1]} for r in rows]}


# ==============================================================================
# INGESTION WORKER
# ==============================================================================

def run_ingestion():
    """
    One-shot ingestion script. Reads S3_BUCKET + S3_KEY from environment,
    downloads the PDF, chunks it, embeds it, and upserts to pgvector.
    Called as the ECS task entry point.
    """
    s3_bucket = os.environ["S3_BUCKET"]
    s3_key    = os.environ["S3_KEY"]
    doc_id    = s3_key  # use S3 key as the document identifier

    logger.info("Starting ingestion: s3://%s/%s", s3_bucket, s3_key)

    # 1. Download from S3
    s3 = boto3.client("s3")
    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
        local_path = tmp.name
    s3.download_file(s3_bucket, s3_key, local_path)
    logger.info("Downloaded to %s", local_path)

    # 2. Extract text
    text = extract_text_from_pdf(local_path)
    logger.info("Extracted %d characters", len(text))

    # 3. Chunk
    chunks = chunk_text(text, CHUNK_SIZE, CHUNK_OVERLAP)
    logger.info("Created %d chunks", len(chunks))

    # 4. Embed (batch for efficiency)
    model = SentenceTransformer(MODEL_NAME)
    embeddings = model.encode(chunks, batch_size=32, show_progress_bar=True)
    logger.info("Embedded %d chunks", len(embeddings))

    # 5. Upsert to pgvector
    conn = get_db_connection()
    ensure_schema(conn)

    with conn.cursor() as cur:
        # Delete existing chunks for this document (re-ingest = full replacement)
        cur.execute("DELETE FROM embeddings WHERE doc_id = %s", (doc_id,))
        deleted = cur.rowcount
        if deleted:
            logger.info("Deleted %d existing rows for doc_id=%s", deleted, doc_id)

        # Insert all new chunks
        for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            cur.execute(
                """
                INSERT INTO embeddings (doc_id, chunk_index, chunk_text, embedding)
                VALUES (%s, %s, %s, %s)
                """,
                (doc_id, i, chunk, embedding.tolist())
            )

    conn.commit()
    conn.close()
    logger.info("Ingestion complete: %d chunks stored for %s", len(chunks), doc_id)

    # Clean up temp file
    os.unlink(local_path)


# ==============================================================================
# TERRAFORM CONFIGURATION (embedded for reference — save as main.tf in practice)
# ==============================================================================

TERRAFORM_CONFIG = '''
# Run as: terraform apply -var="db_password=$DB_PASS" -var="vpc_id=vpc-xxx" ...

resource "aws_s3_bucket" "documents" {
  bucket = "${var.project_name}-documents-${var.account_id}"
  tags   = { Name = "${var.project_name}-documents" }
}

resource "aws_s3_bucket_notification" "documents" {
  bucket      = aws_s3_bucket.documents.id
  eventbridge = true  # ← sends all events to EventBridge
}

resource "aws_db_instance" "postgres" {
  identifier           = "${var.project_name}-db"
  engine               = "postgres"
  engine_version       = "16.1"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = "ragdb"
  username             = "appuser"
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible  = false
  skip_final_snapshot  = true
  # pgvector ships with Postgres 16 on RDS — no special setup needed for the binary
  # You still need: CREATE EXTENSION vector; in the DB
}

resource "aws_cloudwatch_event_rule" "s3_upload" {
  name        = "${var.project_name}-s3-upload"
  description = "Trigger ingestion when a document is uploaded"
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail      = { bucket = { name = [aws_s3_bucket.documents.bucket] } }
  })
}

resource "aws_cloudwatch_event_target" "ingestion" {
  rule     = aws_cloudwatch_event_rule.s3_upload.name
  arn      = aws_ecs_cluster.main.arn
  role_arn = aws_iam_role.eventbridge_ecs.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.ingestion.arn
    launch_type         = "FARGATE"
    task_count          = 1
    network_configuration {
      subnets         = var.private_subnet_ids
      security_groups = [aws_security_group.ecs_tasks.id]
    }
  }

  input_transformer {
    input_paths    = { bucket = "$.detail.bucket.name", key = "$.detail.object.key" }
    input_template = <<-JSON
      {"containerOverrides": [{"name": "ingestion", "environment": [
        {"name": "S3_BUCKET", "value": "<bucket>"},
        {"name": "S3_KEY",    "value": "<key>"}
      ]}]}
    JSON
  }
}
'''


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "ingest":
        run_ingestion()
    else:
        import uvicorn
        uvicorn.run("solution:app", host="0.0.0.0", port=8000, reload=False)
