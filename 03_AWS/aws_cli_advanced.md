# AWS CLI — Advanced Production Usage

> Every command you type is just a signed HTTP request. Once you see that, debugging becomes trivial.

---

## 1. What the AWS CLI Really Is

Imagine a universal TV remote. The remote does not contain the TV — it just translates button presses into infrared signals the TV understands. The AWS CLI is that remote. Under the hood, every command you type becomes a signed HTTPS request to an AWS API endpoint.

```
aws s3 ls s3://my-bucket
        ↓ translates to
GET https://s3.amazonaws.com/my-bucket
Headers:
  Authorization: AWS4-HMAC-SHA256 Credential=AKIA.../...
  x-amz-date: 20260424T120000Z
```

Understanding this has one massive practical benefit: when a CLI command fails, you know exactly what API call failed, which endpoint was hit, and what permissions were missing. The **Signature Version 4 (SigV4)** signing process is what makes every request authenticated — the CLI handles this automatically using your credentials.

```
You type:     aws ec2 describe-instances
                        ↓
CLI resolves: your credentials (from credential chain)
                        ↓
CLI builds:   HTTPS POST to ec2.us-east-1.amazonaws.com
              with SigV4-signed Authorization header
                        ↓
AWS responds: JSON payload
                        ↓
CLI formats:  json / table / text / yaml (your choice)
```

When the CLI fails, `--debug` shows you the raw HTTP request and response. That is all you need.

---

## 2. Installation and Versions

Think of aws-cli v1 and v2 like Python 2 and Python 3 — v1 still exists, but v2 is current and adds features that v1 will never get. If you are starting fresh, install v2.

### v2 vs v1 key differences

| Feature | v1 | v2 |
|---|---|---|
| `--output yaml` | Not supported | Supported |
| AWS SSO (Identity Center) | Limited | Full support |
| Auto-completion | Manual setup | Built-in (`aws_completer`) |
| Binary blobs | Base64 encoded by default | Decoded automatically |
| Installer | `pip install awscli` | Standalone pkg / brew |
| Python dependency | Requires Python | Bundled Python (no conflicts) |

### Install v2 (macOS)

```bash
brew install awscli                          # installs v2 via Homebrew
aws --version                                # confirm: aws-cli/2.x.x
```

### Initial configuration

```bash
aws configure
# AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
# AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# Default region name [None]: us-east-1
# Default output format [None]: json
```

This writes to `~/.aws/credentials` and `~/.aws/config`. You rarely need to run it again — named profiles are the production pattern.

### Shell completion setup

```bash
# bash
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bashrc
source ~/.bashrc

# zsh
echo "autoload bashcompinit && bashcompinit" >> ~/.zshrc
echo "autoload -Uz compinit && compinit" >> ~/.zshrc
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.zshrc
source ~/.zshrc
```

After this, `aws s3 <TAB>` works as expected.

---

## 3. Authentication and Profiles

Authentication is like a security badge system. There is a specific order in which the guards check your badge — first at the door (environment variables), then the desk drawer (credentials file), then they call building services (EC2 metadata), and so on. This ordered lookup is the **credential chain**.

### File structure

```
~/.aws/credentials          # stores raw credentials
~/.aws/config               # stores region, output, profile config
```

`~/.aws/credentials`:
```ini
[default]
aws_access_key_id     = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[prod]
aws_access_key_id     = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
```

`~/.aws/config`:
```ini
[default]
region = us-east-1
output = json

[profile prod]
region = us-west-2
output = table

[profile staging]
region = us-east-1
output = json
```

Note: profiles in `config` are prefixed with `profile `, but in `credentials` they are not.

### Named profiles

```bash
aws s3 ls --profile prod            # use the [prod] profile explicitly
aws ec2 describe-instances \
  --profile staging \
  --region eu-west-1                # profile + region override
```

### AWS_PROFILE environment variable

```bash
export AWS_PROFILE=prod             # all subsequent commands use prod profile
aws s3 ls                           # uses prod without --profile flag
unset AWS_PROFILE                   # restore to default
```

This is the recommended pattern for scripts that run many commands against the same account — set once, use everywhere.

