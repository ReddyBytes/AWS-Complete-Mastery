"""
Project 05: Serverless AI Agent — COMPLETE SOLUTION
=====================================================
Full Lambda function + Terraform for a multi-tool AI agent
with DynamoDB session memory and SSM API key management.

File structure:
  lambda_function.py    ← this file (Lambda handler + agent logic)
  main.tf               ← Terraform at bottom of this file as a string

Deploy steps:
  1. Store API key: aws ssm put-parameter --name /myapp/anthropic-key --value sk-... --type SecureString
  2. Build layer: pip install anthropic -t layer/python/lib/python3.12/site-packages && cd layer && zip -r ../layer.zip .
  3. terraform apply
  4. Test with curl commands from the MISSION.md acceptance criteria
"""

import json
import math
import time
import logging
import os
from datetime import datetime, timezone
from typing import Any

import boto3
import anthropic

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# ── Module-level init (cold start cost: ~200ms, amortized across warm invocations) ──

dynamodb = boto3.resource("dynamodb")                # ← no network call — just client setup
ssm      = boto3.client("ssm")                       # ← same

TABLE_NAME   = os.environ.get("DYNAMODB_TABLE", "chat-sessions")
SSM_KEY_PATH = os.environ.get("SSM_KEY_PATH", "/myapp/anthropic-key")
MODEL        = os.environ.get("ANTHROPIC_MODEL", "claude-3-haiku-20240307")
TTL_SECONDS  = int(os.environ.get("SESSION_TTL_SECONDS", "86400"))  # 24 hours

# API key cached at module level — fetched once per cold start, reused on warm invocations
_api_key: str | None = None

def get_api_key() -> str:
    """Fetch Anthropic API key from SSM Parameter Store. Cached after first call."""
    global _api_key
    if _api_key is None:
        logger.info("Fetching API key from SSM (cold start)")
        response = ssm.get_parameter(Name=SSM_KEY_PATH, WithDecryption=True)
        _api_key = response["Parameter"]["Value"]
    return _api_key

# ── DynamoDB helpers ──────────────────────────────────────────────────────────

def load_session(session_id: str) -> list[dict]:
    """Load message history for a session. Returns [] if session doesn't exist."""
    table = dynamodb.Table(TABLE_NAME)
    try:
        response = table.get_item(Key={"session_id": session_id})
        item = response.get("Item")
        if not item:
            return []
        # messages stored as JSON string (easier than DynamoDB List type)
        return json.loads(item.get("messages", "[]"))
    except Exception as e:
        logger.warning("Failed to load session %s: %s", session_id, e)
        return []

def save_session(session_id: str, messages: list[dict]) -> None:
    """Write session back to DynamoDB with a rolling TTL."""
    table = dynamodb.Table(TABLE_NAME)
    ttl   = int(time.time()) + TTL_SECONDS  # ← roll forward TTL on every update

    table.put_item(Item={
        "session_id":    session_id,
        "messages":      json.dumps(messages),      # ← serialize to JSON string
        "ttl":           ttl,                       # ← DynamoDB TTL attribute
        "message_count": len(messages),
        "updated_at":    datetime.now(timezone.utc).isoformat(),
    })

# ── Tool definitions ──────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "calculator",
        "description": (
            "Evaluate a mathematical expression. Use this for any arithmetic. "
            "Input must be a safe Python math expression using +, -, *, /, **, //, %, "
            "and math module functions like sqrt, log, sin, cos."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "expression": {
                    "type": "string",
                    "description": "Math expression to evaluate, e.g. '42 * 137' or 'math.sqrt(144)'"
                }
            },
            "required": ["expression"]
        }
    },
    {
        "name": "get_current_time",
        "description": "Get the current UTC date and time. No inputs required.",
        "input_schema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "get_weather",
        "description": "Get current weather conditions for a city. Returns temperature and conditions.",
        "input_schema": {
            "type": "object",
            "properties": {
                "city": {
                    "type": "string",
                    "description": "City name, e.g. 'London' or 'New York'"
                }
            },
            "required": ["city"]
        }
    }
]

# ── Tool execution ────────────────────────────────────────────────────────────

