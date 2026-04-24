# Terraform Testing and Validation — Catching Bugs Before They Hit Production

## The Building Permit Analogy

An architect does not hand blueprints to a construction crew and say "build it, we'll see what happens." Before a single foundation is poured, the blueprints go through a review process: a structural engineer checks load calculations, a fire marshal checks egress routes, a building inspector signs off on compliance. Problems caught on paper cost nothing. Problems caught after the concrete is poured cost everything.

Terraform is the same. An infrastructure bug that slips through to `apply` can misconfigure a production database, expose an S3 bucket to the public, or silently provision the wrong instance type. **Testing** and **validation** are the review process that catches these problems at the blueprint stage — before any real resources are created.

---

## The Testing Pyramid for Infrastructure as Code

Think of testing as a pyramid. At the base: fast, cheap checks you run constantly. At the top: slow, expensive tests you run deliberately. The goal is to catch most bugs at the base and only let genuinely complex scenarios reach the top.

```
                        ┌─────────────────────────────┐
                        │    INTEGRATION TESTS        │  ← Slowest, most thorough
                        │  Terraform test / Terratest  │    Actually creates resources
                        │      (minutes to hours)      │
                      ┌─┴─────────────────────────────┴─┐
                      │      PLAN VALIDATION             │  ← Medium speed
                      │   conftest / OPA policies        │    Validates plan output
                      │        (seconds)                 │
                    ┌─┴─────────────────────────────────┴─┐
                    │         STATIC ANALYSIS              │  ← Fastest, cheapest
                    │   terraform validate + tflint        │    No AWS calls at all
                    │   checkov security scanning          │
                    │         (< 1 second)                 │
                    └─────────────────────────────────────┘
```

Run the base of the pyramid on every commit. Run the middle on every PR. Run the top on main-branch merges or scheduled CI runs.

---

## terraform validate — Built-in Syntax Checking

Before reaching for any external tool, use the validator that ships with Terraform itself.

`terraform validate` reads your `.tf` files and checks that:
- All required arguments are present
- Variable references point to declared variables
- Resource types are spelled correctly
- The HCL syntax is valid

It does **not** make any API calls to AWS. It does not know whether `ami-0abc123` actually exists in your region. It only checks whether Terraform can parse and understand your configuration.

```bash
terraform init        # ← providers must be downloaded first
terraform validate    # ← now validate; outputs OK or error list
```

Example output when something is wrong:

```
│ Error: Reference to undeclared resource
│
│   on main.tf line 14, in resource "aws_instance" "web":
│   14:   subnet_id = aws_subnet.privat.id
│
│ A managed resource "aws_subnet" "privat" has not been declared.
│ Did you mean aws_subnet.private?
```

Use `validate` as the first gate in CI — it is instant and catches typos before anything heavier runs.

**Difference from `terraform plan`**: `plan` makes real AWS API calls to determine current state and diff it against your config. `validate` never contacts AWS. Always run `validate` before `plan`.

---

## tflint — Linting for Terraform

`terraform validate` checks syntax. **tflint** checks _correctness_ — rules that Terraform itself cannot catch because it does not know about AWS service limits, deprecated features, or naming conventions.

Think of it as the difference between a spell-checker (validate) and a grammar and style guide reviewer (tflint). Your sentence can be grammatically valid but still wrong.

### What tflint catches

- Invalid instance types — `t3.micr` instead of `t3.micro`
- Deprecated arguments — using old resource attributes that were removed in a provider update
- Missing required tags — if your policy requires every resource to have a `team` tag
- Variable declarations with no type annotation
- Unused variable declarations

### Installation

```bash
# macOS
brew install tflint

# Linux / CI
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
```

### Configuration: .tflint.hcl

Place this file at the root of your Terraform project:

```hcl
# .tflint.hcl

plugin "aws" {
  enabled = true          # ← enable AWS-specific rules
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "aws_instance_invalid_type" {
  enabled = true          # ← catch misspelled instance types
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["Environment", "Team", "CostCenter"]  # ← required tags
}

rule "terraform_deprecated_interpolation" {
  enabled = true          # ← flag old ${var.foo} in non-string context
}

rule "terraform_unused_declarations" {
  enabled = true          # ← warn on declared but unused variables
}
```