### The credential chain (in order)

```
1. Environment variables
   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN

2. AWS CLI credentials file
   ~/.aws/credentials → [profile] or [default]

3. AWS CLI config file
   ~/.aws/config → [profile] with assume_role config

4. Container credentials
   ECS task role via internal metadata endpoint

5. EC2 instance metadata (IMDS)
   http://169.254.169.254/latest/meta-data/iam/

6. EKS/Pod service accounts (IRSA)
   Web identity token file + role ARN from env vars
```

The CLI walks this list top-to-bottom and uses the first match. In production, **always use roles (steps 4–6)** over static keys. Static keys in environment variables are the pattern for CI/CD when role assumption is not available.

### Verify your identity first — always

```bash
aws sts get-caller-identity
# {
#     "UserId": "AIDAIOSFODNN7EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/alice"
# }
```

Run this before any destructive operation. It tells you exactly which principal the CLI resolved to — IAM user, role, or federated identity. If the account number is wrong, stop immediately.

---

## 4. AWS SSO (Identity Center)

Traditional IAM users are like physical door keys — you cut one per person, per door. **AWS SSO (Identity Center)** is a badge system: one badge, multiple doors, permissions managed centrally, and the badge auto-expires.

### Configure SSO

```bash
aws configure sso
# SSO session name (Recommended): my-company
# SSO start URL [None]: https://my-company.awsapps.com/start
# SSO region [None]: us-east-1
# SSO registration scopes [sso:account:access]: sso:account:access
```

This writes to `~/.aws/config`:

```ini
[profile dev-account]
sso_session      = my-company
sso_account_id   = 123456789012
sso_role_name    = DeveloperAccess
region           = us-east-1
output           = json

[sso-session my-company]
sso_start_url    = https://my-company.awsapps.com/start
sso_region       = us-east-1
sso_registration_scopes = sso:account:access
```

### Login and use

```bash
aws sso login --profile dev-account       # opens browser for auth
aws s3 ls --profile dev-account           # now works with SSO credentials
aws sts get-caller-identity --profile dev-account  # verify
```

### Multiple accounts from one SSO setup

```ini
# ~/.aws/config — add more profiles, same sso-session
[profile prod-account]
sso_session    = my-company
sso_account_id = 999888777666            # different account ID
sso_role_name  = ReadOnlyAccess          # different permission set
region         = us-west-2
```

One `aws sso login` authenticates all profiles that share the same `sso-session`. Switch between accounts by switching `--profile`.

### SSO in CI/CD — use OIDC instead

AWS SSO requires a browser login flow, which does not work in CI pipelines. For CI/CD (GitHub Actions, GitLab CI, etc.), use **OIDC (OpenID Connect)** web identity federation instead:

```yaml
# GitHub Actions example
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-1
    # No static keys — GitHub provides an OIDC token, AWS exchanges it for temp creds
```

The IAM role trust policy allows GitHub's OIDC provider (`token.actions.githubusercontent.com`) to assume the role. No keys are stored anywhere.

---

## 5. Output Formats

Output formats are like the same data delivered as a spreadsheet, a wall of text, a formatted report, or a YAML config file. Same data, different shapes for different consumers.

### The four formats

| Format | Flag | Best for |
|---|---|---|
| JSON | `--output json` | Scripts, piping to `jq`, default |
| Text | `--output text` | Shell scripting with `cut`, `awk`, `grep` |
| Table | `--output table` | Human reading in terminal, NOT for scripts |
| YAML | `--output yaml` | Config-style output, v2 only |

```bash
# JSON — full structured output
aws ec2 describe-instances --output json

# Text — tab-separated, one resource per line
aws ec2 describe-instances --output text \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
# i-0abc123    running
# i-0def456    stopped

# Table — pretty, but brittle in scripts
aws ec2 describe-instances --output table \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
# +--------------------+---------+
# |    InstanceId      |  State  |
# +--------------------+---------+
# |  i-0abc123         | running |

# YAML — readable config-style (v2 only)
aws ec2 describe-instances --output yaml
```

### Rule of thumb for scripts

