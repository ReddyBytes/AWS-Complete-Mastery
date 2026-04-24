# CloudTrail, AWS Config, and Audit Logging

Every action in your AWS account — every API call, every console click, every Terraform apply — generates an event. The question is whether you are recording it. CloudTrail is your flight data recorder: it writes every event to a log. AWS Config is your compliance auditor: it continuously checks whether your resources match the rules you set. Together they answer two questions every security and compliance team asks daily — "what happened?" and "are we compliant right now?"

---

## CloudTrail — The API Audit Log

**CloudTrail** records every API call made in your AWS account, whether it came from the console, CLI, SDK, or Terraform. Every call becomes a JSON event stored in S3.

```
┌─────────────────────────────────────────────────────────────────────┐
│  ANY action in AWS                                                  │
│    Console click, aws cli command, terraform apply, SDK call        │
│         │                                                           │
│         ▼                                                           │
│  AWS API (us-east-1)                                                │
│         │                                                           │
│         ├── CloudTrail event: who, what, when, from where          │
│         │          └── S3 bucket (encrypted, versioned)            │
│         │          └── CloudWatch Logs (for real-time alerts)      │
│         │                                                           │
│         └── Action performed (EC2 created, S3 object deleted, etc.)│
└─────────────────────────────────────────────────────────────────────┘
```

### Trail types

A **trail** is a configuration that tells CloudTrail where to deliver log files.

```
Management events (default, free tier):
  - Control plane: CreateBucket, RunInstances, DeleteRole
  - Who changed what infrastructure

Data events (charged, high volume):
  - S3: GetObject, PutObject, DeleteObject (per-object)
  - Lambda: InvokeFunction
  - DynamoDB: PutItem, GetItem

Insights events (anomaly detection):
  - Unusual API call rates
  - Unusual error rates
```

### Creating a trail with Terraform

```hcl
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "my-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  lifecycle {
    prevent_destroy = true    # ← never accidentally delete audit logs
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail.arn
    }
  }
}

# Bucket policy: only CloudTrail can write to this bucket
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = jsonencode({
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "main-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true    # ← IAM, STS, Route53 events
  is_multi_region_trail         = true    # ← capture all regions in one trail
  enable_log_file_validation    = true    # ← detect tampered log files
  kms_key_id                    = aws_kms_key.cloudtrail.arn

  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cw.arn
}
```

### Querying CloudTrail with AWS CLI

```bash
# Look up events for a specific user in the last hour
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=john.doe \
  --start-time "2024-01-15T09:00:00Z" \
  --end-time "2024-01-15T10:00:00Z" \
  --output json | jq '.Events[] | {time: .EventTime, event: .EventName, source: .EventSource}'

# Find who deleted an S3 bucket
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteBucket \
  --output json | jq '.Events[] | {time: .EventTime, user: .Username, bucket: .CloudTrailEvent | fromjson | .requestParameters.bucketName}'

# Find all events from a specific IP address
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=s3.amazonaws.com \
  --query 'Events[?contains(CloudTrailEvent, `"192.168.1.1"`)]'
```

### CloudTrail + Athena: query logs at scale

For historical queries beyond 90 days (CloudTrail console limit), use Athena:

```sql
-- Create table over the S3 logs (one-time setup via CloudTrail console "Create Athena Table")

-- Find all DeleteObject calls in the last 7 days
SELECT
  eventtime,
  useridentity.arn AS who,
  requestparameters
FROM cloudtrail_logs
WHERE eventname = 'DeleteObject'
  AND eventtime > date_format(now() - interval '7' day, '%Y-%m-%dT%H:%i:%sZ')
ORDER BY eventtime DESC;

-- Find all root account activity (should be near-zero in production)
SELECT eventtime, eventname, sourceipaddress
FROM cloudtrail_logs
WHERE useridentity.type = 'Root'
ORDER BY eventtime DESC;

-- Find who assumed which IAM role and when
SELECT eventtime, useridentity.arn AS assumed_by,
       requestparameters AS role_assumed
FROM cloudtrail_logs
WHERE eventname = 'AssumeRole'
ORDER BY eventtime DESC;
```