### Running tflint

```bash
# Initialize plugins (downloads AWS ruleset)
tflint --init

# Run with compact output — ideal for CI
tflint --format compact

# Run on a specific directory
tflint --chdir ./modules/vpc
```

### Running in CI

```yaml
- name: tflint
  run: |
    tflint --init
    tflint --format compact --minimum-failure-severity=error
    # ↑ exits non-zero if any error-level findings exist
```

---

## checkov — Security Scanning

If tflint is a code reviewer, **checkov** is a security auditor. It reads your Terraform files and flags configurations that violate security best practices: unencrypted storage, publicly accessible buckets, overly permissive IAM policies, missing logging.

Checkov ships with hundreds of built-in policies mapped to CIS benchmarks, SOC 2 controls, and AWS Well-Architected Framework recommendations.

### What checkov scans for

| Category | Example finding |
|---|---|
| Encryption | S3 bucket missing server-side encryption |
| Access control | Security group allows `0.0.0.0/0` on port 22 |
| Logging | CloudTrail not enabled in all regions |
| IAM | IAM policy uses `*` for actions or resources |
| Public access | S3 bucket `block_public_acls = false` |
| TLS | Load balancer listener using HTTP, not HTTPS |

### Running checkov

```bash
# Install
pip install checkov

# Scan current directory
checkov -d . --framework terraform

# Scan and output only failures (suppress passed checks)
checkov -d . --framework terraform --quiet

# Output as JSON for downstream processing
checkov -d . --framework terraform -o json > checkov_results.json
```

Example output:

```
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
  FAILED for resource: aws_s3_bucket.app_data
  File: /main.tf:12-20

Check: CKV_AWS_21: "Ensure the S3 bucket has versioning enabled"
  PASSED for resource: aws_s3_bucket.app_data
```

### Inline skip annotations

Sometimes a finding is a known, intentional exception. Rather than disabling the rule globally, annotate the specific resource:

```hcl
resource "aws_s3_bucket" "public_assets" {
  bucket = "my-public-website-assets"

  #checkov:skip=CKV_AWS_18:Access logging not required for public static assets
  #checkov:skip=CKV_AWS_20:This bucket is intentionally public — serves static HTML
}
```

The annotation format is `#checkov:skip=CHECK_ID:reason`. Always include a reason — it documents the decision for future reviewers.

### Common findings and fixes

| Finding | Fix |
|---|---|
| `CKV_AWS_18` — no S3 access logging | Add `logging { target_bucket = ... }` block |
| `CKV_AWS_57` — S3 ignores public ACLs | Set `block_public_acls = true` in `aws_s3_bucket_public_access_block` |
| `CKV_AWS_8` — EC2 no IMDSv2 | Set `metadata_options { http_tokens = "required" }` |
| `CKV_AWS_111` — IAM wildcard actions | Replace `"Action": "*"` with specific action list |
| `CKV_AWS_135` — EBS not encrypted | Set `encrypted = true` on `aws_ebs_volume` |

### Integrating checkov in CI

```yaml
- name: checkov security scan
  run: |
    pip install checkov
    checkov -d . \
      --framework terraform \
      --quiet \
      --soft-fail-on MEDIUM \    # ← MEDIUM findings warn, don't fail
      --hard-fail-on HIGH,CRITICAL  # ← HIGH/CRITICAL fail the build
```

---

## terraform test — Built-in Integration Testing (Terraform 1.6+)

Terraform 1.6 introduced a native testing framework. No external language required — tests are written in HCL and live alongside your modules.

Think of it like unit tests for a function: you call the module with specific inputs, Terraform creates the real resources, and then you assert the outputs match what you expected. When the test finishes, Terraform destroys everything.

### File structure

```
modules/
└── s3_bucket/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── tests/
        ├── basic.tftest.hcl       # ← test files end in .tftest.hcl
        └── encryption.tftest.hcl
```

### Test file syntax

```hcl
# tests/basic.tftest.hcl

# Declare variables your module needs
variables {
  bucket_name = "test-bucket-${run.setup.output.suffix}"  # ← unique name per run
  environment = "test"
}

# A "run" block is one test case
run "bucket_exists_and_is_private" {
  command = apply  # ← actually creates resources (default)

  # Assert output values
  assert {
    condition     = output.bucket_arn != ""        # ← arn was set
    error_message = "Expected bucket ARN to be set"
  }

  assert {
    condition     = output.bucket_id == var.bucket_name
    error_message = "Bucket ID did not match expected name"
  }
}

run "bucket_is_encrypted" {
  command = plan  # ← plan only, no resources created (faster)

  assert {
    condition     = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Bucket must use AES256 encryption"
  }
}

# Test that invalid input fails as expected
run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "staging"  # ← not in allowed_values
  }

  expect_failures = [
    var.environment,  # ← expect this variable's validation to fail
  ]
}
```

### Running tests

```bash
# Run all tests for the current module
terraform test

# Run a specific test file
terraform test -filter=tests/basic.tftest.hcl

# Verbose output
terraform test -verbose
```

### Complete example: testing an S3 module

```hcl
# modules/s3_bucket/tests/full_test.tftest.hcl

provider "aws" {
  region = "us-east-1"
}

variables {
  bucket_name = "terraform-test-${plantimestamp()}"  # ← unique name avoids conflicts
  environment = "test"
  enable_versioning = true
}

run "creates_versioned_private_bucket" {
  command = apply

  assert {
    condition     = output.bucket_id != ""
    error_message = "bucket_id output must not be empty"
  }

  assert {
    condition     = !output.is_public
    error_message = "Bucket must not be public"
  }

  assert {
    condition     = output.versioning_enabled == true
    error_message = "Versioning must be enabled when enable_versioning is true"
  }
}

run "disabling_versioning_works" {
  command = apply

  variables {
    enable_versioning = false
  }

  assert {
    condition     = output.versioning_enabled == false
    error_message = "Versioning should be disabled"
  }
}
```

### terraform test vs Terratest

| Aspect | terraform test | Terratest |
|---|---|---|
| Language | HCL | Go |
| Setup required | None | Go toolchain |
| AWS assertions | Limited (output values) | Full AWS SDK access |
| HTTP checks | Not built in | Yes, via helpers |
| Best for | Module output validation | End-to-end service checks |
| Speed | Moderate | Moderate to slow |

---

## Terratest — Go-Based Integration Testing

**Terratest** is a Go library by Gruntwork for writing end-to-end infrastructure tests. Where `terraform test` validates outputs, Terratest lets you go deeper: make real HTTP calls to your load balancer, use the AWS SDK to verify S3 bucket policies, check that your EKS cluster is actually accepting traffic.

Use Terratest when you need to verify behavior, not just configuration.

### When to use Terratest over terraform test

- You need to make HTTP calls to verify a service is actually reachable
- You need to use the AWS SDK to inspect resource attributes not exposed as Terraform outputs
- You need complex test setup with multiple sequential Terraform modules
- Your team already writes Go

### Basic structure

```go
// test/s3_bucket_test.go

package test

import (
    "testing"

    "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestS3BucketModule(t *testing.T) {
    t.Parallel()  // ← run tests in parallel to speed things up

    awsRegion := "us-east-1"

    // Unique name to avoid conflicts between parallel test runs
    bucketName := fmt.Sprintf("terratest-s3-%s", random.UniqueId())

    // Configure the Terraform options
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/s3_bucket",  // ← path to module

        Vars: map[string]interface{}{
            "bucket_name": bucketName,
            "environment": "test",
        },
    }

    // Destroy resources when test finishes (even if it fails)
    defer terraform.Destroy(t, terraformOptions)  // ← always runs

    // Init and apply
    terraform.InitAndApply(t, terraformOptions)

    // Get the output from the Terraform apply
    bucketID := terraform.Output(t, terraformOptions, "bucket_id")
    assert.Equal(t, bucketName, bucketID)

    // Use AWS SDK to verify the bucket actually exists in AWS
    aws.AssertS3BucketExists(t, awsRegion, bucketName)

    // Verify encryption is set
    aws.AssertS3BucketServerSideEncryptionEnabled(t, awsRegion, bucketName)
}
```

