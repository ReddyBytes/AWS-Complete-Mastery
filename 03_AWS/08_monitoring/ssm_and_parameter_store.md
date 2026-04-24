# AWS Systems Manager (SSM) and Parameter Store

Think of a hotel with a thousand rooms. The old way: a physical master key for every housekeeper, a maintenance crew that knocks on doors and waits for guests to answer, and no log of who entered room 427 at 3pm. The new way: a central management system where the hotel manager can dispatch a task to any room, open any door without carrying a key, and see a full audit trail of every entry — all from a single console.

**AWS Systems Manager (SSM)** is that central management system for your AWS infrastructure. It lets you run commands across hundreds of instances, connect to servers without opening port 22, manage configuration values, and automate operational runbooks — all without distributing keys or credentials.

---

## 1. What SSM Is

SSM is a suite of capabilities, not a single service. The umbrella covers:

- **Session Manager** — SSH-like shell access via the AWS API (no port 22, no bastion)
- **Run Command** — execute scripts on N instances simultaneously
- **Patch Manager** — automated OS patching with compliance reporting
- **Parameter Store** — hierarchical key-value store for configuration and secrets
- **Automation** — YAML runbooks for multi-step operational workflows
- **Inventory** — collect software/hardware metadata from instances

All capabilities share the same prerequisite: the **SSM Agent** must be running on the instance, and the instance must be able to reach the SSM API (either via public internet or a VPC endpoint).

```
Your Machine / CI / Console
        |
        | AWS API call (HTTPS)
        v
   SSM Service
        |
        | SSM Agent polling (HTTPS outbound from instance)
        v
   EC2 Instance (SSM Agent running)
```

The instance calls out to SSM — SSM never calls in. This is why no inbound port is required.

---

## 2. SSM Session Manager — SSH Without SSH

Traditional SSH requires:
- Port 22 open in a security group
- A bastion host in a public subnet
- Key pairs distributed to operators
- No centralized audit log

Session Manager replaces all of this. The instance connects to SSM over HTTPS (outbound, port 443). When you start a session, the SSM service brokers the connection. No inbound port, no bastion, no key distribution.

### Starting a session from the CLI

```bash
# Connect to an instance by ID
aws ssm start-session --target i-0abc123def456789a

# Connect to a specific port (port forwarding)
aws ssm start-session \
  --target i-0abc123def456789a \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["5432"],"localPortNumber":["15432"]}'
# ← forwards RDS port locally for debugging without VPN
```

### IAM permissions required

The role or user initiating the session needs:

```json
{
  "Effect": "Allow",
  "Action": [
    "ssm:StartSession",
    "ssm:TerminateSession",
    "ssm:ResumeSession",
    "ssm:DescribeSessions"
  ],
  "Resource": "*"
}
```

The EC2 instance profile needs the managed policy `AmazonSSMManagedInstanceCore`.

### Requirements checklist

```
Checklist: SSM Session Manager
 [x] SSM Agent installed and running (pre-installed on Amazon Linux 2, Ubuntu 20.04+)
 [x] Instance profile with AmazonSSMManagedInstanceCore
 [x] SSM endpoint reachable:
     - Public internet (default), OR
     - VPC endpoints: ssm, ssmmessages, ec2messages
 [ ] No requirement: open port 22, key pair, bastion host
```

### Audit trail

Every session is logged in **CloudTrail** (StartSession, TerminateSession events). You can also configure Session Manager to stream session content (keystrokes) to CloudWatch Logs or S3 for compliance.

---

## 3. SSM Run Command — Run Commands at Scale

**Run Command** lets you execute a shell script on any number of instances without logging in. Target by instance ID, tag, or resource group.

Think of it as broadcasting a task to every chef in the kitchen simultaneously: "Update the menu board" — and each chef does it independently, at the same time.

### Basic usage

```bash
# Run a shell command on one instance
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=instanceIds,Values=i-0abc123def456789a" \
  --parameters 'commands=["df -h"]' \
  --output text

# Run on all instances tagged Environment=prod
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Environment,Values=prod" \
  --parameters 'commands=["systemctl status nginx"]'
```

### Rate control — prevent thundering herd

```bash
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Environment,Values=prod" \
  --parameters 'commands=["sudo systemctl restart app"]' \
  --max-concurrency "10"  \        # ← run on 10 instances at a time
  --max-errors "5%"                # ← stop if 5% of targets fail
```

### Collecting output

```bash
# Store output in S3
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Role,Values=webserver" \
  --parameters 'commands=["cat /etc/app/version.txt"]' \
  --output-s3-bucket-name "my-ssm-output-bucket" \
  --output-s3-key-prefix "run-command-results/"

# Wait and fetch result from a specific invocation
COMMAND_ID="abc-123-..."
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "i-0abc123def456789a" \
  --query '[Status,StandardOutputContent]'
```

### Practical: rotate a config file on all prod instances

```bash
#!/usr/bin/env bash

NEW_CONFIG=$(cat /deploy/app.conf | base64)  # ← encode to pass safely

aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:Environment,Values=prod" \
  --parameters "{
    \"commands\": [
      \"echo '${NEW_CONFIG}' | base64 -d > /etc/app/app.conf\",
      \"systemctl reload app\"
    ]
  }" \
  --max-concurrency "20%" \        # ← roll out to 20% at a time
  --max-errors "5%"
```