def execute_tool(name: str, inputs: dict) -> str:
    """Execute a named tool and return its result as a string."""
    logger.info("Executing tool: %s with inputs: %s", name, inputs)

    if name == "calculator":
        expr = inputs.get("expression", "")
        try:
            # Safe eval: only allow math operations, no builtins, no imports
            result = eval(
                expr,
                {"__builtins__": {}, "math": math},  # ← restrict namespace
                {}
            )
            return str(result)
        except Exception as e:
            return f"Error evaluating '{expr}': {e}"

    elif name == "get_current_time":
        now = datetime.now(timezone.utc)
        return json.dumps({
            "utc_time":  now.isoformat(),
            "unix_epoch": int(now.timestamp()),
            "formatted":  now.strftime("%Y-%m-%d %H:%M:%S UTC")
        })

    elif name == "get_weather":
        city = inputs.get("city", "Unknown")
        # Stub: real implementation would call a weather API
        return json.dumps({
            "city":       city,
            "temp_c":     22,
            "temp_f":     72,
            "condition":  "partly cloudy",
            "humidity":   "65%",
            "note":       "stub data — connect a real weather API for production"
        })

    else:
        return f"Unknown tool: {name}. Available tools: {[t['name'] for t in TOOLS]}"

# ── Agent loop ────────────────────────────────────────────────────────────────

def run_agent(messages: list[dict]) -> tuple[str, list[dict]]:
    """
    Run the Claude agentic loop.

    The loop continues until Claude returns stop_reason="end_turn".
    On stop_reason="tool_use", executes the requested tools and feeds results back.

    Returns:
        (final_text_response, updated_messages_including_all_turns)
    """
    client = anthropic.Anthropic(api_key=get_api_key())

    # Safety: prevent runaway loops (Claude calling tools indefinitely)
    max_iterations = 10

    for iteration in range(max_iterations):
        logger.info("Agent iteration %d, messages: %d", iteration + 1, len(messages))

        response = client.messages.create(
            model=MODEL,
            max_tokens=1024,
            tools=TOOLS,
            messages=messages,
            system=(
                "You are a helpful assistant with access to tools. "
                "Use the calculator tool for math. "
                "Use get_current_time when asked about the time — never guess. "
                "Be concise and accurate."
            )
        )

        if response.stop_reason == "end_turn":
            # Extract the text response from the content blocks
            text = ""
            for block in response.content:
                if hasattr(block, "text"):
                    text += block.text

            # Append the final assistant message to history
            messages.append({"role": "assistant", "content": response.content})
            return text, messages

        elif response.stop_reason == "tool_use":
            # Append the assistant's tool_use message (including all content blocks)
            messages.append({"role": "assistant", "content": response.content})

            # Execute all tool calls and build the tool_result message
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    result = execute_tool(block.name, block.input)
                    logger.info("Tool %s returned: %s", block.name, result[:200])
                    tool_results.append({
                        "type":        "tool_result",
                        "tool_use_id": block.id,
                        "content":     result
                    })

            # Append all tool results in a single user message
            messages.append({"role": "user", "content": tool_results})
            # Loop again — Claude will now process the tool results

        else:
            # Unexpected stop reason
            logger.warning("Unexpected stop_reason: %s", response.stop_reason)
            return f"Unexpected stop reason: {response.stop_reason}", messages

    return "Max tool iterations reached. Please rephrase your question.", messages

# ── Lambda Handler ────────────────────────────────────────────────────────────

def handler(event: dict, context: Any) -> dict:
    """
    API Gateway HTTP API event handler.

    API Gateway passes the HTTP request body as event["body"] (a string).
    Must return a dict with statusCode, headers, and body (a string).
    """
    logger.info("Event: %s", json.dumps({k: v for k, v in event.items() if k != "body"}))

    # 1. Parse request body
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _error(400, "Request body must be valid JSON")

    session_id = body.get("session_id", "").strip()
    message    = body.get("message", "").strip()

    if not session_id:
        return _error(400, "Missing required field: session_id")
    if not message:
        return _error(400, "Missing required field: message")

    # 2. Load existing conversation history from DynamoDB
    messages = load_session(session_id)
    logger.info("Loaded %d messages for session %s", len(messages), session_id)

    # 3. Append the new user message
    messages.append({"role": "user", "content": message})

    # 4. Run the agent loop
    try:
        response_text, updated_messages = run_agent(messages)
    except Exception as e:
        logger.exception("Agent error")
        return _error(500, f"Agent error: {str(e)}")

    # 5. Save updated history back to DynamoDB
    try:
        save_session(session_id, updated_messages)
    except Exception as e:
        logger.warning("Failed to save session (continuing): %s", e)

    # 6. Return the response
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type":                "application/json",
            "Access-Control-Allow-Origin": "*",  # ← enable CORS for browser clients
        },
        "body": json.dumps({
            "response":      response_text,
            "session_id":    session_id,
            "message_count": len(updated_messages),
        })
    }