### CloudWatch metric filters and alerts

Send CloudTrail to CloudWatch Logs and create alarms for critical events:

```hcl
# Alert on root account usage
resource "aws_cloudwatch_metric_alarm" "root_usage" {
  alarm_name  = "root-account-usage"
  metric_name = "RootAccountUsage"
  namespace   = "CloudTrailMetrics"
  period      = 300
  statistic   = "Sum"
  threshold   = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_log_metric_filter" "root_usage" {
  name           = "RootAccountUsage"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"

  metric_transformation {
    name      = "RootAccountUsage"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}
```

**Standard CloudTrail metric filter alerts** (CIS AWS Benchmark):

| Event | What it detects |
|---|---|
| Unauthorized API calls | Credential theft attempts |
| Console login without MFA | Security policy violation |
| Root account usage | Should never happen post-setup |
| IAM policy changes | Privilege escalation attempts |
| CloudTrail configuration changes | Someone disabling audit logging |
| S3 bucket policy changes | Data exfiltration risk |
| Security group changes | Network perimeter changes |
| VPC changes | Network architecture changes |

---

## AWS Config — Continuous Compliance

**AWS Config** continuously monitors your resources and checks them against rules you define. While CloudTrail answers "what happened?", Config answers "are my resources compliant with my policies right now?" and "what did this resource look like 30 days ago?"

```
┌──────────────────────────────────────────────────────────────────────┐
│  Resource created/changed                                            │
│         │                                                            │
│         ▼                                                            │
│  Config recorder captures current state                              │
│  (every resource, every change)                                      │
│         │                                                            │
│         ├── Config rules evaluate: COMPLIANT or NON_COMPLIANT        │
│         │                                                            │
│         ├── Configuration history: full timeline per resource        │
│         │                                                            │
│         └── Remediation actions (auto-fix or SNS alert)             │
└──────────────────────────────────────────────────────────────────────┘
```

### Enabling Config with Terraform

```hcl
resource "aws_s3_bucket" "config" {
  bucket = "aws-config-${data.aws_caller_identity.current.account_id}"
}

resource "aws_config_configuration_recorder" "main" {
  name     = "default"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true     # ← record all resource types
    include_global_resource_types = true     # ← include IAM, etc.
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.config.bucket
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}
```

### Config rules — managed and custom

**AWS Managed Rules** (pre-built, just enable them):

```hcl
# S3 buckets must not be public
resource "aws_config_config_rule" "s3_public_read" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
}

# EBS volumes must be encrypted
resource "aws_config_config_rule" "ebs_encrypted" {
  name = "encrypted-volumes"
  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }
}

# RDS instances must have Multi-AZ enabled
resource "aws_config_config_rule" "rds_multi_az" {
  name = "rds-multi-az-support"
  source {
    owner             = "AWS"
    source_identifier = "RDS_MULTI_AZ_SUPPORT"
  }
}

# Security groups must not allow unrestricted SSH
resource "aws_config_config_rule" "ssh_restricted" {
  name = "restricted-ssh"
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
}

# Required tags on all resources
resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"
  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }
  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag2Key   = "Owner"
    tag3Key   = "CostCenter"
  })
}
```

**High-value managed rules to enable:**

| Rule | What it checks |
|---|---|
| `S3_BUCKET_PUBLIC_READ_PROHIBITED` | No public S3 buckets |
| `ENCRYPTED_VOLUMES` | All EBS volumes encrypted |
| `RDS_STORAGE_ENCRYPTED` | RDS encrypted at rest |
| `CLOUD_TRAIL_ENABLED` | CloudTrail is enabled |
| `MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS` | All IAM users have MFA |
| `ACCESS_KEYS_ROTATED` | IAM keys < 90 days old |
| `SECURITY_HUB_ENABLED` | Security Hub running |
| `VPC_FLOW_LOGS_ENABLED` | VPC flow logs active |
| `RESTRICTED_INCOMING_TRAFFIC` | No unrestricted inbound |
| `IAM_ROOT_ACCESS_KEY_CHECK` | No root access keys |

### Auto-remediation

When a rule finds a non-compliant resource, Config can auto-fix it:

```hcl
resource "aws_config_remediation_configuration" "s3_public_access" {
  config_rule_name = aws_config_config_rule.s3_public_read.name
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-DisableS3BucketPublicReadWrite"  # ← SSM Automation doc

  parameter {
    name         = "S3BucketName"
    resource_value = "RESOURCE_ID"    # ← Config passes the non-compliant resource ID
  }

  automatic                  = true
  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60
}
```

### Querying Config history

```bash
# See all changes to a specific resource over time
aws configservice get-resource-config-history \
  --resource-type AWS::EC2::SecurityGroup \
  --resource-id sg-12345678 \
  --output json | jq '.configurationItems[] | {time: .configurationItemCaptureTime, status: .configurationItemStatus}'

# List all non-compliant resources
aws configservice describe-compliance-by-resource \
  --compliance-types NON_COMPLIANT \
  --output json | jq '.ComplianceByResources[] | {type: .ResourceType, id: .ResourceId}'

# Check compliance summary across all rules
aws configservice describe-compliance-by-config-rule \
  --output json | jq '.ComplianceByConfigRules[] | {rule: .ConfigRuleName, status: .Compliance.ComplianceType}'
```

---

## AWS Security Hub — Centralized Findings

**Security Hub** aggregates findings from Config, GuardDuty, Inspector, Macie, and third-party tools into a single dashboard. It runs the CIS AWS Foundations Benchmark automatically.

```hcl
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"
}
```

---

## VPC Flow Logs — Network Audit

**VPC Flow Logs** record every network connection accepted or rejected at the VPC, subnet, or ENI level. Essential for security investigations and debugging network policies.

```hcl
resource "aws_flow_log" "vpc" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"             # ← ACCEPT, REJECT, or ALL
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
}
```

```bash
# Find all rejected traffic to a specific instance
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs \
  --filter-pattern "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action=REJECT, flowlogstatus]" \
  --output json | jq '.events[].message'
```

---

## Compliance Architecture: The Full Stack

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  GuardDuty ──────── threat detection (DNS exfil, port scan, etc.)   │
│                                │                                     │
│  CloudTrail ─────── who did what, when, from where                  │
│                                │                                     │
│  VPC Flow Logs ──── what talked to what at the network level         │
│                                │                                     │
│  AWS Config ─────── are resources compliant right now?               │
│                                │                                     │
│  Security Hub ───── central dashboard: all findings in one place     │
│                                │                                     │
│  SNS → PagerDuty / Slack ───── alert on critical findings            │
│                                                                      │
│  Athena ─────────── historical queries over all the above logs       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Common Mistakes

| Mistake | Consequence | Fix |
|---|---|---|
| Single-region trail | Events from other regions not captured | Always use `is_multi_region_trail = true` |
| No log file validation | Attacker tampers with logs to hide activity | `enable_log_file_validation = true` |
| CloudTrail bucket is public | Audit logs exposed to internet | Bucket policy blocks public access |
| No S3 lifecycle on trail bucket | Log costs grow unbounded | Set lifecycle to move to Glacier after 90 days |
| Config enabled but no rules | Config costs money but catches nothing | Enable at least CIS benchmark rules |
| Not alerting on CloudTrail config changes | Attacker disables logging undetected | Metric filter + alarm on CloudTrail changes |
| No VPC flow logs | Network incidents uninvestigable | Enable on all production VPCs |
| Security Hub not aggregated across accounts | Each account has its own blind spots | Designate a Security account as aggregator |

---

## Navigation

**Related:**
- [IAM](../06_security/iam.md) — who can do what
- [AWS Organizations](../06_security/organizations_multi_account.md) — multi-account audit strategy
- [CloudWatch](./cloudwatch.md) — metrics and alarms
- [SSM and Parameter Store](./ssm_and_parameter_store.md) — automated remediation
- [VPC](../05_networking/vpc.md) — VPC flow logs