---

## 4. SSM Patch Manager

**Patch Manager** automates OS patching across fleets of instances, replacing ad-hoc cron jobs with a managed, auditable system.

Key concepts:

- **Patch baseline**: defines which patches are approved for installation (by severity, classification, age)
- **Maintenance window**: when patching runs (schedule, duration, targets)
- **Patch group**: a tag (`Patch Group: prod-linux`) that associates instances with a baseline
- **Compliance**: after patching, SSM reports which instances are compliant or missing patches

```bash
# View patch compliance for all instances
aws ssm describe-instance-patch-states-for-patch-group \
  --patch-group "prod-linux" \
  --query 'InstancePatchStates[*].[InstanceId,MissingCount,FailedCount,InstalledCount]'
```

---

## 5. Parameter Store — Configuration Management

**Parameter Store** is a hierarchical key-value store for configuration data and secrets. The hierarchy is a path, like a filesystem:

```
/myapp/
├── prod/
│   ├── db_password      (SecureString, encrypted with KMS)
│   ├── db_host          (String)
│   └── feature_flags    (StringList)
└── dev/
    ├── db_password
    └── db_host
```

### Parameter types

| Type | Use case | Encrypted? |
|---|---|---|
| String | Non-sensitive config (regions, hostnames, feature flags) | No |
| StringList | Comma-separated values | No |
| SecureString | Passwords, API keys, tokens | Yes (KMS) |

### Basic CLI operations

```bash
# Write a parameter
aws ssm put-parameter \
  --name "/myapp/prod/db_password" \
  --value "supersecret123" \
  --type SecureString \
  --key-id "alias/myapp-key" \     # ← KMS key to encrypt with
  --overwrite

# Read a parameter
aws ssm get-parameter \
  --name "/myapp/prod/db_password" \
  --with-decryption \              # ← required for SecureString
  --query 'Parameter.Value' \
  --output text

# Read all parameters under a path (recursive)
aws ssm get-parameters-by-path \
  --path "/myapp/prod/" \
  --recursive \
  --with-decryption \
  --query 'Parameters[*].[Name,Value]'
```

### Versioning

Every `put-parameter` with `--overwrite` creates a new version. You can retrieve older versions:

```bash
# Get version 3 of a parameter
aws ssm get-parameter \
  --name "/myapp/prod/db_password:3" \
  --with-decryption

# List version history
aws ssm get-parameter-history \
  --name "/myapp/prod/db_password" \
  --with-decryption
```

---

## 6. Parameter Store vs Secrets Manager

A common question: when do I use Parameter Store and when do I use Secrets Manager?

The short answer: Parameter Store is the file cabinet (cheap, good for config). Secrets Manager is the vault (costs more, but rotates credentials automatically).

```
Dimension          | Parameter Store           | Secrets Manager
-------------------|---------------------------|---------------------------
Cost               | Standard: free            | $0.40/secret/month
                   | Advanced: $0.05/param/mo  |
Auto-rotation      | No (manual via Lambda)    | Yes (built-in for RDS,
                   |                           | Redshift, Documenten DB)
Cross-account      | IAM policies only         | Resource-based policies
                   |                           | (like S3 bucket policies)
Max value size     | 4 KB (Standard)           | 64 KB
                   | 8 KB (Advanced)           |
Versioning         | Yes                       | Yes (with stages: AWSCURRENT,
                   |                           | AWSPREVIOUS)
Hierarchical paths | Yes                       | No (flat namespace)
```

Decision guide:

- Non-sensitive config values → Parameter Store String (free)
- Sensitive config that you rotate manually → Parameter Store SecureString
- Database passwords that need auto-rotation → Secrets Manager
- Secrets shared across accounts → Secrets Manager (resource policies)

---

## 7. Parameter Store in Applications

### Python with boto3

```python
import boto3
import json

ssm = boto3.client('ssm', region_name='us-east-1')

def get_param(name: str) -> str:
    response = ssm.get_parameter(
        Name=name,
        WithDecryption=True         # ← required for SecureString
    )
    return response['Parameter']['Value']

# Load all params for an app at startup
def load_config(env: str) -> dict:
    response = ssm.get_parameters_by_path(
        Path=f"/myapp/{env}/",
        Recursive=True,
        WithDecryption=True
    )
    # Convert list of {Name, Value} to flat dict
    return {
        p['Name'].split('/')[-1]: p['Value']
        for p in response['Parameters']
    }

config = load_config('prod')
db_password = config['db_password']
```

### Lambda: reference Parameter Store at deploy time

In a Lambda function's environment variable configuration, reference a parameter by ARN:

```
Environment variable: DB_PASSWORD
Value: {{resolve:ssm-secure:/myapp/prod/db_password:2}}
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
       ← CloudFormation-style dynamic reference; Lambda resolves at deploy
```

### ECS task definition: `valueFrom`

