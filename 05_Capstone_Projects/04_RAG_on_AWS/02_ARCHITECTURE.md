# 02 — Architecture: RAG System on AWS

## System Overview

A RAG system has two separate data flows: **write** (ingest documents) and **read** (answer queries). Separating them means ingestion spikes don't affect query latency, and each can scale independently.

```
WRITE PATH (document ingestion)
───────────────────────────────
User uploads PDF
    |
    v
S3 Bucket (documents/)
    |
    | s3:ObjectCreated event
    v
EventBridge Rule
    |
    | runs ECS task (one-off, not a service)
    v
ECS Ingestion Task (Fargate)
    |  1. Download PDF from S3
    |  2. pdfplumber → extract text
    |  3. Chunk text (512 tokens, 50 overlap)
    |  4. sentence-transformers → 384-dim embeddings
    |  5. INSERT INTO embeddings (doc_id, chunk, embedding)
    v
RDS Postgres + pgvector
    (stores: doc_id, chunk_text, embedding VECTOR(384))


READ PATH (query answering)
───────────────────────────
User sends question
    |
    v
ALB → ECS API Service (always running, 2 tasks)
    |  1. Embed the question (same model)
    |  2. SELECT ... ORDER BY embedding <=> $query_vec LIMIT 5
    |  3. Concatenate top-5 chunks as context
    |  4. Call Claude/OpenAI API with: context + question
    v
Return answer to user
```

---

## pgvector Query Anatomy

pgvector adds three distance operators. For text similarity, cosine distance (`<=>`) is usually best.

```sql
-- Setup (run once after CREATE EXTENSION vector)
CREATE TABLE embeddings (
    id          SERIAL PRIMARY KEY,
    doc_id      TEXT NOT NULL,           -- S3 key of source document
    chunk_index INT  NOT NULL,           -- position in document
    chunk_text  TEXT NOT NULL,           -- original text
    embedding   VECTOR(384) NOT NULL     -- 384-dim float vector
);

-- Index for fast approximate nearest-neighbor search
CREATE INDEX ON embeddings
    USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);                  -- tune: sqrt(row_count)

-- Query: find 5 most similar chunks to a question embedding
SELECT chunk_text, 1 - (embedding <=> $1::vector) AS similarity
FROM embeddings
ORDER BY embedding <=> $1::vector        -- <=> = cosine distance (lower = more similar)
LIMIT 5;
```

The `$1` parameter is a Python list of 384 floats, passed as a string like `[0.12, -0.34, ...]`.

---

## S3 Event → ECS Task Flow

S3 natively integrates with EventBridge. Every object creation triggers an event; EventBridge rules filter and route it.

```
S3 Bucket
    |
    | EventBridge notification (all s3:ObjectCreated events)
    v
EventBridge Rule
    pattern: { "source": ["aws.s3"], "detail-type": ["Object Created"],
               "detail": { "bucket": { "name": ["myapp-documents"] } } }
    |
    | target: ECS task (one-shot run, not a service)
    v
aws_cloudwatch_event_target (type: "EcsParameters")
    task_definition_arn: ingestion task def
    launch_type: FARGATE
    network_configuration: private subnets
    |
    | environment variable injection:
    |   S3_BUCKET = event.detail.bucket.name
    |   S3_KEY    = event.detail.object.key
    v
ECS Ingestion Task starts, processes the file, exits
```

---

## pgvector vs ChromaDB Trade-offs

| Aspect | ChromaDB (local) | pgvector on RDS |
|---|---|---|
| Setup | Zero config | Create extension, create table, create index |
| Persistence | In-memory or local file | Fully durable, backed up by RDS |
| Multi-process | No (single process) | Yes (any process with DB access) |
| Scalability | Limited by RAM | RDS scales storage + read replicas |
| SQL queries | Not supported | Full SQL — join vectors with metadata |
| Managed | No | Yes (backups, patching, Multi-AZ) |
| Cost | Free | ~$25+/month (db.t3.micro) |
| Query latency | <1ms (in-process) | 5-50ms (network + index) |

For production with multiple services, pgvector wins on every operational dimension except latency.

---

## Data Flow: Upload to Answer

```
1. User uploads "product-manual.pdf" to s3://myapp-documents/product-manual.pdf

2. Ingestion Task runs:
   - Downloads PDF (2.3 MB)
   - Extracts 47 pages of text (~28,000 tokens)
   - Chunks into 54 chunks of 512 tokens with 50-token overlap
   - Embeds all 54 chunks (sentence-transformers, ~3s)
   - Inserts 54 rows into embeddings table

3. User sends: POST /query {"question": "How do I reset the device?"}

4. API Task:
   - Embeds question: [0.12, -0.34, 0.89, ...]  (384 floats)
   - Queries pgvector: SELECT chunk_text ORDER BY embedding <=> $1 LIMIT 5
   - Gets 5 relevant chunks about device reset procedures
   - Sends to Claude: "Given this context: <chunks> Answer: How do I reset the device?"
   - Returns: "To reset the device, hold the power button for 10 seconds..."
```

---

## 📂 Navigation

**Prev:** [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md) &nbsp;&nbsp; **Next:** [05 — Serverless AI Agent](../05_Serverless_AI_Agent/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
