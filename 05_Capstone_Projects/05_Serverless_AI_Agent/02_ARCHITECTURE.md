# 02 — Architecture: Serverless AI Agent

## The Big Picture

Think of Lambda like a vending machine: it does nothing while idle, springs to life the moment someone drops a coin (HTTP request), dispenses the result, and goes quiet again. You pay per dispense, not per hour of standing there.

```
Browser / curl
    |
    | POST /chat  {"session_id": "abc", "message": "hi"}
    v
+------------------------------+
|  API Gateway (HTTP API)      |
|  - validates request format  |
|  - throttles (1000 rps max)  |
+------------------------------+
    |
    | invoke Lambda (synchronous)
    v
+------------------------------+     +--------------------------+
|  Lambda Function             |     |  DynamoDB                |
|  (Python 3.12)               |     |  Table: chat_sessions    |
|                              |---->|  PK: session_id          |
|  1. Parse event              |     |  Attr: messages (JSON)   |
|  2. Get API key (SSM cache)  |<----|  Attr: ttl (Unix epoch)  |
|  3. Load session from DDB    |     +--------------------------+
|  4. Run Claude agent loop    |
|  5. Execute tools if needed  |     +--------------------------+
|  6. Save session to DDB      |     |  SSM Parameter Store     |
|  7. Return response          |---->|  /myapp/anthropic-key    |
+------------------------------+     |  (SecureString, cached)  |
    |                                +--------------------------+
    | JSON response
    v
API Gateway formats HTTP response
    |
    v
Browser / curl receives answer
```

---

## Lambda Execution Model: Cold vs Warm Start

```
COLD START (first request after deploy or scale-out):
─────────────────────────────────────────────────────
Lambda downloads your code + layer (from S3 internally)
    ↓
Python interpreter starts
    ↓
Module-level code runs:
  - import anthropic, boto3  (~200ms)
  - ssm.get_parameter(...)   (~50ms) ← network call
  - _api_key cached in memory
    ↓
handler() called              (~500ms for first Claude call)
    ↓
Total: ~750ms-2s (perceived latency spike on first request)

WARM START (subsequent requests within ~15 minutes):
─────────────────────────────────────────────────────
Lambda reuses the same execution environment
    ↓
Module-level code is ALREADY loaded (cached)
    ↓
handler() called directly      (~200-500ms for Claude call)
    ↓
Total: ~200-600ms (normal latency)
```

The warm/cold distinction is why you load the API key and clients at module level — they persist across warm invocations for free.

---

## DynamoDB Session Table Schema

DynamoDB is a key-value and document store. For conversation memory, each row is one session. The `messages` attribute holds the full conversation history as a JSON list (Claude's message format).

```
Table: chat_sessions
    Billing:   PAY_PER_REQUEST (no provisioning needed at low scale)
    TTL attr:  ttl (DynamoDB auto-deletes items when ttl < now)

Item structure:
    {
        "session_id": "abc-123",            ← partition key (string)
        "messages": [                        ← full conversation history
            {"role": "user",      "content": "My name is Alice."},
            {"role": "assistant", "content": "Nice to meet you, Alice!"},
            {"role": "user",      "content": "What is my name?"},
            {"role": "assistant", "content": "Your name is Alice."}
        ],
        "ttl": 1714000000,                  ← Unix timestamp 24h from last update
        "created_at": "2025-04-24T12:00:00Z",
        "message_count": 4
    }

Max item size: 400 KB.
A conversation of 100 turns at ~200 chars/turn is ~20 KB — well within limits.
Prune old messages if sessions get very long.
```

---

## Lambda Layer: Dependency Packaging

Lambda has a 50MB compressed code size limit. The `anthropic` SDK + dependencies is ~15MB. Packaging them in a separate Layer means:

- The layer is uploaded once and shared across function versions
- Code-only updates are faster (deploy a 20KB zip, not a 15MB one)
- Multiple functions can share the same layer

```
Lambda deployment structure:

function.zip (small — just your code)
    └── lambda_function.py   (~5 KB)

layer.zip (large — third-party deps)
    └── python/
        └── lib/
            └── python3.12/
                └── site-packages/
                    ├── anthropic/      (~12 MB)
                    ├── boto3/          (already in Lambda runtime — don't include)
                    └── ...
```

Build the layer:
```bash
mkdir -p python/lib/python3.12/site-packages
pip install anthropic -t python/lib/python3.12/site-packages --platform manylinux2014_x86_64 --only-binary=:all:
zip -r layer.zip python/
```

---

## Cost Comparison: Lambda vs Fargate for Low-Traffic AI Agent

| Metric | Lambda | ECS Fargate (always on) |
|---|---|---|
| 100 req/day, 2s avg duration | ~$0.003/month | ~$1.50/month |
| 10,000 req/day, 2s avg | ~$0.30/month | ~$1.50/month |
| 100,000 req/day, 2s avg | ~$3/month | ~$1.50/month |
| Break-even | ~80,000 req/day | — |
| Idle cost | $0 | $1.50/month |
| Cold start latency | +0.5-2s | None |
| Max execution time | 15 min | Unlimited |

Lambda wins for bursty/low-traffic workloads. Fargate wins when you have consistent high traffic or long-running tasks.

---

## 📂 Navigation

**Prev:** [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md) &nbsp;&nbsp; This is the final project.

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
