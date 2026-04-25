"""
Project 05: Serverless AI Agent — STARTER
==========================================
Fill in all TODO sections to build the Lambda-based AI agent.

Save as: lambda_function.py
Deploy: zip lambda_function.py && aws lambda update-function-code ...

Environment variables (set in Lambda config or Terraform):
  DYNAMODB_TABLE  — name of the DynamoDB sessions table
  SSM_KEY_PATH    — path of the SSM parameter holding the Anthropic API key
  ANTHROPIC_MODEL — model ID (default: claude-3-haiku-20240307)
"""

import json
import time
import logging
import os
from typing import Any

import boto3

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# ── Module-level init (runs once per cold start, reused on warm starts) ────────

# TODO: Initialize boto3 clients at module level
# - DynamoDB resource (for higher-level Item API)
# - SSM client (for GetParameter)
dynamodb = None  # replace with boto3.resource("dynamodb")
ssm      = None  # replace with boto3.client("ssm")

# TODO: Set up a module-level cache for the API key
_api_key = None

def get_api_key() -> str:
    """Fetch Anthropic API key from SSM, cache it in module memory."""
    global _api_key
    if _api_key is None:
        # TODO: Call ssm.get_parameter with WithDecryption=True
        # Parameter name comes from os.environ["SSM_KEY_PATH"]
        pass
    return _api_key

# ── DynamoDB helpers ──────────────────────────────────────────────────────────

TABLE_NAME = os.environ.get("DYNAMODB_TABLE", "chat-sessions")
TTL_SECONDS = 86400  # 24 hours

def load_session(session_id: str) -> list[dict]:
    """Load conversation history from DynamoDB. Returns empty list if no session exists."""
    # TODO: Get item from DynamoDB table using session_id as partition key
    # If item exists, parse and return the "messages" attribute (JSON string → list)
    # If item doesn't exist (KeyError or empty response), return []
    return []

def save_session(session_id: str, messages: list[dict]) -> None:
    """Write conversation history back to DynamoDB with updated TTL."""
    # TODO: Put item with:
    #   - session_id (PK)
    #   - messages: json.dumps(messages)
    #   - ttl: int(time.time()) + TTL_SECONDS
    #   - message_count: len(messages)
    pass

# ── Tools ─────────────────────────────────────────────────────────────────────

TOOLS = [
    {
        "name": "calculator",
        "description": "Evaluate a safe mathematical expression. Input must be a valid Python math expression.",
        "input_schema": {
            "type": "object",
            "properties": {
                "expression": {
                    "type": "string",
                    "description": "Math expression to evaluate, e.g. '42 * 137' or '(100 / 4) ** 2'"
                }
            },
            "required": ["expression"]
        }
    },
    {
        "name": "get_current_time",
        "description": "Get the current UTC date and time.",
        "input_schema": {
            "type": "object",
            "properties": {}
        }
    },
    {
        "name": "get_weather",
        "description": "Get current weather for a city (stub — returns fake data for demo).",
        "input_schema": {
            "type": "object",
            "properties": {
                "city": {"type": "string", "description": "City name"}
            },
            "required": ["city"]
        }
    }
]

def execute_tool(name: str, inputs: dict) -> str:
    """Execute a tool and return its result as a string."""
    if name == "calculator":
        # TODO: Safely evaluate the math expression
        # Use eval() with a restricted namespace: eval(expr, {"__builtins__": {}}, {})
        # Return the result as a string, or an error message if it fails
        return "TODO"

    elif name == "get_current_time":
        # TODO: Return the current UTC time as an ISO 8601 string
        return "TODO"

    elif name == "get_weather":
        # TODO: Return a fake weather dict as JSON string
        # {"city": inputs["city"], "temp_c": 22, "condition": "partly cloudy"}
        return "TODO"

    else:
        return f"Unknown tool: {name}"

# ── Agent loop ────────────────────────────────────────────────────────────────

def run_agent(messages: list[dict]) -> tuple[str, list[dict]]:
    """
    Run the Claude agent loop until a final text response is produced.
    Returns (final_text_response, updated_messages_list).

    The loop:
      1. Call Claude with current messages + tools
      2. If Claude calls a tool: execute it, append result, loop again
      3. If Claude returns end_turn: extract text response, return
    """
    import anthropic

    client = anthropic.Anthropic(api_key=get_api_key())
    model  = os.environ.get("ANTHROPIC_MODEL", "claude-3-haiku-20240307")

    # TODO: Implement the agentic loop
    # See the solution for the full pattern, but the key steps are:
    #
    # while True:
    #   response = client.messages.create(model=..., max_tokens=1024,
    #                                     tools=TOOLS, messages=messages)
    #   if response.stop_reason == "end_turn":
    #     extract text content, return
    #   elif response.stop_reason == "tool_use":
    #     append assistant message (with tool_use blocks) to messages
    #     for each tool_use block: execute_tool, build tool_result message
    #     append tool_result message to messages
    #     continue loop

    return "TODO: implement agent loop", messages

# ── Lambda Handler ────────────────────────────────────────────────────────────

def handler(event: dict, context: Any) -> dict:
    """
    API Gateway HTTP API invocation.
    event["body"] contains the JSON request body as a string.
    Must return: {"statusCode": int, "headers": {...}, "body": str}
    """
    try:
        # TODO: Parse the request body
        # body = json.loads(event.get("body") or "{}")
        # Extract session_id and message — return 400 if missing

        # TODO: Load existing conversation from DynamoDB

        # TODO: Append the new user message to messages

        # TODO: Run the agent loop

        # TODO: Save updated messages to DynamoDB

        # TODO: Return 200 with the response
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"response": "TODO", "session_id": "TODO", "message_count": 0})
        }

    except Exception as e:
        logger.exception("Unhandled error")
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }
