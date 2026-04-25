# 01 — Mission: Deploy RAG System to AWS (ECS + pgvector on RDS)

## The Scenario

Your RAG system works locally: upload a PDF, it chunks the text, embeds it with sentence-transformers, stores vectors in ChromaDB, and answers questions with semantic search. It runs on your laptop.

The problem: ChromaDB is an in-process vector store — it lives in the container's filesystem. If the container restarts, your vectors are gone. Multiple containers can't share it. You can't query it from outside the process.

The solution: replace ChromaDB with **pgvector** on RDS Postgres. pgvector is a Postgres extension that adds a vector column type and similarity search operators. Your vectors live in a managed, backed-up, multi-AZ Postgres database that any ECS task can reach. The architecture splits into two services: an API that answers queries, and an ingestion worker that processes new documents uploaded to S3.

---

## What You'll Build

- **RDS Postgres with pgvector** — managed vector store with standard SQL queries
- **ECS API service** — FastAPI app that takes questions, searches pgvector, returns answers
- **ECS ingestion worker** — runs when triggered by S3 event, chunks + embeds new documents
- **S3 bucket** — document storage + event source for ingestion
- **EventBridge rule** — triggers ingestion task on new S3 uploads
- **ALB** — routes traffic to the API service

---

## Skills You'll Practice

| Skill | What you'll do |
|---|---|
| pgvector | CREATE EXTENSION, vector columns, `<=>` cosine similarity operator |
| S3 event-driven architecture | S3 notifications → EventBridge → ECS task |
| Multi-service ECS | Two independent services in one cluster |
| Embedding models | sentence-transformers running in container |
| SSM Parameter Store | Config values (model name, chunk size) vs secrets (passwords) |
| IAM for ECS | Least-privilege task roles for S3, RDS, SSM |

---

## Prerequisites

- Completed Project 03 (ECS Fargate fundamentals)
- Basic understanding of RAG: chunk → embed → store → query
- Familiarity with psycopg2 or SQLAlchemy

---

## Project Metadata

| Field | Value |
|---|---|
| Difficulty | 🟠 Minimal Hints |
| Estimated time | 7 hours |
| AWS cost | ~$5-10/day (RDS + Fargate + NAT) |
| Stack | Terraform, ECS Fargate, RDS Postgres + pgvector, S3, ECR, ALB, EventBridge |

---

## Acceptance Criteria

You've succeeded when:

1. `psql -h <rds-endpoint>` from an EC2 bastion shows `SELECT * FROM pg_extension WHERE extname='vector'` returns a row
2. Uploading a PDF to S3 triggers the ingestion task (visible in ECS console within 60s)
3. After ingestion, `SELECT COUNT(*) FROM embeddings` shows rows in the DB
4. `curl -X POST http://<alb>/query -d '{"question": "what is the main topic?"}'` returns a coherent answer
5. `terraform destroy` cleans everything up

---

## 📂 Navigation

**Prev:** [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md) &nbsp;&nbsp; **Next:** [05 — Serverless AI Agent](../05_Serverless_AI_Agent/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