```json
{
  "containerDefinitions": [
    {
      "name": "api",
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789:parameter/myapp/prod/db_password"
        }
      ]
    }
  ]
}
```

The ECS agent fetches and injects the secret at container start. The container process sees it as a normal environment variable. No boto3 call required in application code.

---

## 8. Parameter Store in Terraform

### Reading an existing parameter

```hcl
# Read a parameter created outside Terraform (e.g., manually set secret)
data "aws_ssm_parameter" "db_password" {
  name            = "/myapp/prod/db_password"
  with_decryption = true
}

resource "aws_db_instance" "main" {
  password = data.aws_ssm_parameter.db_password.value
  # ...
}
```

### Creating a parameter

```hcl
resource "aws_kms_key" "param_key" {
  description = "Key for Parameter Store secrets"
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/myapp/prod/db_password"
  type        = "SecureString"
  value       = var.db_password             # ← set via -var or tfvars
  key_id      = aws_kms_key.param_key.id

  tags = {
    Environment = "prod"
    App         = "myapp"
  }
}
```

Note: storing the value in `terraform.tfvars` means it appears in plaintext in your state file. Use Secrets Manager or a secrets backend (Vault, AWS Secrets Manager as Terraform state backend) to avoid this.

---

## 9. SSM Automation — Runbooks

**Automation** documents are YAML runbooks that execute multi-step operational procedures. Think of them as codified SOPs (Standard Operating Procedures) — instead of a human following a checklist, SSM executes each step and logs the result.

### Pre-built documents

```bash
# List available AWS-managed automation documents
aws ssm list-documents \
  --document-filter-list "key=Owner,value=Amazon" \
  --query 'DocumentIdentifiers[*].Name'

# Common ones:
# AWS-StopEC2Instance
# AWS-StartEC2Instance
# AWS-RestartEC2Instance
# AWS-CreateImage
# AWS-UpdateSSMAgent
```

### Custom automation document

```yaml
# doc: restart-and-verify.yml
schemaVersion: '0.3'
description: 'Restart app service and verify it came back healthy'
parameters:
  InstanceId:
    type: String
    description: 'The EC2 instance to restart the service on'
mainSteps:
  - name: RestartService
    action: aws:runCommand
    inputs:
      DocumentName: AWS-RunShellScript
      InstanceIds:
        - '{{ InstanceId }}'
      Parameters:
        commands:
          - 'sudo systemctl restart app'

  - name: WaitForHealthy
    action: aws:waitForAwsResourceProperty
    inputs:
      Service: ssm
      Api: GetCommandInvocation
      PropertySelector: '$.Status'
      DesiredValues:
        - Success

  - name: VerifyHealth
    action: aws:runCommand
    inputs:
      DocumentName: AWS-RunShellScript
      InstanceIds:
        - '{{ InstanceId }}'
      Parameters:
        commands:
          - 'curl -sf http://localhost:8080/health'
```

### EventBridge trigger for automatic remediation

```hcl
# Trigger an SSM Automation runbook when GuardDuty finds a compromised instance
resource "aws_cloudwatch_event_rule" "compromised_instance" {
  name        = "detect-compromised-instance"
  description = "Trigger isolation automation on GuardDuty finding"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      type = [{ prefix = "UnauthorizedAccess:EC2" }]
    }
  })
}

resource "aws_cloudwatch_event_target" "isolate" {
  rule     = aws_cloudwatch_event_rule.compromised_instance.name
  arn      = "arn:aws:ssm:us-east-1:123456789:automation-definition/IsolateEC2Instance"
  role_arn = aws_iam_role.eventbridge_ssm.arn
}
```

---

## 10. Common Mistakes

| Mistake | What goes wrong | Fix |
|---|---|---|
| SSM Agent not installed | Sessions and Run Command fail silently | Use Amazon Linux 2 / Ubuntu 20.04+ (pre-installed), or add agent install to user data |
| Missing IAM permissions | `AccessDeniedException` with no clear message | Instance profile needs `AmazonSSMManagedInstanceCore`; caller needs `ssm:StartSession` or `ssm:SendCommand` |
| No VPC endpoint in private subnet | Instances in private VPCs cannot reach SSM API | Create VPC endpoints for `ssm`, `ssmmessages`, and `ec2messages` |
| Wrong VPC endpoint (missing one) | Sessions work but Run Command fails (or vice versa) | All three endpoints are required: ssm + ssmmessages + ec2messages |
| Flat Parameter Store naming | `/db_password` instead of `/app/prod/db_password` — cannot query by path | Design hierarchy before writing first parameter; hard to rename later |
| Storing Parameter Store ARN instead of value in ECS | ECS cannot resolve the value; task fails to start | Use `valueFrom` with the full parameter ARN, ensure task role has `ssm:GetParameter` |
| Using Parameter Store for high-rotation secrets | No auto-rotation means manually updating passwords + deploying everywhere | Use Secrets Manager with automatic rotation for database credentials |

---

## Navigation

- Previous: [cloudwatch.md](cloudwatch.md)
- Next: [organizations_multi_account.md](../06_security/organizations_multi_account.md)
- Related: [iam.md](../../iam.md)
