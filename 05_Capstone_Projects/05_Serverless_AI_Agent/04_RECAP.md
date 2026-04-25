# 04 — Recap: Serverless AI Agent on Lambda

## What You Built

A fully serverless AI agent where the infrastructure cost is directly proportional to usage. No idle charges, no servers to patch, no containers to orchestrate. HTTP arrives, Lambda wakes, Claude thinks, DynamoDB stores, Lambda sleeps.

---

## 3 Key Concepts

### 1. Serverless Tradeoffs

Lambda is not always the right choice. The tradeoffs:

**Lambda wins when:**
- Traffic is bursty or unpredictable (dev tools, internal dashboards, low-traffic APIs)
- Individual request processing time is under 5 minutes
- You want to pay $0 during idle periods (nights, weekends)
- Operational simplicity matters more than fine-grained control

**Lambda loses when:**
- You need persistent connections (WebSockets, database connection pools)
- Cold start latency is unacceptable (real-time gaming, trading systems)
- You need long-running jobs (ML training, video transcoding — use ECS or Batch)
- You're at scale where always-on Fargate is cheaper

The break-even for this agent (2s per invocation) is approximately 80,000 requests per day. Below that, Lambda is cheaper. Above that, Fargate is.

### 2. Lambda Cold Starts and the Module-Level Cache Pattern

Lambda's execution model creates a two-tier cache:
- **Module-level** (`_api_key`, boto3 clients): initialized on cold start, persists across all warm invocations of that execution environment
- **Handler-level** (local variables): re-initialized on every invocation

The `get_api_key()` function exploits this. The first call in a cold start hits SSM (50ms network call). Every subsequent warm invocation returns the cached value instantly. Over the lifetime of an execution environment (typically 5-60 minutes), hundreds of requests share one SSM call.

This pattern applies to: database connections (use a connection pool stored at module level), ML models (load once at cold start), configuration (read from SSM/environment once).

### 3. DynamoDB TTL for Session Management

DynamoDB TTL is a background deletion process. When you set `ttl = int(time.time()) + 86400` on an item, DynamoDB will delete it sometime after that Unix timestamp expires. "Sometime" means within 48 hours of expiry — TTL is not instant and is not a hard guarantee.

For conversation memory, this is fine. Expired sessions are cleaned up automatically without you running any maintenance jobs or paying for a cleanup Lambda.

The rolling TTL pattern (update `ttl` on every write) means active sessions never expire — only abandoned ones do. A user who sends one message every 23 hours would keep the session alive indefinitely.

---

## Lambda Debugging Reference

| Problem | How to diagnose |
|---|---|
| 502 from API Gateway | Lambda returned non-standard response format — check `statusCode`, `headers`, `body` |
| "Task timed out" in logs | Claude + tool loop exceeded `timeout` setting — increase to 60-120s |
| `AccessDeniedException` on SSM | Lambda execution role missing `ssm:GetParameter` on the parameter ARN |
| `ResourceNotFoundException` on DynamoDB | Table name mismatch between `DYNAMODB_TABLE` env var and actual table name |
| Cold start > 5s | `anthropic` SDK imported inside handler — move to module level |
| Tool loop not stopping | Claude confused about tool results — add explicit `max_iterations` guard |

---

## Extend It

**Add Lambda@Edge for lower latency**
Lambda@Edge runs your function at CloudFront edge locations worldwide. For a read-heavy endpoint (e.g., returning cached responses), this reduces latency from 100ms to <10ms for geographically distributed users.

**Add SQS for async long-running agents**
For agents that take 30+ seconds (complex reasoning, many tool calls), switch to async: API Gateway → Lambda writes to SQS → second Lambda processes → writes result to DynamoDB → client polls `/result/{job_id}`. Removes the 29-second API Gateway timeout limit.

**Switch to Bedrock**
Replace `anthropic.Anthropic(api_key=...)` with `boto3.client("bedrock-runtime")` and call `invoke_model`. Removes the SSM API key entirely (Bedrock uses IAM authentication). Add `bedrock:InvokeModel` to the Lambda execution role. Lower latency since Bedrock traffic stays within AWS.

**Add Lambda Powertools**
The `aws-lambda-powertools` library adds structured logging, distributed tracing (X-Ray), and metrics with minimal boilerplate. Replace `logger.info(...)` with Powertools Logger for automatic request ID injection and JSON-structured logs.

---

## ✅ What you mastered
- Lambda execution model: cold/warm starts, module-level caching
- API Gateway HTTP API event format and response contract
- DynamoDB TTL for serverless session management

## 🔨 What to build next
- Add a `/history` endpoint that returns the full conversation history for a session
- Add request rate limiting per `session_id` to prevent abuse

## This is the final capstone project.

---

## 📂 Navigation

⬅️ **Prev:** [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md) &nbsp;&nbsp; ➡️ **This is the final project**

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