def _error(status_code: int, message: str) -> dict:
    """Build an error response in API Gateway format."""
    return {
        "statusCode": status_code,
        "headers":    {"Content-Type": "application/json"},
        "body":       json.dumps({"error": message})
    }


# ==============================================================================
# TERRAFORM CONFIGURATION (save as main.tf)
# ==============================================================================

TERRAFORM = '''
# =============================================================================
# Terraform for Lambda + API Gateway + DynamoDB + SSM + IAM
# =============================================================================

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region"    { default = "us-east-1" }
variable "project_name"  { default = "myapp-agent" }

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── DynamoDB Table ────────────────────────────────────────────────────────────

resource "aws_dynamodb_table" "sessions" {
  name         = "${var.project_name}-sessions"
  billing_mode = "PAY_PER_REQUEST"  # ← no capacity planning; scale-to-zero

  hash_key = "session_id"  # ← partition key

  attribute {
    name = "session_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"     # ← DynamoDB auto-deletes items past this Unix timestamp
    enabled        = true
  }

  tags = { Name = "${var.project_name}-sessions" }
}

# ── IAM Role for Lambda ───────────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  # ← grants: CloudWatch Logs write (CreateLogGroup, CreateLogStream, PutLogEvents)
}

resource "aws_iam_role_policy" "lambda_app" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
        Resource = [aws_dynamodb_table.sessions.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/myapp/anthropic-key"]
      }
    ]
  })
}

# ── Lambda Function ───────────────────────────────────────────────────────────

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "agent" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.project_name}-agent"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  timeout          = 60      # ← Claude tool loops can take 5-20s; 60s is safe
  memory_size      = 256     # ← more memory = more vCPU allocation = faster execution

  source_code_hash = data.archive_file.lambda.output_base64sha256  # ← triggers redeploy on change

  layers = [aws_lambda_layer_version.anthropic.arn]  # ← separate layer for dependencies

  environment {
    variables = {
      DYNAMODB_TABLE  = aws_dynamodb_table.sessions.name
      SSM_KEY_PATH    = "/myapp/anthropic-key"
      ANTHROPIC_MODEL = "claude-3-haiku-20240307"
    }
  }

  tags = { Name = "${var.project_name}-agent" }
}

# ── Lambda Layer (anthropic SDK) ──────────────────────────────────────────────

# Build before terraform apply:
#   pip install anthropic -t layer/python/lib/python3.12/site-packages \
#       --platform manylinux2014_x86_64 --only-binary=:all:
#   cd layer && zip -r ../anthropic-layer.zip .

resource "aws_lambda_layer_version" "anthropic" {
  filename            = "${path.module}/anthropic-layer.zip"  # ← build this before applying
  layer_name          = "${var.project_name}-anthropic"
  compatible_runtimes = ["python3.12"]

  lifecycle {
    create_before_destroy = true
  }
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.agent.function_name}"
  retention_in_days = 14
}

# ── API Gateway (HTTP API — simpler and cheaper than REST API) ────────────────

resource "aws_apigatewayv2_api" "agent" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]  # ← tighten in production
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.agent.id
  integration_type       = "AWS_PROXY"  # ← API GW passes full event to Lambda
  integration_uri        = aws_lambda_function.agent.invoke_arn
  payload_format_version = "2.0"  # ← HTTP API v2 format (simpler than v1)
}

resource "aws_apigatewayv2_route" "chat" {
  api_id    = aws_apigatewayv2_api.agent.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.agent.id
  name        = "$default"  # ← $default = no stage prefix in URL
  auto_deploy = true        # ← redeploy automatically on route changes
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agent.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.agent.execution_arn}/*/*"
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "api_endpoint" {
  description = "Base URL for the agent API"
  value       = aws_apigatewayv2_api.agent.api_endpoint
}

output "test_command" {
  description = "Quick test"
  value       = "curl -X POST ${aws_apigatewayv2_api.agent.api_endpoint}/chat -H \\"Content-Type: application/json\\" -d \'{\\"session_id\\": \\"test-001\\", \\"message\\": \\"What is 6 * 7?\\"}\'"
}
'''
