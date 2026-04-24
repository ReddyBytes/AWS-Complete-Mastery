# Terraform — Topic Recap

> One-line summary of every module. Use this to quickly find which module covers the concept you need.

---

## 01 · Introduction — `01_introduction/`

| File | Covers |
|------|--------|
| `what_is_terraform.md` | Infrastructure as Code explained: the problem with ClickOps, how Terraform reads HCL and provisions cloud resources, the core workflow (write → plan → apply), and why IaC makes infrastructure reproducible and version-controlled |
| `terraform_vs_others.md` | Comparison of IaC tools: Terraform (cloud-agnostic provisioning) vs Ansible (configuration management) vs CloudFormation (AWS-native) vs Pulumi (general programming languages) vs CDK — when to choose each |
| `installation.md` | Installing Terraform CLI, setting up AWS credentials, configuring the `terraform` binary, and verifying your environment is ready with a first `terraform version` |

---

## 02 · HCL Basics — `02_hcl_basics/`

| File | Covers |
|------|--------|
| `syntax.md` | HCL grammar fundamentals: blocks (type, labels, body), arguments, expressions, comments, and how Terraform parses `.tf` files — the building blocks everything else is written in |
| `data_types.md` | The seven core data types — string, number, bool (primitives), list, set, map, object (complex) — with how to declare, access, and transform them in HCL |
| `expressions.md` | Making configuration dynamic: string interpolation `${}`, conditional expressions (`condition ? true : false`), `for` expressions, splat expressions, `count` and `for_each` meta-arguments, and `dynamic` blocks |

---

## 03 · Providers & Resources — `03_providers_resources/`

| File | Covers |
|------|--------|
| `providers.md` | What providers are (API translator plugins), the `terraform { required_providers }` block, provider configuration (region, credentials), version constraints, and the Terraform Registry — plus multi-provider and multi-region patterns |
| `resources.md` | The resource block anatomy (`resource "type" "name" {}`), resource arguments and attributes, resource references (`aws_instance.web.id`), meta-arguments (`depends_on`, `lifecycle`, `count`, `for_each`), and how Terraform builds the dependency graph |
| `data_sources.md` | Read-only lookups of existing infrastructure: `data "aws_ami" "latest" {}` pattern, referencing data source outputs, common use cases (latest AMI, existing VPC, SSM Parameter Store values) |

---

## 04 · Variables & Outputs — `04_variables_outputs/`

| File | Covers |
|------|--------|
| `variables.md` | Input variables: the `variable` block (type, description, default, validation), how to pass values (CLI flags, `.tfvars` files, environment variables `TF_VAR_*`), and sensitive variables |
| `outputs.md` | Output values: the `output` block, exposing resource attributes after `apply`, `sensitive` outputs, using outputs as inter-module communication, and querying outputs with `terraform output` |
| `locals.md` | Local values (`locals {}`): computed expressions defined once and reused throughout a module — common patterns for naming conventions (`name_prefix`), merged tag maps, and avoiding repetition |

---

## 05 · State Management — `05_state_management/`

| File | Covers |
|------|--------|
| `state_file.md` | What `terraform.tfstate` is (Terraform's ledger of real-world resources), its JSON structure, how Terraform uses it to compute diffs, why you must never edit it by hand, and the risks of losing or corrupting state |
| `remote_state.md` | Moving state to a shared S3 backend with DynamoDB locking: the `backend "s3" {}` block, state encryption at rest, enabling state locking to prevent concurrent applies, and cross-team collaboration patterns |
| `state_commands.md` | Surgical state operations: `terraform state list`, `state show`, `state mv` (rename after refactoring), `state rm` (remove without destroying), and `terraform import` (bring existing AWS resources under Terraform management) |

---

## 06 · Modules — `06_modules/`

| File | Covers |
|------|--------|
| `creating_modules.md` | Writing reusable modules: root module vs child module, the standard file structure (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`), calling a child module with `module {}` blocks, and passing variables/receiving outputs |
| `module_registry.md` | The Terraform Registry (registry.terraform.io): using community modules with `source = "terraform-aws-modules/vpc/aws"`, version pinning, reading module inputs and outputs, and when to use pre-built vs custom modules |
| `module_composition.md` | Wiring modules together: root module orchestration, passing outputs from one module as inputs to another (`module.networking.vpc_id`), avoiding circular dependencies, and layered architecture patterns (networking → compute → database) |

---

## 07 · Workspaces — `07_workspaces/`

| File | Covers |
|------|--------|
| `workspaces.md` | Terraform workspaces: one codebase, isolated state per environment — `terraform workspace new dev`, `terraform workspace select prod`, the `terraform.workspace` variable for environment-specific logic, and limitations |
| `environments.md` | Three environment management strategies: workspaces (simple, same account), directory-per-environment (more isolation, some duplication), and separate repos per environment (maximum isolation, highest overhead) — trade-offs and when to use each |

---

## 08 · AWS with Terraform — `08_aws_with_terraform/`

| File | Covers |
|------|--------|
| `vpc.md` | End-to-end VPC in Terraform: `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_nat_gateway`, `aws_route_table` + associations, and the complete public/private subnet pattern across multiple AZs |
| `ec2.md` | Launching EC2 instances: `aws_instance`, data source for latest AMI, `aws_security_group` with ingress/egress rules, `aws_key_pair`, IAM instance profile attachment, and user_data for bootstrapping |
| `rds.md` | Provisioning RDS with Terraform: `aws_db_instance`, subnet groups, parameter groups, security group scoping, Multi-AZ, automated backups, and storing the password via `aws_secretsmanager_secret` |
| `s3.md` | S3 bucket management: `aws_s3_bucket`, versioning, server-side encryption, lifecycle rules, bucket policies, public access block, and static website hosting configuration |
| `iam.md` | IAM in Terraform: `aws_iam_role`, assume role policy documents with `data "aws_iam_policy_document"`, `aws_iam_policy`, role–policy attachment, and least-privilege patterns for EC2 instance profiles and Lambda execution roles |

---

## 09 · Best Practices — `09_best_practices/`

| File | Covers |
|------|--------|
| `code_organization.md` | Standard Terraform file structure (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `providers.tf`), naming conventions, splitting large configs into separate modules, README documentation, and tagging strategy |
| `security.md` | Never hardcode credentials; use environment variables or OIDC for CI/CD; store secrets in AWS Secrets Manager or SSM; encrypt state at rest; use `sensitive = true` on outputs; run `tfsec` or Checkov for static analysis |
| `ci_cd_integration.md` | Automating Terraform in pipelines: PR-triggered `plan` for review, protected `apply` on merge to main, OIDC-based authentication to AWS (no long-lived keys), `terraform fmt` and `validate` as pre-checks, and Atlantis vs GitHub Actions patterns |

---

## 99 · Interview Master — `99_interview_master/terraform_questions.md`
Beginner-to-advanced interview questions: IaC fundamentals, plan vs apply vs destroy, state management, module design, handling state drift, import vs refactoring, workspace vs directory strategies, remote state, and common production mistakes (state corruption, provider version pinning, resource replacement triggers).

---

*Total modules: 9 + interview · Last updated: 2026-04-21*