### HTTP health check helpers

```go
// After deploying a load balancer, verify it actually returns HTTP 200
import "github.com/gruntwork-io/terratest/modules/http-helper"

lbDNS := terraform.Output(t, terraformOptions, "lb_dns_name")
url   := fmt.Sprintf("http://%s/health", lbDNS)

// Retry up to 10 times with 10s sleep — waits for the service to come up
http_helper.HttpGetWithRetry(
    t,
    url,
    nil,        // ← no TLS config
    200,        // ← expected status code
    "",         // ← expected body (empty = don't check)
    10,         // ← max retries
    10*time.Second,
)
```

### Test isolation: unique naming

```go
// Bad — parallel test runs collide
bucketName := "my-test-bucket"

// Good — random suffix makes each run independent
import "github.com/gruntwork-io/terratest/modules/random"
bucketName := fmt.Sprintf("my-test-bucket-%s", random.UniqueId())
// → "my-test-bucket-a4f3b2"
```

### Running Terratest

```bash
# Run all tests (applies, checks, destroys)
go test -v -timeout 30m ./test/...

# Run a specific test
go test -v -timeout 30m -run TestS3BucketModule ./test/...
```

---

## conftest / OPA — Policy-Based Plan Validation

**conftest** uses Open Policy Agent (OPA) to validate Terraform plan output against policies written in Rego. This sits between `terraform plan` and `terraform apply`: after you know what changes Terraform intends to make, you enforce rules before allowing apply.

Think of it as the compliance officer who reviews the architect's approved blueprints before construction begins — checking not just "is this valid?" but "does this comply with company policy?"

### The workflow

```bash
# 1. Generate the plan as a binary file
terraform plan -out=tfplan

# 2. Convert to JSON (human and machine readable)
terraform show -json tfplan > tfplan.json

# 3. Run conftest against the JSON
conftest test tfplan.json --policy ./policies/
```

### Example policies

```rego
# policies/require_tags.rego

package main

# Collect all resources that are missing required tags
deny[msg] {
    resource := input.resource_changes[_]
    resource.change.actions[_] != "delete"   # ← don't check deletes

    required_tags := {"Environment", "Team", "CostCenter"}
    provided_tags := {k | resource.change.after.tags[k]}

    missing := required_tags - provided_tags
    count(missing) > 0

    msg := sprintf(
        "Resource %s is missing required tags: %v",
        [resource.address, missing]
    )
}
```

```rego
# policies/no_public_s3.rego

package main

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_acl"
    resource.change.after.acl == "public-read"  # ← block any public-read ACL

    msg := sprintf(
        "S3 bucket %s must not use public-read ACL",
        [resource.address]
    )
}
```

### Running conftest in CI

```yaml
- name: conftest policy check
  run: |
    terraform plan -out=tfplan
    terraform show -json tfplan > tfplan.json
    conftest test tfplan.json \
      --policy ./policies/ \
      --namespace main      # ← OPA package name in your .rego files
```

---

## CI Pipeline Integration — The Full Stage Order

Stage order matters. Run fast, cheap checks first to fail early and save time.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CI PIPELINE STAGE ORDER                          │
│                                                                     │
│  PR Opened                                                          │
│     │                                                               │
│     ▼                                                               │
│  1. terraform validate    (syntax — zero cost, instant)             │
│     │                                                               │
│     ▼                                                               │
│  2. tflint                (correctness — no API calls)              │
│     │                                                               │
│     ▼                                                               │
│  3. checkov               (security — no API calls)                 │
│     │                                                               │
│     ▼                                                               │
│  4. terraform plan        (API calls — what will change)            │
│     │                                                               │
│     ▼                                                               │
│  5. conftest              (policy — validates plan JSON)            │
│     │                                                               │
│     ▼                                                               │
│  Human review of plan output ──► Approve PR                        │
│                                        │                           │
│                                        ▼                           │
│  6. terraform apply       (on merge to main)                        │
│     │                                                               │
│     ▼                                                               │
│  7. terraform test /      (post-apply — verify it works)           │
│     Terratest                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

