# 03 — Guide: Serverless AI Agent

This is a 🔴 Build Yourself project. No step-by-step instructions — just the acceptance criteria, architectural hints, and a reference solution.

---

## Your Spec

Build a serverless multi-turn AI agent with the following behavior:

### API Contract

**Endpoint:** `POST /chat`

**Request body:**
```json
{
  "session_id": "string (required) — UUID or any unique string",
  "message": "string (required) — the user's message"
}
```

**Response body:**
```json
{
  "response": "string — Claude's reply",
  "session_id": "string — echo the session_id back",
  "message_count": 4
}
```

**Error responses:**
- `400` — missing `session_id` or `message`
- `500` — internal error (Claude API failure, DynamoDB failure)

---

## Acceptance Criteria

Run all five tests before marking this project complete.

**Test 1: Single-turn response**
```bash
curl -X POST https://<api_gw_url>/chat \
  -H "Content-Type: application/json" \
  -d '{"session_id": "test-001", "message": "What is 42 * 137?"}'
```
Expected: response contains "5754"

**Test 2: Tool use (time tool)**
```bash
curl -X POST https://<api_gw_url>/chat \
  -H "Content-Type: application/json" \
  -d '{"session_id": "test-002", "message": "What is the current UTC time?"}'
```
Expected: a real timestamp, not a hallucinated one. Verify it matches your watch.

**Test 3: Multi-turn memory**
```bash
# Turn 1
curl -X POST https://<api_gw_url>/chat \
  -d '{"session_id": "test-003", "message": "My name is Alice."}'

# Turn 2 (same session_id — must recall previous turn)
curl -X POST https://<api_gw_url>/chat \
  -d '{"session_id": "test-003", "message": "What is my name?"}'
```
Expected: turn 2 response mentions "Alice"

**Test 4: Session isolation**
```bash
curl -X POST https://<api_gw_url>/chat \
  -d '{"session_id": "test-004", "message": "What is my name?"}'
```
Expected: agent says it doesn't know — different session from test-003

**Test 5: TTL set correctly**
```bash
aws dynamodb get-item \
  --table-name chat-sessions \
  --key '{"session_id": {"S": "test-001"}}' \
  --query 'Item.ttl'
```
Expected: a number approximately equal to `$(date +%s) + 86400` (24 hours from now)

---

## Architectural Decision Hints

**Hint 1: How to handle Lambda cold starts**

The `anthropic` client initialization and SSM parameter fetch are expensive operations (200-500ms combined). They should happen at module level, not inside the handler. Module-level code runs once per execution environment (cold start) and is reused on warm invocations.

Structure your Lambda like this:
```
module level:
  - import all libraries
  - initialize boto3 clients (free — no network calls)
  - define _api_key = None (will be populated on first call)
  - define get_api_key() function with global cache

handler():
  - call get_api_key() (returns cached value on warm start)
  - create anthropic.Anthropic(api_key=...) (fast once key is cached)
  - proceed with logic
```

**Hint 2: How to store API key in SSM**

Create the parameter before deploying:
```bash
aws ssm put-parameter \
  --name "/myapp/anthropic-key" \
  --value "sk-ant-api03-..." \
  --type "SecureString" \
  --overwrite
```

Retrieve it in Lambda:
```python
ssm.get_parameter(Name="/myapp/anthropic-key", WithDecryption=True)["Parameter"]["Value"]
```

The Lambda execution role needs: `ssm:GetParameter` on that specific ARN.

**Hint 3: How to manage conversation history in DynamoDB**

DynamoDB stores the entire `messages` list as a single JSON attribute. The agentic loop may expand the messages list (tool use adds intermediate messages). Store the final list after the agent finishes.

DynamoDB `messages` attribute type: `S` (String containing JSON), not `L` (List) — it's easier to serialize/deserialize a Python list with `json.dumps`/`json.loads`.

TTL: `int(time.time()) + 86400` — set on every write to "roll forward" the expiry.

---

## Tools to Implement

Your agent must have at least these three tools:

**calculator** — evaluates a math expression
```python
{
  "name": "calculator",
  "description": "Evaluate a mathematical expression. Input: a string like '42 * 137'.",
  "input_schema": {
    "type": "object",
    "properties": {
      "expression": {"type": "string", "description": "Math expression to evaluate"}
    },
    "required": ["expression"]
  }
}
```

**get_current_time** — returns current UTC time (no inputs needed)

**get_weather** — stub that returns fake weather data (no real API needed, just returns `{"city": city, "temp_c": 20, "condition": "sunny"}`)

---

## Full Reference Solution

<details>
<summary>✅ Full Solution (expand only after attempting)</summary>

See `src/solution.py` for the complete implementation including:
- Lambda handler with correct API Gateway response format
- DynamoDB read/write with TTL
- SSM API key caching
- Multi-tool Claude agent loop
- Complete Terraform at the bottom of the file
</details>

---

## 📂 Navigation

**Prev:** [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md) &nbsp;&nbsp; This is the final project.

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