- Use `--output json` + `jq` when you need nested data or complex filtering.
- Use `--output text` + `--query` when you need a simple list of values for a shell loop.
- Never use `--output table` in scripts — column widths vary and parsing breaks.

---

## 6. --query (JMESPath) — the most important flag

Imagine the AWS API response is a giant filing cabinet. **JMESPath** is a path language that lets you reach in and pull out exactly the drawer, folder, or page you need — without pulling out the whole cabinet.

The `--query` flag takes a JMESPath expression and filters the JSON response before displaying it. This happens client-side, after the full API response arrives.

### Basic syntax

```bash
# Get all instance IDs across all reservations
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].InstanceId'
# [["i-0abc123"], ["i-0def456"]]

# Flatten nested arrays with []
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].InstanceId | []'   # ← [] flattens nested lists
# ["i-0abc123", "i-0def456"]

# Multi-field projection (returns array of arrays)
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
# [["i-0abc123","running"],["i-0def456","stopped"]]

# Filter: only running instances
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[?State.Name==`running`].[InstanceId]'
#                                                 ↑ backtick quotes in JMESPath

# Count instances
aws ec2 describe-instances \
  --query 'length(Reservations[*].Instances[])'
# 7
```

### JMESPath reference patterns

| Goal | Expression |
|---|---|
| Single field | `Reservations[0].Instances[0].InstanceId` |
| All values of a field | `Reservations[*].Instances[*].InstanceId` |
| Flatten nested arrays | `Reservations[*].Instances[].InstanceId` |
| Multiple fields | `Reservations[*].Instances[*].[InstanceId,State.Name]` |
| Nested field | `Reservations[*].Instances[*].State.Name` |
| Filter by value | `Reservations[*].Instances[?State.Name==\`running\`]` |
| Filter by existence | `Reservations[*].Instances[?Tags]` |
| Count | `length(Reservations[*].Instances[])` |
| First item | `Reservations[0].Instances[0]` |
| Keys of object | `keys(Tags[0])` |

### 10+ real AWS CLI + query examples

```bash
# 1. List all S3 bucket names
aws s3api list-buckets \
  --query 'Buckets[*].Name' \
  --output text

# 2. Get running EC2 instance IDs and their private IPs
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[?State.Name==`running`].[InstanceId,PrivateIpAddress]' \
  --output text

# 3. Get all Lambda function names and runtimes
aws lambda list-functions \
  --query 'Functions[*].[FunctionName,Runtime]' \
  --output table

# 4. Find EC2 instances by tag Name
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[?Tags[?Key==`Name`]|[0].Value==`web-server`].InstanceId' \
  --output text

# 5. List CloudFormation stacks that are CREATE_COMPLETE
aws cloudformation describe-stacks \
  --query 'Stacks[?StackStatus==`CREATE_COMPLETE`].StackName' \
  --output text

# 6. Get all security group IDs for a specific VPC
aws ec2 describe-security-groups \
  --filters Name=vpc-id,Values=vpc-0abc12345 \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table

# 7. Get ARN of a specific IAM role
aws iam get-role \
  --role-name MyRole \
  --query 'Role.Arn' \
  --output text

# 8. List ECS services in a cluster
aws ecs list-services \
  --cluster my-cluster \
  --query 'serviceArns[*]' \
  --output text

# 9. Get the latest AMI ID for Amazon Linux 2023
aws ec2 describe-images \
  --owners amazon \
  --filters Name=name,Values='al2023-ami-*' Name=architecture,Values=x86_64 \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' \   # ← sort and take last
  --output text

# 10. Get all RDS instance identifiers and their engine versions
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,Engine,EngineVersion]' \
  --output table

# 11. Get subnet IDs for a specific VPC
aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=vpc-0abc12345 \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' \
  --output table

# 12. List Route53 hosted zone names and IDs
aws route53 list-hosted-zones \
  --query 'HostedZones[*].[Name,Id]' \
  --output text
```

---

## 7. Pagination

Imagine asking a librarian for all books ever published. They do not hand you millions of books at once — they bring a cart at a time. AWS APIs work the same way: large result sets are split into pages, each with a **NextToken** that points to the next page.

