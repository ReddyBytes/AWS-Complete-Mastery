# 01 — Mission: Serverless AI Agent on AWS Lambda + API Gateway

## The Scenario

You've deployed APIs to EC2, containers to ECS, and RAG systems to Fargate. All of those involve persistent infrastructure — instances or services that run 24/7 and accrue hourly charges whether or not anyone is using them.

**Lambda** flips the model. You upload code; AWS runs it only when a request arrives. Idle periods cost $0. You're billed for execution time in 100ms increments. For an AI agent that might get 100 requests per day, Lambda can cost pennies per month instead of $50-100 for always-on Fargate.

The catch: Lambda has constraints — 15-minute max execution time, no persistent filesystem, cold starts on the first request. This project teaches you to design around those constraints.

Your mission: deploy a multi-tool AI agent as a Lambda function. HTTP requests arrive via API Gateway, Lambda invokes Claude with tools (calculator, weather, current time), and conversation memory lives in DynamoDB so users can have multi-turn conversations across separate HTTP requests.

---

## What You'll Build

- **Lambda function** — Python handler that runs the Claude agent
- **API Gateway** — HTTP API endpoint that triggers Lambda on POST requests
- **DynamoDB** — conversation memory table with TTL (sessions expire after 24h)
- **SSM Parameter Store** — stores the Anthropic API key (not Secrets Manager — cheaper for simple strings)
- **Lambda Layer** — packages the `anthropic` SDK separately from the function code
- **CloudWatch** — Lambda execution logs + duration metrics

---

## Skills You'll Practice

| Skill | What you'll do |
|---|---|
| Lambda + API Gateway | HTTP API trigger, event parsing, response format |
| DynamoDB session storage | PutItem, GetItem, TTL attribute |
| Lambda Layers | Package heavy dependencies separately for faster deploys |
| SSM Parameter Store | SecureString for API key, cached in Lambda memory |
| Cold start optimization | Load SDK + API key at module level, not inside handler |
| IAM for Lambda | Execution role with least-privilege DynamoDB and SSM access |
| Terraform for Lambda | `aws_lambda_function`, archive_file, Lambda URLs |

---

## Prerequisites

- Understand Lambda basics: handler, event, context, execution role
- Completed at least Project 02 (Terraform) and Project 03 (ECS IAM patterns)
- Familiarity with the Anthropic Python SDK and tool use

---

## Project Metadata

| Field | Value |
|---|---|
| Difficulty | 🔴 Build Yourself |
| Estimated time | 8 hours |
| AWS cost | ~$0-2/month at low traffic (Lambda free tier: 1M requests/month) |
| Stack | Lambda (Python 3.12), API Gateway HTTP API, DynamoDB, SSM, CloudWatch, Terraform |

---

## Acceptance Criteria

All five must pass before you consider this complete.

**1. Single-turn response**
```bash
curl -X POST https://<api_gw_url>/chat \
  -H "Content-Type: application/json" \
  -d '{"session_id": "test-001", "message": "What is 42 * 137?"}'
# Expected: response containing "5754"
```

**2. Tool use (calculator)**
```bash
curl -X POST https://<api_gw_url>/chat \
  -d '{"session_id": "test-002", "message": "What time is it in UTC right now?"}'
# Expected: correct UTC time (uses the time tool, not hallucinated)
```

**3. Multi-turn memory**
```bash
# Turn 1
curl -X POST https://<api_gw_url>/chat \
  -d '{"session_id": "test-003", "message": "My name is Alice."}'
# Turn 2 (same session_id)
curl -X POST https://<api_gw_url>/chat \
  -d '{"session_id": "test-003", "message": "What is my name?"}'
# Expected: "Alice" — Lambda retrieved previous turn from DynamoDB
```

**4. Session isolation**
```bash
curl -X POST https://<api_gw_url>/chat \
  -d '{"session_id": "test-004", "message": "What is my name?"}'
# Expected: agent says it doesn't know (different session_id from test-003)
```

**5. Session expiry**
In DynamoDB console, find the session item and verify it has a `ttl` attribute set to approximately `now + 86400` (24 hours from creation).

---

## Architectural Hints (3 key decisions)

**1. Cold starts: load expensive resources at module level**

Lambda reuses execution environments between invocations ("warm starts"). Variables set at module level persist across warm invocations. Use this:

```python
# Module level — runs once per cold start
import anthropic
import boto3

ssm = boto3.client("ssm")
_api_key = None

def get_api_key() -> str:
    global _api_key
    if _api_key is None:
        # On cold start: fetch from SSM. On warm start: use cached value.
        _api_key = ssm.get_parameter(Name="/myapp/anthropic-key", WithDecryption=True)["Parameter"]["Value"]
    return _api_key

# Handler — runs on every invocation
def handler(event, context):
    client = anthropic.Anthropic(api_key=get_api_key())
    # ...
```

**2. DynamoDB for conversation history**

Lambda has no persistent state between invocations. DynamoDB provides fast key-value access. The conversation table has:
- Partition key: `session_id` (string)
- Attributes: `messages` (JSON list), `ttl` (number — Unix timestamp)
- TTL configured on the `ttl` attribute

On each request: read existing messages → append new user message → run agent → append assistant response → write back.

**3. API Gateway response format**

Lambda must return a specific JSON structure for API Gateway to pass it through correctly:

```python
return {
    "statusCode": 200,
    "headers": {"Content-Type": "application/json"},
    "body": json.dumps({"response": "...", "session_id": "..."})
}
```

Returning anything else results in a 502 from API Gateway.

---

## Full Reference Solution

See `src/solution.py` for the complete implementation.

---

## 📂 Navigation

**Prev:** [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md) &nbsp;&nbsp; This is the final project.

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
