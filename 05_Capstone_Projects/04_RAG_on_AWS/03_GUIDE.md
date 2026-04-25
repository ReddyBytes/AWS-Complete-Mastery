# 03 — Guide: Deploy RAG System to AWS

This is a 🟠 Minimal Hints project. Each step describes what to build; you write the code and config. One hint per step.

---

## Step 1 — Enable pgvector on RDS

First, provision an RDS Postgres instance and run the setup SQL to enable the extension and create the embeddings table.

<details>
<summary>💡 Hint: How to run setup SQL against RDS</summary>

RDS lives in a private subnet — you can't connect directly from your laptop. Options:

1. Use an EC2 bastion host in the public subnet: `ssh ec2-user@<bastion-ip>`, then `psql -h <rds-endpoint> -U appuser -d ragdb`
2. Use `aws rds-data execute-statement` (requires Aurora Serverless)
3. Add your IP temporarily to the RDS security group, connect directly (development only)

After connecting:
```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS embeddings (
    id          SERIAL PRIMARY KEY,
    doc_id      TEXT NOT NULL,
    chunk_index INT  NOT NULL,
    chunk_text  TEXT NOT NULL,
    embedding   VECTOR(384) NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_embeddings_cosine
    ON embeddings USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 50);

CREATE INDEX IF NOT EXISTS idx_embeddings_doc_id ON embeddings (doc_id);
```
</details>

---

## Step 2 — Write the Python RAG API

Write a FastAPI application with two endpoints:
- `GET /health` — liveness probe
- `POST /query` — accepts `{"question": "..."}`, returns `{"answer": "...", "sources": [...]}`

The query endpoint embeds the question, searches pgvector, and calls an LLM with the retrieved context.

<details>
<summary>💡 Hint: pgvector connection with psycopg2</summary>

```python
import psycopg2
from pgvector.psycopg2 import register_vector

conn = psycopg2.connect(
    host=os.environ["DB_HOST"],
    dbname="ragdb",
    user="appuser",
    password=os.environ["DB_PASSWORD"],
    sslmode="require"
)
register_vector(conn)  # ← teaches psycopg2 to serialize/deserialize VECTOR type

# Query
cur = conn.cursor()
cur.execute(
    "SELECT chunk_text FROM embeddings ORDER BY embedding <=> %s LIMIT %s",
    (embedding.tolist(), 5)  # ← pass as Python list
)
chunks = [row[0] for row in cur.fetchall()]
```
</details>

---

## Step 3 — Write the Ingestion Script

The ingestion worker runs as an ECS task (not a service — it starts, processes one document, and exits). It reads `S3_BUCKET` and `S3_KEY` from environment variables (injected by EventBridge).

<details>
<summary>💡 Hint: PDF chunking strategy</summary>

```python
import pdfplumber

def extract_chunks(pdf_path: str, chunk_size: int = 512, overlap: int = 50) -> list[str]:
    words = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text() or ""
            words.extend(text.split())

    chunks = []
    i = 0
    while i < len(words):
        chunk = " ".join(words[i:i + chunk_size])
        chunks.append(chunk)
        i += chunk_size - overlap  # ← slide window with overlap for context continuity
    return chunks
```
</details>

---

## Step 4 — Containerize Both Services

Write two Dockerfiles: one for the API (`api/Dockerfile`) and one for the ingestion worker (`ingestion/Dockerfile`). They can share a base image but have different entry points.

<details>
<summary>💡 Hint: Multi-stage build to reduce image size</summary>

sentence-transformers downloads model weights at runtime by default. Instead, download them during the Docker build so the container starts faster:

```dockerfile
FROM python:3.11-slim AS builder
RUN pip install sentence-transformers
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')"
# Model cached in ~/.cache/huggingface/

FROM python:3.11-slim
COPY --from=builder /root/.cache /root/.cache  # ← copy pre-downloaded model
COPY requirements.txt .
RUN pip install -r requirements.txt
```
</details>

---

## Step 5 — Terraform: RDS with pgvector, ECS services, S3 bucket

Write the Terraform configuration for all infrastructure. Key requirements:
- RDS Postgres 16 with `auto_minor_version_upgrade = true` (pgvector updates come this way)
- Two ECR repos (api, ingestion)
- Two ECS task definitions (different images, different IAM roles)
- One ECS service (API — always running)
- S3 bucket with EventBridge notifications enabled
- IAM role for ingestion task with `s3:GetObject` on the documents bucket

<details>
<summary>💡 Hint: Enable EventBridge on S3 bucket</summary>

```hcl
resource "aws_s3_bucket_notification" "documents" {
  bucket      = aws_s3_bucket.documents.id
  eventbridge = true  # ← sends ALL S3 events to EventBridge (replaces SNS/Lambda triggers)
}
```
</details>

---

## Step 6 — Configure S3 → EventBridge → ECS Task Trigger

Create an EventBridge rule that matches S3 ObjectCreated events for the documents bucket and triggers the ingestion ECS task.

<details>
<summary>💡 Hint: ECS task target in EventBridge</summary>

```hcl
resource "aws_cloudwatch_event_rule" "s3_upload" {
  name        = "${var.project_name}-s3-upload"
  description = "Trigger ingestion on new S3 document"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = { name = [aws_s3_bucket.documents.bucket] }
      object = { key = [{ prefix = "documents/" }] }
    }
  })
}

resource "aws_cloudwatch_event_target" "ingestion" {
  rule     = aws_cloudwatch_event_rule.s3_upload.name
  arn      = aws_ecs_cluster.main.arn
  role_arn = aws_iam_role.eventbridge_ecs.arn  # ← EventBridge needs permission to run ECS tasks

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.ingestion.arn
    launch_type         = "FARGATE"
    task_count          = 1

    network_configuration {
      subnets         = var.private_subnet_ids
      security_groups = [aws_security_group.ecs_tasks.id]
    }
  }

  # Inject S3 event details as environment variable overrides
  input_transformer {
    input_paths = {
      bucket = "$.detail.bucket.name"
      key    = "$.detail.object.key"
    }
    input_template = <<-JSON
      {
        "containerOverrides": [{
          "name": "ingestion",
          "environment": [
            {"name": "S3_BUCKET", "value": "<bucket>"},
            {"name": "S3_KEY",    "value": "<key>"}
          ]
        }]
      }
    JSON
  }
}
```
</details>

---

## Step 7 — Upload Document, Verify Ingestion, Query

```bash
# Apply Terraform
terraform apply

# Upload a test PDF
aws s3 cp test-document.pdf s3://$(terraform output -raw documents_bucket)/documents/test-document.pdf

# Watch for the ingestion task to start (within ~30 seconds)
watch -n 5 "aws ecs list-tasks --cluster myapp-cluster --desired-status RUNNING"

# After ingestion task finishes, verify embeddings
# (connect to RDS via bastion or temporarily open port)
psql -h $(terraform output -raw rds_endpoint) -U appuser -d ragdb \
  -c "SELECT COUNT(*), doc_id FROM embeddings GROUP BY doc_id;"

# Query the API
ALB=$(terraform output -raw alb_dns_name)
curl -X POST http://${ALB}/query \
  -H "Content-Type: application/json" \
  -d '{"question": "What is the main topic of the document?"}'
```

---

## 📂 Navigation

**Prev:** [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md) &nbsp;&nbsp; **Next:** [05 — Serverless AI Agent](../05_Serverless_AI_Agent/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