The AWS CLI v2 **auto-paginates by default** — it keeps calling the API and accumulating pages until all results are fetched. This is convenient but can be dangerous for very large result sets (high memory usage, slow response).

```
Auto-pagination behavior:

Page 1: {Items: [...50...], NextToken: "abc123"}
                ↓ CLI fetches automatically
Page 2: {Items: [...50...], NextToken: "def456"}
                ↓
Page 3: {Items: [...42...]}  ← no NextToken = last page
                ↓
CLI returns all 142 items merged
```

### Controlling pagination

```bash
# Let CLI auto-paginate (default) — fetches ALL pages
aws ec2 describe-instances

# Disable auto-pagination — return ONLY the first page
aws ec2 describe-instances --no-paginate                   # ← first page only

# Limit items per API call (reduces memory pressure per request)
aws s3api list-objects-v2 \
  --bucket my-large-bucket \
  --page-size 100                                          # ← 100 items per API call, still auto-paginates

# Manual pagination — use a starting token
aws s3api list-objects-v2 \
  --bucket my-large-bucket \
  --starting-token "eyJ..."                               # ← resume from a specific point

# Get max items overall (stop after N total items)
aws s3api list-objects-v2 \
  --bucket my-large-bucket \
  --max-items 200                                          # ← return at most 200 total
```

### When to use each

- `--no-paginate`: when you only need a sample, or when integrating with a system that handles its own pagination.
- `--page-size`: tune for memory-constrained environments without changing total results.
- `--max-items`: cap output at a known limit (useful in dashboards or monitoring scripts).
- Default (auto-paginate): fine for most operations; avoid on buckets with millions of objects.

---

## 8. --filters vs --query

Two gates, different positions on the road. **`--filters`** is the first gate — it sits at the AWS data center and stops irrelevant data from ever traveling across the network. **`--query`** is the second gate — it sits on your machine and filters whatever arrives from AWS.

```
Without filtering:
  AWS → [all 10,000 instances] → network → CLI → you

With --filters:
  AWS → [filter: running only] → [200 instances] → network → CLI → you

With --filters + --query:
  AWS → [filter: running] → [200 instances] → network → CLI → [filter: fields] → you
```

### --filters syntax

```bash
# Server-side: only return running instances in a specific VPC
aws ec2 describe-instances \
  --filters \
    Name=instance-state-name,Values=running \            # ← filter by state
    Name=vpc-id,Values=vpc-0abc12345                     # ← AND filter by VPC

# Multiple values for a single filter (OR within the filter)
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running,stopped   # ← running OR stopped

# Filter by tag
aws ec2 describe-instances \
  --filters Name=tag:Environment,Values=production        # ← tag key=Environment, value=production
```

### When to use each

| Scenario | Use |
|---|---|
| Filter on indexed AWS attributes (state, type, VPC, tags) | `--filters` — server-side, fast, less data |
| Filter on non-filterable fields (computed, nested) | `--query` — client-side after data arrives |
| Complex logic (AND + OR + nested) | `--query` JMESPath |
| Reduce network transfer for huge result sets | `--filters` always |
| Field selection / reshaping output | `--query` always |

Best pattern: use `--filters` to reduce result set size, then `--query` to reshape the fields you actually need.

```bash
# Gold standard: server-side filter + client-side field selection
aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[*].Instances[*].[InstanceId,PrivateIpAddress,Tags[?Key==`Name`]|[0].Value]' \
  --output text
```

---

## 9. Waiting for Async Operations

AWS is asynchronous by nature. You tell EC2 to start an instance, and it says "OK, working on it." The instance is not actually running yet. **Waiters** are built-in polling loops that block your script until a resource reaches the expected state.

Think of a waiter as a patient assistant who checks the kitchen every 15 seconds and tells you only when your food is ready.

```bash
# Wait for an EC2 instance to reach running state
aws ec2 wait instance-running \
  --instance-ids i-0abc123def456789a                     # ← blocks until running or timeout

# Wait for a CloudFormation stack to finish creating
aws cloudformation wait stack-create-complete \
  --stack-name my-production-stack                       # ← polls until CREATE_COMPLETE

# Wait for an S3 bucket to exist
aws s3api wait bucket-exists \
  --bucket my-new-bucket

# Wait for an RDS instance to be available
aws rds wait db-instance-available \
  --db-instance-identifier my-database

# Wait for an ECS service to reach steady state
aws ecs wait services-stable \
  --cluster my-cluster \
  --services my-service
```