### GitHub Actions workflow

```yaml
# .github/workflows/terraform-test.yml

name: Terraform Test

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

env:
  TF_VERSION: "1.7.0"

jobs:
  # ─── Stage 1-3: Static analysis (fast, parallel) ─────────────────
  static:
    name: Static Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Terraform Init
        run: terraform init -backend=false    # ← skip remote backend for validation

      - name: Terraform Validate
        run: terraform validate

      - name: tflint
        run: |
          curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
          tflint --init
          tflint --format compact

      - name: checkov
        run: |
          pip install checkov
          checkov -d . --framework terraform --quiet \
            --hard-fail-on HIGH,CRITICAL

  # ─── Stage 4-5: Plan + policy (needs AWS credentials) ────────────
  plan:
    name: Plan and Policy Check
    runs-on: ubuntu-latest
    needs: static          # ← only runs if static passes
    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.TF_ROLE_ARN }}
          aws-region: us-east-1

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Convert Plan to JSON
        run: terraform show -json tfplan > tfplan.json

      - name: conftest policy check
        run: |
          wget https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz
          tar xzf conftest_*.tar.gz
          ./conftest test tfplan.json --policy ./policies/

  # ─── Stage 6: Apply (main branch only) ───────────────────────────
  apply:
    name: Apply
    runs-on: ubuntu-latest
    needs: plan
    if: github.ref == 'refs/heads/main'    # ← only on main branch
    environment: production                # ← requires manual approval in GitHub
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.TF_ROLE_ARN }}
          aws-region: us-east-1
      - run: terraform init
      - run: terraform apply -auto-approve

  # ─── Stage 7: Post-apply integration tests ───────────────────────
  integration:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: apply
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.21"
      - name: Run Terratest
        run: go test -v -timeout 30m ./test/...
        env:
          AWS_DEFAULT_REGION: us-east-1
```

### Parallelizing tests across modules

When your repo has multiple modules, run static analysis in parallel across them:

```yaml
strategy:
  matrix:
    module: [vpc, eks, rds, s3]    # ← test all modules simultaneously
steps:
  - name: tflint
    run: tflint --chdir ./modules/${{ matrix.module }} --format compact
```

---

## Common Mistakes

| Mistake | Why it happens | Fix |
|---|---|---|
| Testing against production state | Test environment shares backend with prod | Use a separate backend (`-backend-config=test.hcl`) or `-backend=false` for static tests |
| Not cleaning up test resources | Test fails mid-run before `terraform destroy` | Always use `defer terraform.Destroy(t, opts)` in Terratest; `terraform test` cleans up automatically |
| Hardcoded credentials in tests | Developer copies access keys into test config | Use IAM roles / OIDC in CI; use `~/.aws/credentials` locally — never commit keys |
| Hardcoded resource names in tests | Parallel runs collide on the same bucket name | Always append `random.UniqueId()` to resource names in tests |
| Running integration tests on every commit | Tests that create real resources are expensive | Gate integration tests on PR merge or schedule them nightly |
| No test for destroy | Module applies fine, destroy breaks everything | Include a destroy-and-re-apply cycle in Terratest |
| Ignoring checkov findings with blanket skips | `--skip-check` silences all rules | Use inline `#checkov:skip` per resource with a reason, not global suppression |

---

## Navigation

Back to [04_Terraform README](../README.md)

Previous: [ci_cd_integration.md](./ci_cd_integration.md)

Related: [security.md](./security.md) | [code_organization.md](./code_organization.md) | [ci_cd_integration.md](./ci_cd_integration.md)
