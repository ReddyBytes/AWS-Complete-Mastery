# 04 — Recap: RAG System on AWS

## What You Built

A production RAG pipeline where documents are ingested asynchronously via S3 events and served via a stateless query API. The vector store is PostgreSQL — which means your embeddings are backed up, queryable with SQL, and shareable across any number of containers.

---

## 3 Key Concepts

### 1. pgvector vs ChromaDB: the Operational Tradeoff

ChromaDB is a purpose-built vector database optimized for embedding workloads. pgvector is an extension that adds vector operations to Postgres. The performance gap is small at moderate scale — both can serve thousands of queries per second with proper indexing. The operational gap is large:

ChromaDB is a process-scoped store. Multiple containers can't share one ChromaDB instance without a network server setup. pgvector is just a Postgres table — any process with DB credentials can read from it. When you already run RDS for your application data, adding a `VECTOR` column to an embeddings table costs $0 in infrastructure.

The IVFFlat index (`ivfflat`) is an approximate nearest-neighbor index. It trades a small amount of recall (it might miss 1-5% of truly relevant results) for dramatically faster queries. For typical RAG applications where you're retrieving 5-20 chunks, this tradeoff is almost always acceptable.

### 2. S3 Event-Driven Ingestion

The pattern of S3 ObjectCreated → EventBridge → ECS task run is a foundational AWS serverless pattern. It decouples the write path (someone uploading a document) from the processing path (chunking and embedding). The uploader gets a fast response (`200 OK` from S3), and the ingestion happens asynchronously without blocking anything.

Key detail: EventBridge's `input_transformer` is what injects the S3 bucket and key into the ECS task's environment variables. Without it, the task would start but not know which file to process.

### 3. Two IAM Roles, Two ECS Services

The API and the ingestion worker have different permission requirements:
- API service task role: `secretsmanager:GetSecretValue` (DB password), nothing else
- Ingestion worker task role: `s3:GetObject` on the documents bucket, `secretsmanager:GetSecretValue`

Giving the API service `s3:GetObject` would violate least privilege. If the API container is compromised, the attacker should not be able to read arbitrary documents from S3. Keep roles minimal and purpose-specific.

---

## Extend It

**Add Redis caching for embeddings**
Embedding a question takes ~50ms with sentence-transformers. Cache `hash(question) → embedding` in ElastiCache Redis with a 1-hour TTL. For repeated questions (common in production), query time drops from 100ms to 10ms.

**Switch to Bedrock embeddings**
Replace `sentence-transformers` (which runs in-container, consuming Fargate CPU/memory) with `amazon.titan-embed-text-v1` via the Bedrock API. This eliminates the embedding model from the container entirely — smaller image, faster cold start, no GPU needed. Add `bedrock:InvokeModel` to the task role.

**Add OpenSearch for hybrid search**
pgvector does pure vector search. OpenSearch supports **hybrid search**: combine vector similarity with BM25 keyword scoring. Hybrid search outperforms pure vector search on factual Q&A tasks. The trade-off is cost — OpenSearch clusters start at ~$50/month.

**Add a re-ranker**
After pgvector retrieves top-20 chunks, use a cross-encoder model (e.g., `cross-encoder/ms-marco-MiniLM-L-6-v2`) to re-rank them and keep the top 5. Cross-encoders look at query+chunk together and are much more accurate than bi-encoders for relevance scoring. Run it as a CPU-bound Lambda or Fargate sidecar.

---

## ✅ What you mastered
- pgvector: setup, indexing, cosine similarity queries via SQL
- S3-triggered ECS task runs via EventBridge
- Multi-service ECS architecture with purpose-specific IAM roles

## 🔨 What to build next
- Add a re-ranking step: retrieve top-20 from pgvector, re-rank with cross-encoder, keep top 5

## ➡️ Next project
No EC2, no containers — deploy an AI agent as a single Lambda function: [05 — Serverless AI Agent](../05_Serverless_AI_Agent/01_MISSION.md)

---

## 📂 Navigation

**Prev:** [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md) &nbsp;&nbsp; **Next:** [05 — Serverless AI Agent](../05_Serverless_AI_Agent/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