### Common waiters and their defaults

| Waiter | Service | Max wait | Poll interval |
|---|---|---|---|
| `instance-running` | EC2 | 10 min | 15 sec |
| `instance-stopped` | EC2 | 10 min | 15 sec |
| `stack-create-complete` | CloudFormation | 2 hours | 30 sec |
| `stack-delete-complete` | CloudFormation | 2 hours | 30 sec |
| `db-instance-available` | RDS | 30 min | 30 sec |
| `bucket-exists` | S3 | 20 sec | 5 sec |
| `services-stable` | ECS | 10 min | 15 sec |

Waiters exit with code `0` on success and code `255` on timeout. Use this in scripts:

```bash
aws ec2 wait instance-running --instance-ids i-0abc && echo "Instance is up" || echo "Timed out"
```

---

## 10. aws configure / Config Management for Teams

A single developer with one AWS account uses `aws configure` once and forgets about it. A team working across dev, staging, and prod accounts with MFA and assumed roles needs a structured config strategy.

### Environment-specific profiles

```ini
# ~/.aws/config

[profile dev]
region           = us-east-1
output           = json
sso_session      = my-company
sso_account_id   = 111111111111
sso_role_name    = DeveloperAccess

[profile staging]
region           = us-east-1
output           = json
sso_session      = my-company
sso_account_id   = 222222222222
sso_role_name    = DeveloperAccess

[profile prod]
region           = us-east-1
output           = json
sso_session      = my-company
sso_account_id   = 333333333333
sso_role_name    = ReadOnlyAccess                        # ← limited access in prod
```

### Assumed roles in config

For non-SSO setups where you assume a cross-account role:

```ini
[profile dev]
region         = us-east-1

[profile prod-deployer]
role_arn       = arn:aws:iam::333333333333:role/DeployerRole   # ← role to assume
source_profile = dev                                            # ← use dev creds to assume it
region         = us-east-1
output         = json
```

```bash
aws sts get-caller-identity --profile prod-deployer
# CLI automatically calls sts:AssumeRole using dev credentials, then uses temp creds
```

### MFA token integration

```ini
[profile mfa-required]
role_arn            = arn:aws:iam::333333333333:role/AdminRole
source_profile      = dev
mfa_serial          = arn:aws:iam::111111111111:mfa/alice     # ← your MFA device ARN
role_session_name   = alice-session
```

```bash
aws s3 ls --profile mfa-required
# Enter MFA code: 123456
# (CLI caches temp credentials for the session duration)
```

### credential_process for custom providers

For Vault, custom PKI, or proprietary identity providers:

```ini
[profile vault-creds]
credential_process = /usr/local/bin/vault-aws-creds.sh prod   # ← must output JSON with AccessKeyId etc
region             = us-east-1
```

The script must print:
```json
{
  "Version": 1,
  "AccessKeyId": "...",
  "SecretAccessKey": "...",
  "SessionToken": "...",
  "Expiration": "2026-04-24T15:00:00Z"
}
```

---

## 11. Useful CLI Patterns for Production Scripts

A production script is like a surgeon's checklist — predictable, explicit, and designed to fail loudly rather than silently do the wrong thing.

### Dry-run flags

```bash
# EC2 — test permission without making changes
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --dry-run                                              # ← validates IAM permission only; always fails with DryRunOperation

# Check for DryRunOperation in exit code
aws ec2 run-instances ... --dry-run 2>&1 | grep -q "DryRunOperation" && echo "Permission OK"
```

### Idempotency tokens

```bash
# Prevent duplicate resource creation if script re-runs
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --instance-type t3.micro \
  --client-token "deploy-$(date +%Y%m%d)-v1"            # ← same token = same request = no duplicate
```

### --cli-input-json for complex inputs

Long argument lists become unmaintainable. Use JSON input for anything non-trivial:

