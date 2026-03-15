# Stage 09b — AWS CDK & Terraform: Modern Infrastructure as Code

> Define cloud infrastructure in real programming languages, not just YAML. Loops, functions, abstractions — real code for real infrastructure.

---

## 1. The IaC Evolution

```
Level 1 — ClickOps:        Click in AWS Console
           Problem: Not reproducible, no audit trail, drift between envs

Level 2 — CloudFormation:  YAML/JSON templates
           Problem: Verbose, no real programming constructs, hard to reuse

Level 3 — CDK / Terraform: Real code (Python, TypeScript, Go, etc.)
           ✅ Loops, conditions, functions, classes
           ✅ IDE autocomplete, type checking
           ✅ Unit testing for infrastructure
           ✅ Reusable constructs/modules
```

---

## 2. AWS CDK — Cloud Development Kit

### Core Intuition

CDK lets you define AWS infrastructure in TypeScript, Python, Java, Go, or C#. It compiles down to CloudFormation templates. Best of both worlds: real programming + CloudFormation's reliability.

```
You write:   Python/TypeScript class
CDK compiles: CloudFormation template (YAML)
CloudFormation: provisions AWS resources

CDK = High-level language → CloudFormation → AWS
```

---

## 3. CDK Python Example

```python
# app.py — CDK app entry point
import aws_cdk as cdk
from stacks.api_stack import ApiStack
from stacks.database_stack import DatabaseStack

app = cdk.App()

# Deploy to two environments
DatabaseStack(app, "DatabaseStack-Dev",
    env=cdk.Environment(account="123456789", region="us-east-1"),
    stage="dev"
)
ApiStack(app, "ApiStack-Dev",
    env=cdk.Environment(account="123456789", region="us-east-1"),
    stage="dev"
)

app.synth()
```

```python
# stacks/api_stack.py
from aws_cdk import (
    Stack, Duration, RemovalPolicy,
    aws_lambda as lambda_,
    aws_apigateway as apigw,
    aws_dynamodb as ddb,
    aws_iam as iam,
)
from constructs import Construct

class ApiStack(Stack):

    def __init__(self, scope: Construct, id: str, stage: str, **kwargs):
        super().__init__(scope, id, **kwargs)

        # DynamoDB table
        table = ddb.Table(
            self, "OrdersTable",
            table_name=f"orders-{stage}",
            partition_key=ddb.Attribute(name="orderId", type=ddb.AttributeType.STRING),
            billing_mode=ddb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY if stage == "dev" else RemovalPolicy.RETAIN
        )

        # Lambda function — iterate over all handlers
        handlers = {
            "get-orders": "handlers/get_orders.py",
            "create-order": "handlers/create_order.py",
            "delete-order": "handlers/delete_order.py",
        }

        lambdas = {}
        for name, _ in handlers.items():
            fn = lambda_.Function(
                self, f"Function-{name}",
                runtime=lambda_.Runtime.PYTHON_3_12,
                code=lambda_.Code.from_asset("lambda"),
                handler=f"{name.replace('-', '_')}.handler",
                environment={
                    "TABLE_NAME": table.table_name,
                    "STAGE": stage,
                },
                timeout=Duration.seconds(30),
                memory_size=256,
            )
            table.grant_read_write_data(fn)  # least-privilege IAM!
            lambdas[name] = fn

        # API Gateway REST API
        api = apigw.RestApi(
            self, "OrdersApi",
            rest_api_name=f"orders-api-{stage}",
            default_cors_preflight_options=apigw.CorsOptions(
                allow_origins=apigw.Cors.ALL_ORIGINS,
                allow_methods=["GET", "POST", "DELETE"],
            )
        )

        # Add routes
        orders = api.root.add_resource("orders")
        orders.add_method("GET",  apigw.LambdaIntegration(lambdas["get-orders"]))
        orders.add_method("POST", apigw.LambdaIntegration(lambdas["create-order"]))

        order = orders.add_resource("{orderId}")
        order.add_method("DELETE", apigw.LambdaIntegration(lambdas["delete-order"]))
```

---

## 4. CDK Constructs — The Library System

```
CDK has 3 levels of constructs:

L1 — CloudFormation Resources (Cfn prefix):
  Direct mapping to CloudFormation
  All properties available but verbose
  Example: aws_ec2.CfnSecurityGroup(...)

L2 — AWS Constructs (recommended):
  Sensible defaults + helper methods
  Type-safe, IDE-complete
  Example: aws_ec2.SecurityGroup(...) — auto-creates common rules

L3 — Patterns:
  Complete solutions (opinionated, composable)
  Example: aws_ecs_patterns.ApplicationLoadBalancedFargateService(...)
  Creates: ECS cluster + Task Def + ALB + Route53 record — one construct!

Best practice: use L2/L3. Drop to L1 only for missing features.
```

```python
# L3 example: deploy a full Fargate service behind ALB in ~10 lines
from aws_cdk import aws_ecs_patterns as ecs_patterns, aws_ecs as ecs

# This creates: VPC, ECS Cluster, Task Def, Fargate Service, ALB, Target Group
service = ecs_patterns.ApplicationLoadBalancedFargateService(
    self, "MyWebService",
    cluster=ecs.Cluster(self, "Cluster", vpc=vpc),
    task_image_options=ecs_patterns.ApplicationLoadBalancedTaskImageOptions(
        image=ecs.ContainerImage.from_ecr_repository(repo, "latest"),
        container_port=8080,
    ),
    desired_count=3,
    public_load_balancer=True,
    memory_limit_mib=512,
    cpu=256,
)
service.scale_task_count(max_capacity=10).scale_on_cpu_utilization(
    "CpuScaling", target_utilization_percent=70
)
```

