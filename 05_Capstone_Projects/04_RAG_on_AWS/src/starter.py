"""
Project 04: RAG System on AWS — STARTER
========================================
Fill in all TODO sections to build the RAG API and ingestion worker.

Two entry points:
  - api/main.py    → FastAPI app (query endpoint)
  - ingestion/worker.py → one-shot ECS task (S3 → chunk → embed → store)

Usage (local dev):
  pip install -r requirements.txt
  export DB_HOST=localhost DB_PASSWORD=secret DB_NAME=ragdb
  uvicorn api.main:app --reload
"""

import os
import logging
from typing import Optional

import psycopg2
import numpy as np
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer

logger = logging.getLogger(__name__)

# ── Configuration (from environment variables) ────────────────────────────────

DB_HOST     = os.environ.get("DB_HOST", "localhost")
DB_PORT     = int(os.environ.get("DB_PORT", "5432"))
DB_NAME     = os.environ.get("DB_NAME", "ragdb")
DB_USER     = os.environ.get("DB_USER", "appuser")
DB_PASSWORD = os.environ.get("DB_PASSWORD")  # injected by Secrets Manager via ECS

MODEL_NAME  = os.environ.get("EMBEDDING_MODEL", "all-MiniLM-L6-v2")  # 384-dim embeddings
TOP_K       = int(os.environ.get("TOP_K", "5"))

# ── FastAPI App ───────────────────────────────────────────────────────────────

app = FastAPI(title="RAG API", version="1.0.0")

# ── Models ────────────────────────────────────────────────────────────────────

class QueryRequest(BaseModel):
    question: str
    top_k: Optional[int] = TOP_K

class QueryResponse(BaseModel):
    answer: str
    sources: list[str]
    chunks_used: int

# ── Startup: Load embedding model and connect to DB ───────────────────────────

_model: Optional[SentenceTransformer] = None
_conn = None

@app.on_event("startup")
def startup():
    global _model, _conn
    # TODO: Load the sentence-transformers model (MODEL_NAME)
    # This is slow (~2s) — do it at startup, not per request
    _model = None  # replace with SentenceTransformer(MODEL_NAME)

    # TODO: Connect to Postgres using psycopg2
    # Use the DB_* environment variables above
    # Call register_vector(conn) from pgvector.psycopg2 to enable VECTOR type
    _conn = None  # replace with psycopg2.connect(...)

# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/query", response_model=QueryResponse)
def query(request: QueryRequest):
    """
    1. Embed the question using the sentence-transformers model
    2. Query pgvector for the top-k most similar chunks
    3. Call an LLM (or just return the chunks directly for the starter)
    4. Return the answer and source chunk IDs
    """
    if _model is None or _conn is None:
        raise HTTPException(status_code=503, detail="Service not ready")

    # TODO: Embed the question
    # question_embedding = _model.encode(request.question).tolist()

    # TODO: Query pgvector for top-k chunks
    # SQL: SELECT chunk_text, doc_id FROM embeddings
    #      ORDER BY embedding <=> %s LIMIT %s
    # Pass: (question_embedding, request.top_k)

    # TODO: Build context string from retrieved chunks

    # TODO: Call LLM (optional — can return raw chunks for starter)
    # For the starter, just return the top chunk as the "answer"

    return QueryResponse(
        answer="TODO: implement query logic",
        sources=[],
        chunks_used=0,
    )


# ==============================================================================
# INGESTION WORKER (run as a separate ECS task, not part of the API)
# Save this as ingestion/worker.py
# ==============================================================================

"""
ingestion/worker.py — Run as one-shot ECS Fargate task

Environment variables (injected by EventBridge input_transformer):
  S3_BUCKET — the bucket name
  S3_KEY    — the object key (e.g., "documents/my-file.pdf")

Steps:
  1. Download PDF from S3
  2. Extract text with pdfplumber
  3. Chunk text
  4. Embed each chunk
  5. Upsert into pgvector embeddings table
  6. Exit 0 on success, nonzero on failure
"""


def run_ingestion():
    # TODO: Read S3_BUCKET and S3_KEY from environment
    s3_bucket = os.environ.get("S3_BUCKET")
    s3_key    = os.environ.get("S3_KEY")
    if not s3_bucket or not s3_key:
        raise ValueError("S3_BUCKET and S3_KEY must be set")

    # TODO: Download the PDF from S3 to /tmp using boto3
    # local_path = f"/tmp/{os.path.basename(s3_key)}"
    # boto3.client("s3").download_file(s3_bucket, s3_key, local_path)

    # TODO: Extract text from the PDF using pdfplumber

    # TODO: Chunk the text (512 words, 50 word overlap)

    # TODO: Load sentence-transformers model and embed all chunks
    # Use batch encoding: model.encode(chunks, batch_size=32, show_progress_bar=True)

    # TODO: Connect to Postgres and upsert embeddings
    # Use a transaction: begin, delete existing rows for doc_id, insert new rows, commit

    print(f"Ingestion complete for {s3_key}")


if __name__ == "__main__":
    run_ingestion()