```bash
# Write the request to a file
cat > launch-config.json <<EOF
{
  "ImageId": "ami-0abcdef1234567890",
  "InstanceType": "t3.micro",
  "MinCount": 1,
  "MaxCount": 1,
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [{"Key": "Environment", "Value": "prod"}]
    }
  ]
}
EOF

aws ec2 run-instances --cli-input-json file://launch-config.json
```

Generate a template for any command:
```bash
aws ec2 run-instances --generate-cli-skeleton > launch-config.json   # ← full skeleton
```

### aws ... | jq pipelines

```bash
# 1. Pretty-print and colorize any AWS output
aws ec2 describe-instances | jq .

# 2. Extract all instance IDs as a plain list
aws ec2 describe-instances | jq -r '.Reservations[].Instances[].InstanceId'

# 3. Get private IPs of running instances
aws ec2 describe-instances \
  | jq -r '.Reservations[].Instances[] | select(.State.Name=="running") | .PrivateIpAddress'

# 4. Summarize S3 buckets with creation date
aws s3api list-buckets \
  | jq -r '.Buckets[] | "\(.Name)\t\(.CreationDate)"'

# 5. Get security group names for a specific instance
aws ec2 describe-instances --instance-ids i-0abc123 \
  | jq -r '.Reservations[].Instances[].SecurityGroups[].GroupName'

# 6. Create a shell variable from CLI output
BUCKET_ARN=$(aws s3api get-bucket-location --bucket my-bucket | jq -r '.LocationConstraint')

# 7. Count objects in an S3 bucket by storage class
aws s3api list-objects-v2 --bucket my-bucket \
  | jq '.Contents | group_by(.StorageClass) | map({class: .[0].StorageClass, count: length})'

# 8. Get latest CloudWatch log stream
aws logs describe-log-streams \
  --log-group-name /aws/lambda/my-function \
  --order-by LastEventTime \
  --descending \
  | jq -r '.logStreams[0].logStreamName'

# 9. List IAM roles with their ARNs as key-value pairs
aws iam list-roles | jq -r '.Roles[] | "\(.RoleName): \(.Arn)"'

# 10. Extract task definition family names from ECS
aws ecs list-task-definitions \
  | jq -r '.taskDefinitionArns[] | split("/")[1] | split(":")[0]' \
  | sort -u                                              # ← unique family names only
```

---

## 12. AWS CLI in CI/CD

CI/CD pipelines are automated workers in a locked room with no browser. They cannot use SSO, MFA, or interactive login. Authentication must be non-interactive, scoped to minimum permissions, and rotation-safe.

### OIDC-based auth (GitHub Actions → AWS) — recommended

```
GitHub Actions runner
        ↓ requests OIDC token from GitHub
GitHub OIDC provider
        ↓ issues signed JWT
AWS STS (AssumeRoleWithWebIdentity)
        ↓ validates JWT against trusted OIDC provider
        ↓ issues temporary credentials
Your workflow
        ↓ uses temp creds for AWS CLI / SDK
```

```yaml
# .github/workflows/deploy.yml
permissions:
  id-token: write                           # ← required: allows requesting OIDC token
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsDeployer
          aws-region: us-east-1
          # No keys stored anywhere — pure OIDC exchange

      - name: Verify identity
        run: aws sts get-caller-identity

      - name: Deploy
        run: aws cloudformation deploy --stack-name my-stack --template-file template.yml
```

The IAM role trust policy must allow `token.actions.githubusercontent.com` as a trusted OIDC provider and constrain by repo and branch.

### aws configure set for programmatic setup

```bash
# In CI when you must use static keys (legacy pattern)
aws configure set aws_access_key_id     "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set default.region        "us-east-1"
```

### Environment variables in CI

```bash
# Set in CI system secrets, not in code
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...       # required when using assumed roles / STS temp creds
AWS_DEFAULT_REGION=us-east-1
```

The CLI picks these up from the credential chain (step 1). They override everything else.