---

## 5. CDK CLI Commands

```bash
# Install CDK
npm install -g aws-cdk

# Create new CDK project
mkdir my-infra && cd my-infra
cdk init app --language python
source .venv/bin/activate
pip install -r requirements.txt

# Bootstrap (one-time per account/region — creates CDK toolkit stack)
cdk bootstrap aws://123456789/us-east-1

# See what CloudFormation will be generated
cdk synth

# See what will change (like terraform plan)
cdk diff

# Deploy all stacks
cdk deploy --all

# Deploy specific stack
cdk deploy ApiStack-Dev

# Destroy infrastructure
cdk destroy ApiStack-Dev
```

---

## 6. Terraform — Multi-Cloud IaC

### Core Intuition

Terraform uses its own language (HCL — HashiCorp Configuration Language) to define infrastructure across ANY cloud provider. One tool for AWS, Azure, GCP, Kubernetes, and more.

```
CDK:       AWS-only, real programming language
Terraform: Multi-cloud, HCL language, larger ecosystem

Use CDK when:   AWS-only shop, TypeScript/Python team
Use Terraform:  Multi-cloud, need community modules, existing Terraform team
```

---

## 7. Terraform HCL Example

```hcl
# main.tf — Deploy Lambda + API Gateway + DynamoDB

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Remote state in S3
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "api/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"  # state locking
    encrypt        = true
  }
}

variable "stage" {
  type    = string
  default = "dev"
}

# DynamoDB Table
resource "aws_dynamodb_table" "orders" {
  name         = "orders-${var.stage}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "orderId"

  attribute {
    name = "orderId"
    type = "S"
  }

  tags = {
    Environment = var.stage
    Project     = "my-api"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-${var.stage}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query"]
      Resource = aws_dynamodb_table.orders.arn
    }]
  })
}

# Lambda Function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "api" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "orders-api-${var.stage}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.orders.name
      STAGE      = var.stage
    }
  }
}

output "lambda_arn" {
  value = aws_lambda_function.api.arn
}
```

---

## 8. Terraform CLI Commands

```bash
# Initialize (download providers, set up backend)
terraform init

# Preview changes (ALWAYS do this before apply)
terraform plan

# Apply changes
terraform apply

# Apply without confirmation prompt (CI/CD)
terraform apply -auto-approve

# Destroy infrastructure
terraform destroy

# Target specific resource
terraform apply -target=aws_dynamodb_table.orders

# Import existing resource into state
terraform import aws_s3_bucket.existing my-existing-bucket

# View current state
terraform show
terraform state list

# Format code
terraform fmt

# Validate syntax
terraform validate
```

---

## 9. CDK vs Terraform vs CloudFormation

```
                CloudFormation      CDK                 Terraform
Language:       YAML/JSON           Python/TS/Java/Go   HCL
Multi-cloud:    No                  No                  Yes
State backend:  AWS-managed         AWS-managed         S3 (you manage)
Testing:        Limited             Unit tests (pytest) terratest
Learning curve: Medium              Low (if Python/TS)  Medium
Ecosystem:      AWS-native          AWS-native          Huge (modules)
Drift detection:✅ built-in         ✅ (uses CFN)       Manual / Driftctl
Cost estimate:  No                  No                  Infracost (3rd party)

Choose CDK when:
  ✅ AWS-only
  ✅ Python/TypeScript team
  ✅ Want IDE support + type safety
  ✅ Want to write unit tests for infra

Choose Terraform when:
  ✅ Multi-cloud
  ✅ Existing Terraform expertise
  ✅ Need large module ecosystem
  ✅ Fine with HCL syntax
```

---

## 10. Interview Perspective

**Q: What is the difference between CDK and CloudFormation?**
CloudFormation uses YAML/JSON templates — static, verbose, no real programming constructs. CDK generates CloudFormation templates from real code (Python, TypeScript). CDK adds: loops to create similar resources, conditionals, functions to encapsulate patterns, unit testing with pytest, IDE autocomplete. Both compile to the same CloudFormation in the end, so CDK gets all of CloudFormation's deployment reliability.

**Q: How does Terraform manage state, and why does it matter?**
Terraform stores the current state of deployed infrastructure in a state file. It uses this to calculate what changes to make (`terraform plan` = desired state minus current state). In teams, you must use remote state (S3 + DynamoDB for locking) so everyone sees the same state and two people can't run `terraform apply` simultaneously. Without remote state, two people applying simultaneously can corrupt infrastructure.

**Q: What is `cdk diff` equivalent to in Terraform?**
Both `cdk diff` and `terraform plan` show what will change before you deploy — what resources will be created, modified, or deleted. This is critical for production deployments: always run diff/plan, review the output, then deploy. CDK diff integrates with CloudFormation change sets; Terraform plan compares desired state to state file.

**Back to root** → [../README.md](../README.md)