### Least-privilege IAM for CI roles

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DescribeStacks",
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"    // ← restrict to one region
        }
      }
    }
  ]
}
```

Grant only the actions the pipeline actually performs. Review with `aws iam simulate-principal-policy` before going live.

---

## 13. Debugging CLI Issues

When the CLI fails, you are debugging an HTTP API call. The `--debug` flag turns the remote control into a glass box — you see every signal sent and every response received.

### --debug flag

```bash
aws s3 ls --debug 2>&1 | head -100
# 2026-04-24 12:00:00,000 - MainThread - awscli.clidriver - DEBUG - CLI version: 2.x.x
# 2026-04-24 12:00:00,001 - MainThread - botocore.credentials - DEBUG - Found credentials in shared credentials file
# 2026-04-24 12:00:00,002 - MainThread - botocore.endpoint - DEBUG - Making request for OperationModel(name=ListBuckets)
# 2026-04-24 12:00:00,003 - MainThread - urllib3.connectionpool - DEBUG - https://s3.amazonaws.com:443 "GET / HTTP/1.1" 200
```

Look for:
- Which credentials were found and from where (credential chain step)
- The exact endpoint being called
- The HTTP status code returned
- Any error message in the response body

### Reading debug output

```
Key lines to find in --debug output:

"Found credentials in ..."     → which credential chain step resolved
"Making request for ..."       → which API operation
"https://... HTTP/1.1"         → actual endpoint + status
"An error occurred ..."        → AWS error code and message
"AccessDenied"                 → IAM policy missing this action
"InvalidClientTokenId"         → bad or expired credentials
```

### AWS_CA_BUNDLE for custom certificates

```bash
# Corporate proxy / custom CA — SSL verification fails without this
export AWS_CA_BUNDLE=/etc/ssl/certs/corporate-ca-bundle.pem
aws s3 ls                                                # now trusts your corporate CA
```

### Endpoint URL overrides for LocalStack

**LocalStack** is a local AWS emulator for development and testing. Override the endpoint to point CLI at it:

```bash
# LocalStack runs on localhost:4566
aws --endpoint-url http://localhost:4566 s3 ls          # ← all S3 calls go to LocalStack
aws --endpoint-url http://localhost:4566 \
  sqs create-queue --queue-name test-queue

# Or set permanently via env var
export AWS_ENDPOINT_URL=http://localhost:4566
aws s3 ls                                               # ← uses LocalStack endpoint
```

You can also configure per-service endpoints in `~/.aws/config`:

```ini
[profile localstack]
endpoint_url = http://localhost:4566
region       = us-east-1
output       = json
```

---

## 14. Common Mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Forgetting `--region` | Wrong region's resources returned, or `Could not connect to the endpoint URL` | Always specify `--region` or set in profile; set `AWS_DEFAULT_REGION` in scripts |
| `--output text` with complex JSON | Script gets garbled multi-line text | Use `--output json` + `jq` for nested structures |
| `--output table` in a script | Script breaks when column widths change | Never use `table` in scripts; use `text` or `json` |
| JMESPath string literals without backticks | `--query` returns null or error | String literals in JMESPath use backticks: `` `running` `` not `"running"` |
| JMESPath backtick quoting in double-quoted shell strings | Shell eats the backticks | Wrap `--query` in single quotes: `--query '...'` |
| Credential chain confusion | Wrong account / access denied | Always run `aws sts get-caller-identity` first |
| Auto-pagination on large buckets | Script hangs for minutes, OOM on huge result sets | Use `--no-paginate` + `--max-items` for large collections |
| Static keys in scripts committed to git | Secret exposure | Use IAM roles, OIDC, or `credential_process` — never hardcode |
| `--dry-run` not checking exit code | Assuming success when CLI always errors on dry-run | `dry-run` ALWAYS returns error; check for `DryRunOperation` in message |
| Missing `AWS_SESSION_TOKEN` with temp creds | `InvalidClientTokenId` or `ExpiredTokenException` | Temp credentials always need all three: key + secret + session token |

---

## Navigation

Back to: [03_AWS README](./README.md)

Related topics:
- [IAM](./06_security/iam.md) — policies, roles, trust relationships
- [EKS](./10_containers/) — IRSA, pod identity, Kubernetes on AWS
- [jq and JSON](../01_Linux/jq_and_json.md) — JSON processing for CLI pipelines
