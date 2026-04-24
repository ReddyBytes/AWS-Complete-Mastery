# Terraform Practice Questions — 100 Questions from Basics to Mastery

> Test yourself across the full Terraform curriculum. Answers hidden until clicked.

---

## How to Use This File

1. **Read the question** — attempt your answer before opening the hint
2. **Use the framework** — run through the 5-step thinking process first
3. **Check your answer** — click "Show Answer" only after you've tried

---

## How to Think: 5-Step Framework

1. **Restate** — what is this question actually asking?
2. **Identify the concept** — which Terraform feature/concept is being tested?
3. **Recall the rule** — what is the exact behaviour or rule?
4. **Apply to the case** — trace through the scenario step by step
5. **Sanity check** — does the result make sense? What edge cases exist?

---

## Progress Tracker

- [ ] **Tier 1 — Basics** (Q1–Q33): Fundamentals and core commands
- [ ] **Tier 2 — Intermediate** (Q34–Q66): Advanced features and real patterns
- [ ] **Tier 3 — Advanced** (Q67–Q75): Deep internals and edge cases
- [ ] **Tier 4 — Interview / Scenario** (Q76–Q90): Explain-it, compare-it, real-world problems
- [ ] **Tier 5 — Critical Thinking** (Q91–Q100): Predict output, debug, design decisions

---

## Question Type Legend

| Tag | Meaning |
|---|---|
| `[Normal]` | Recall + apply — straightforward concept check |
| `[Thinking]` | Requires reasoning about internals |
| `[Logical]` | Predict output or trace execution |
| `[Critical]` | Tricky gotcha or edge case |
| `[Interview]` | Explain or compare in interview style |
| `[Debug]` | Find and fix the broken code/config |
| `[Design]` | Architecture or approach decision |

---

## 🟢 Tier 1 — Basics

---

### Q1 · [Normal] · `what-is-terraform`

> **What is Terraform? What problem does it solve compared to manually configuring infrastructure?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Terraform is an open-source Infrastructure as Code (IaC) tool by HashiCorp that lets you define, provision, and manage cloud infrastructure using declarative configuration files.

**How to think through this:**
1. "ClickOps" (manually clicking through AWS console) is slow, error-prone, and impossible to reproduce exactly
2. Terraform replaces that with code — you describe the desired end state, and Terraform figures out how to get there
3. The config files can be version-controlled, reviewed, and shared — treating infrastructure like software

**Key takeaway:** Terraform turns infrastructure into repeatable, reviewable code instead of undocumented manual steps.

</details>

📖 **Theory:** [what-is-terraform](./01_introduction/what_is_terraform.md#what-is-terraform--infrastructure-as-code-explained)


---

### Q2 · [Thinking] · `terraform-vs-others`

> **How does Terraform compare to AWS CloudFormation, Ansible, and Pulumi? When would you choose Terraform?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- **CloudFormation**: AWS-only, YAML/JSON, tightly integrated with AWS but no multi-cloud support
- **Ansible**: Procedural, agentless config management — great for software configuration, not infrastructure provisioning
- **Pulumi**: Like Terraform but uses general-purpose languages (Python, TypeScript) instead of HCL
- **Terraform**: Declarative, multi-cloud, large provider ecosystem, industry standard for provisioning

**How to think through this:**
1. If you're 100% AWS and want deep native integration → CloudFormation
2. If you need to configure servers (install packages, manage files) → Ansible
3. If your team prefers Python/TypeScript over HCL → Pulumi
4. If you need multi-cloud, a massive provider ecosystem, and the broadest industry adoption → Terraform

**Key takeaway:** Choose Terraform when you need multi-cloud provisioning, a large ecosystem, and a declarative workflow that any DevOps engineer will recognize.

</details>

📖 **Theory:** [terraform-vs-others](./01_introduction/terraform_vs_others.md#terraform-vs-other-iac-tools--choosing-the-right-wrench)


---

### Q3 · [Normal] · `iac-benefits`

> **What are the 4 main benefits of Infrastructure as Code (IaC)? Why is IaC superior to "ClickOps"?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
1. **Reproducibility** — the same config creates identical environments every time
2. **Version control** — infrastructure changes are tracked in Git with history, diffs, and rollback
3. **Automation** — no manual steps; CI/CD pipelines can apply changes without human intervention
4. **Documentation** — the code itself documents exactly what infrastructure exists and how it's configured

**How to think through this:**
1. ClickOps relies on human memory and screenshots — impossible to reproduce at scale or audit reliably
2. IaC encodes intent: "I want a VPC with these CIDRs" is readable and reviewable
3. Drift is detectable — Terraform plan will show if someone manually changed something outside the code
4. Onboarding new engineers is faster when the full environment is codified

**Key takeaway:** IaC makes infrastructure as manageable and auditable as application code, eliminating the fragile snowflake server problem.

</details>

📖 **Theory:** [iac-benefits](./01_introduction/what_is_terraform.md#what-is-infrastructure-as-code-iac)


---

### Q4 · [Normal] · `terraform-workflow`

> **What are the 5 main Terraform commands in a typical workflow? What does each do?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
1. `terraform init` — downloads providers and modules, initializes the backend
2. `terraform plan` — shows a preview of what changes will be made (no changes applied)
3. `terraform apply` — executes the plan, creating/modifying/destroying real infrastructure
4. `terraform destroy` — tears down all infrastructure managed by the current state
5. `terraform fmt` / `terraform validate` — formats and validates config files (often added to the workflow)

**How to think through this:**
1. You always start with `init` — without it, providers aren't downloaded and nothing works
2. `plan` is your safety net — always review it before applying
3. `apply` is the action step — it compares desired state (code) to current state (state file) and reconciles
4. `destroy` is the nuclear option — removes everything tracked in state
5. `fmt` and `validate` are hygiene steps, often run in CI before plan

**Key takeaway:** The core loop is init → plan → apply, with destroy reserved for teardown and fmt/validate for code quality.

</details>

📖 **Theory:** [terraform-workflow](./01_introduction/installation.md#installing-terraform--getting-your-workstation-ready)


---

### Q5 · [Normal] · `hcl-basics`

> **What does HCL stand for? What are the 3 main block types in a Terraform configuration file?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
HCL stands for **HashiCorp Configuration Language**. The 3 main block types are:
1. `resource` — declares infrastructure to create and manage
2. `variable` — declares input parameters
3. `output` — declares values to export after apply

Other important block types include `provider`, `data`, `locals`, `module`, and `terraform`.

**How to think through this:**
1. HCL is designed to be human-readable and declarative — you describe what you want, not how to do it
2. `resource` blocks are the core — they map to real infrastructure objects (EC2 instance, S3 bucket, etc.)
3. `variable` and `output` blocks are the "API" of your Terraform module — inputs in, results out

**Key takeaway:** Every Terraform file is composed of typed blocks — resource, variable, and output cover 90% of what you'll write day to day.

</details>

📖 **Theory:** [hcl-basics](./02_hcl_basics/syntax.md#hcl-syntax--learning-the-language-of-terraform)


---

### Q6 · [Normal] · `resource-block`

> **Write a minimal Terraform resource block that creates an S3 bucket named "my-bucket" in AWS.**

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The block above is the minimal valid resource declaration. `"aws_s3_bucket"` is the resource type (from the AWS provider), `"example"` is the local name used to reference it elsewhere in the config.

**How to think through this:**
1. Resource blocks always follow the pattern: `resource "<type>" "<local_name>" { ... }`
2. The type (`aws_s3_bucket`) maps to a real API call in the provider
3. Arguments inside the block (like `bucket`) are resource-specific — check the provider docs for required vs optional
4. The local name (`example`) is only meaningful inside Terraform — it's how you reference this resource as `aws_s3_bucket.example`

**Key takeaway:** Resource block = resource type + local name + arguments; the type+name pair must be unique within a configuration.

</details>

📖 **Theory:** [resource-block](./03_providers_resources/resources.md#the-resource-block-anatomy)


---

### Q7 · [Normal] · `provider-block`

> **What is a Terraform provider? Write a minimal `provider "aws"` block. Where does Terraform download providers from?**

```hcl
provider "aws" {
  region = "us-east-1"
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A provider is a plugin that knows how to talk to a specific API (AWS, GCP, Azure, GitHub, etc.). It translates Terraform resource declarations into API calls.

Terraform downloads providers from the **Terraform Registry** (`registry.terraform.io`) during `terraform init`.

**How to think through this:**
1. Without a provider, Terraform has no idea what `aws_s3_bucket` means — providers supply the vocabulary
2. The `provider` block configures the provider (region, credentials, endpoints)
3. Credentials are typically passed via environment variables (`AWS_ACCESS_KEY_ID`) or IAM roles, not hardcoded in the block
4. Provider versions should be pinned in the `required_providers` block to prevent unexpected upgrades

**Key takeaway:** Providers are the bridge between Terraform's HCL and a platform's API — each resource type belongs to exactly one provider.

</details>

📖 **Theory:** [provider-block](./03_providers_resources/providers.md#terraform-providers--plugins-that-talk-to-the-world)


---

### Q8 · [Normal] · `variables-input`

> **What is an input variable in Terraform? Write a variable declaration for a required string called `environment`.**

```hcl
variable "environment" {
  type        = string
  description = "The deployment environment (e.g. dev, staging, prod)"
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
An input variable is a parameter that makes your Terraform configuration reusable. No `default` value means the variable is required — Terraform will error if it's not provided.

**How to think through this:**
1. Variables let you write one configuration that works for `dev`, `staging`, and `prod` by changing inputs
2. Without a `default`, the user must supply the value via CLI flag, env var, or `.tfvars` file
3. The `type` constraint catches type errors early — passing a number where a string is expected fails at plan time
4. Reference the variable elsewhere with `var.environment`

**Key takeaway:** Input variables are the parameters of your infrastructure module — always declare type and description for clarity.

</details>

📖 **Theory:** [variables-input](./04_variables_outputs/variables.md#terraform-variables--making-your-code-reusable)


---

### Q9 · [Normal] · `variable-types`

> **What are the Terraform variable types: string, number, bool, list, map, set, object, tuple? Give an example of a map variable.**

```hcl
variable "tags" {
  type = map(string)
  default = {
    owner       = "platform-team"
    environment = "dev"
  }
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `string` — text: `"us-east-1"`
- `number` — integer or float: `3`, `1.5`
- `bool` — `true` or `false`
- `list(type)` — ordered collection: `["a", "b", "c"]`
- `map(type)` — key-value pairs: `{ key = "value" }`
- `set(type)` — unordered unique values
- `object({ ... })` — structured type with named attributes
- `tuple([type, ...])` — fixed-length list with mixed types

**How to think through this:**
1. Primitive types (string, number, bool) are the building blocks
2. Collection types (list, map, set) hold multiple values of the same type
3. Structural types (object, tuple) hold mixed types — useful for complex variable shapes
4. `map(string)` is the most common map pattern, used heavily for AWS resource tags

**Key takeaway:** Use `map(string)` for tags and key-value config; use `object` when you need a variable with multiple named fields of different types.

</details>

📖 **Theory:** [variable-types](./04_variables_outputs/variables.md#variable-types)


---

### Q10 · [Thinking] · `variable-precedence`

> **List the Terraform variable precedence order from highest to lowest (CLI flags, environment variables, .tfvars files, defaults).**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
From highest to lowest precedence:
1. `-var` and `-var-file` flags on the CLI (highest)
2. `*.auto.tfvars` and `*.auto.tfvars.json` files (loaded automatically)
3. `terraform.tfvars.json`
4. `terraform.tfvars`
5. Environment variables (`TF_VAR_<name>`)
6. Default values in the `variable` block (lowest)

**How to think through this:**
1. CLI flags always win — useful for one-off overrides in CI/CD pipelines
2. `.auto.tfvars` files are convenient for per-environment configs because they load automatically
3. `terraform.tfvars` is the conventional "local override" file — often gitignored for secrets
4. Environment variables (prefixed `TF_VAR_`) are the standard way to inject secrets in CI
5. Defaults are the fallback of last resort

**Key takeaway:** CLI `-var` flags override everything; `TF_VAR_` env vars are the standard for secrets in automated pipelines; defaults are just starting points.

</details>

📖 **Theory:** [variable-precedence](./04_variables_outputs/variables.md#terraform-variables--making-your-code-reusable)


---

### Q11 · [Normal] · `outputs`

> **What are Terraform outputs? Write an output that exports the public IP of an EC2 instance. When would you use them?**

```hcl
output "instance_public_ip" {
  description = "The public IP of the web server"
  value       = aws_instance.web.public_ip
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Outputs expose values from your Terraform configuration after apply. They appear in the terminal after `terraform apply` and can be read by other modules or scripts.

Use cases:
- Passing values between modules (a root module consuming a child module's output)
- Displaying useful info after apply (e.g., load balancer DNS, database endpoint)
- Reading values in scripts via `terraform output -json`

**How to think through this:**
1. Without outputs, resource attributes are internal — you can't easily retrieve them after apply
2. In modular Terraform, outputs are the "return values" of a module
3. `terraform output instance_public_ip` reads a specific output from the command line
4. Sensitive outputs can be marked `sensitive = true` to prevent them showing in logs

**Key takeaway:** Outputs are the public API of a Terraform module — use them to expose results to callers and make post-apply automation possible.

</details>

📖 **Theory:** [outputs](./04_variables_outputs/outputs.md#terraform-outputs--exposing-useful-values)


---

### Q12 · [Normal] · `locals`

> **What are `locals` in Terraform? How do they differ from variables? Write an example that builds a resource name from environment + project.**

```hcl
locals {
  resource_name = "${var.environment}-${var.project}-server"
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Locals are computed values defined within the configuration. Unlike variables, they cannot be overridden from outside — they are internal constants or derived expressions.

Key differences from variables:
- Variables are inputs (set by the caller); locals are internal (set by the author)
- Locals can reference other locals, variables, and resource attributes
- Locals have no type constraint — they hold any expression result

**How to think through this:**
1. Use locals to avoid repeating the same expression multiple times
2. Use locals to give a complex expression a readable name
3. Use variables when the value needs to change between environments or callers
4. Reference a local with `local.resource_name` (no `s`, singular)

**Key takeaway:** Locals are for DRY — if you're writing the same expression in three places, move it to a local.

</details>

📖 **Theory:** [locals](./04_variables_outputs/locals.md#terraform-locals--eliminating-repetition-in-your-code)


---

### Q13 · [Normal] · `data-sources`

> **What is a Terraform data source? Write a `data` block that looks up the latest Amazon Linux 2 AMI.**

```hcl
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A data source reads existing infrastructure or external data without managing it. It's read-only — Terraform queries the API and makes the result available in your config, but never creates or destroys the thing it reads.

Reference the result with: `data.aws_ami.amazon_linux_2.id`

**How to think through this:**
1. `resource` = create and manage; `data` = read and reference
2. Common use case: look up an AMI ID, VPC ID, or secret ARN that already exists
3. Data sources are re-evaluated on every `plan` and `apply` — they always reflect current reality
4. Without data sources, you'd hardcode AMI IDs that become stale as AWS releases new images

**Key takeaway:** Data sources are the "read" side of Terraform — use them to avoid hardcoding IDs for things that already exist outside your config.

</details>

📖 **Theory:** [data-sources](./03_providers_resources/data_sources.md#data-sources--reading-existing-infrastructure)


---

### Q14 · [Thinking] · `resource-dependencies`

> **How does Terraform determine the order to create resources? What is an implicit dependency vs `depends_on`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Terraform builds a **dependency graph** from resource references. Resources are created in the correct order automatically.

- **Implicit dependency**: created automatically when one resource references another's attribute (e.g., `subnet_id = aws_subnet.main.id`). Terraform sees the reference and knows to create the subnet first.
- **Explicit dependency** (`depends_on`): used when there is a real dependency that isn't expressed through attribute references — for example, an IAM policy must be attached before a Lambda function runs, but the Lambda config doesn't reference the policy directly.

**How to think through this:**
1. Terraform's graph engine resolves the order — you don't write `step 1, step 2, step 3`
2. Implicit dependencies are always preferred — they're self-documenting
3. `depends_on` is a last resort for non-obvious dependencies (often involving IAM propagation)
4. Overusing `depends_on` creates unnecessary serialization and slower applies

**Key takeaway:** Let Terraform infer order through attribute references whenever possible; only reach for `depends_on` when the dependency is real but invisible in the config.

</details>

📖 **Theory:** [resource-dependencies](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q15 · [Normal] · `terraform-state`

> **What is Terraform state? What is stored in `terraform.tfstate`? Why should you never edit it manually?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Terraform state is a JSON file that maps your configuration resources to real-world infrastructure objects. It's the source of truth Terraform uses to compute diffs.

What's stored in `terraform.tfstate`:
- Resource IDs and all attribute values as last seen
- Metadata (provider versions, dependency information)
- Outputs

Why not to edit manually:
- JSON is fragile — a typo corrupts the entire file
- Editing breaks the mapping between config and real resources, causing Terraform to try to recreate or destroy things incorrectly
- Use `terraform state mv`, `terraform state rm`, or `terraform import` for legitimate state manipulation

**How to think through this:**
1. Think of state as Terraform's memory — without it, every plan looks like "create everything from scratch"
2. State lets Terraform know "this `aws_s3_bucket.example` is the real bucket with ID `my-bucket-abc123`"
3. Manual edits can cause a mismatch where Terraform thinks a resource doesn't exist and tries to create a duplicate

**Key takeaway:** State is Terraform's single source of truth — treat it as sacred and use Terraform CLI commands to manipulate it, never a text editor.

</details>

📖 **Theory:** [terraform-state](./05_state_management/state_file.md#the-terraform-state-file--terraforms-memory)


---

### Q16 · [Thinking] · `state-file-contents`

> **What is stored in the state file? Why does Terraform need state to plan changes?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The state file stores:
- **Resource instances**: each resource's type, name, provider, and all attribute values at last apply
- **Dependencies**: the graph edges between resources
- **Outputs**: all output values
- **Terraform version and provider schema info**

Why Terraform needs state to plan:
1. Terraform is **declarative** — it computes the diff between desired state (your `.tf` files) and current state (the state file)
2. Without state, Terraform would have to query every API endpoint to discover what exists — slow and often impossible (some attributes aren't readable after creation)
3. State also stores computed attributes (like auto-generated IDs) that aren't in your config

**How to think through this:**
1. Your config says "I want an EC2 instance with type t3.micro"
2. The state says "the current instance is t3.small with ID i-abc123"
3. The plan says "change instance type from t3.small to t3.micro"
4. Without step 2, Terraform can't produce step 3

**Key takeaway:** State enables incremental changes — it's the "before" snapshot that makes `terraform plan` meaningful.

</details>

📖 **Theory:** [state-file-contents](./05_state_management/state_file.md#the-terraform-state-file--terraforms-memory)


---

### Q17 · [Debug] · `terraform-plan`

> **What does `terraform plan` output? What do the `+`, `-`, `~`, and `-/+` symbols mean in a plan?**

```
# aws_instance.web will be updated in-place
~ resource "aws_instance" "web" {
    id            = "i-0abc123"
  ~ instance_type = "t3.small" -> "t3.micro"
}

# aws_s3_bucket.logs must be replaced
-/+ resource "aws_s3_bucket" "logs" {
  ~ bucket = "old-name" -> "new-name" # forces replacement
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `+` — resource will be **created**
- `-` — resource will be **destroyed**
- `~` — resource will be **updated in-place** (no recreation needed)
- `-/+` — resource will be **destroyed and recreated** (a change to an immutable attribute forces replacement)

**How to think through this:**
1. `+` and `-` are straightforward create/delete
2. `~` is the happy path for changes — the existing resource is modified via API without downtime
3. `-/+` is the dangerous one — Terraform must destroy the old resource and create a new one, which can cause downtime (e.g., changing an EC2 instance's availability zone)
4. Always scan for `-/+` in a plan before approving — it's where accidents happen

**Key takeaway:** `-/+` in a plan means the resource will be destroyed and recreated — always scrutinize these lines before running apply.

</details>

📖 **Theory:** [terraform-plan](./01_introduction/installation.md#installing-terraform--getting-your-workstation-ready)


---

### Q18 · [Normal] · `terraform-apply`

> **What happens during `terraform apply`? What is the difference between `-auto-approve` and interactive approval?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
During `terraform apply`:
1. Terraform re-runs the plan to get the current diff
2. Displays the plan output
3. Waits for approval (unless `-auto-approve` is set)
4. Executes API calls to create/modify/destroy resources in dependency order
5. Updates the state file as each resource operation completes

`-auto-approve` skips the interactive "yes/no" prompt — used in CI/CD pipelines where human approval happens upstream (e.g., in a PR review or pipeline gate).

**How to think through this:**
1. Interactive approval is a safety net for human operators who might catch a dangerous change
2. `-auto-approve` is appropriate in automated pipelines where the plan has already been reviewed and approved
3. Never use `-auto-approve` interactively for production changes unless you're very confident
4. State is updated incrementally — if apply fails halfway, the state reflects what succeeded

**Key takeaway:** `-auto-approve` removes the human checkpoint — only use it in pipelines where approval already happened at the plan stage.

</details>

📖 **Theory:** [terraform-apply](./01_introduction/installation.md#installing-terraform--getting-your-workstation-ready)


---

### Q19 · [Critical] · `terraform-destroy`

> **What does `terraform destroy` do? Is it safe to run in production? How do you prevent accidental destruction?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`terraform destroy` destroys all infrastructure tracked in the current state file. It is equivalent to `terraform apply -destroy`.

It is **not safe** to run in production without safeguards.

Prevention strategies:
1. `lifecycle { prevent_destroy = true }` on critical resources — Terraform will error if anything tries to destroy them
2. IAM permissions — restrict destroy actions in production AWS accounts
3. Remote state with restricted access — operators can't run destroy without access to the state backend
4. Workspace separation — keep prod state in a separate workspace or backend
5. Require `-target` flags in CI to prevent broad destroys

**How to think through this:**
1. In development, destroy is safe and useful for cost management
2. In production, "destroy" should be a rare, deliberate, multi-approval operation
3. The fact that destroy asks for confirmation (`yes`) is not sufficient protection — use `prevent_destroy`

**Key takeaway:** `prevent_destroy = true` on databases, S3 buckets, and other stateful resources is mandatory in production — a confirmation prompt is not enough protection.

</details>

📖 **Theory:** [terraform-destroy](./01_introduction/installation.md#installing-terraform--getting-your-workstation-ready)


---

### Q20 · [Normal] · `remote-state`

> **What is remote state? Why is it better than local state for teams? Name two remote state backends.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Remote state stores `terraform.tfstate` in a shared, centralized location instead of on a local developer's machine.

Why it's better for teams:
- **Shared access**: all team members and CI/CD pipelines read the same state
- **State locking**: prevents concurrent applies that corrupt state
- **Security**: sensitive values in state aren't stored on developer laptops
- **Durability**: backends like S3 provide versioning and backup

Two common remote state backends:
1. **AWS S3** (with DynamoDB for locking) — most common for AWS teams
2. **Terraform Cloud / HCP Terraform** — HashiCorp's managed backend with built-in locking and UI

**How to think through this:**
1. With local state, engineer A applies and now engineer B's state is out of date — they'll fight over resources
2. Remote state is the foundation of team Terraform workflows
3. State locking ensures only one apply runs at a time

**Key takeaway:** Remote state is non-negotiable for any team environment — local state is only appropriate for solo experimentation.

</details>

📖 **Theory:** [remote-state](./05_state_management/remote_state.md#remote-state--sharing-terraform-state-across-teams)


---

### Q21 · [Normal] · `s3-backend`

> **Write the `terraform { backend "s3" {} }` block for storing state in S3 with DynamoDB locking.**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The block above configures:
- `bucket` — the S3 bucket that stores the state file
- `key` — the path within the bucket (use paths like `env/service/terraform.tfstate` for multi-env setups)
- `region` — AWS region of the S3 bucket
- `dynamodb_table` — DynamoDB table used for state locking (must have a partition key named `LockID`)
- `encrypt` — enables server-side encryption at rest

**How to think through this:**
1. The S3 bucket and DynamoDB table must be created before running `terraform init` with this backend
2. The `key` path is how you isolate state between environments — `dev/app/terraform.tfstate` vs `prod/app/terraform.tfstate`
3. `encrypt = true` is a security best practice since state can contain secrets
4. Backend config cannot use variables — values must be literals (or passed via `-backend-config` flags)

**Key takeaway:** S3 + DynamoDB is the standard AWS remote backend pattern — S3 stores the state, DynamoDB provides the distributed lock.

</details>

📖 **Theory:** [s3-backend](./05_state_management/remote_state.md#setting-up-the-s3-backend)


---

### Q22 · [Critical] · `state-locking`

> **What is state locking? What happens if two engineers run `terraform apply` simultaneously without locking?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
State locking prevents concurrent Terraform operations from corrupting the state file. When an apply starts, Terraform writes a lock entry to the backend. Any other apply that tries to start will fail with a lock error until the first one completes.

Without locking, two simultaneous applies can:
1. Both read the same state (both think resource X doesn't exist)
2. Both create resource X independently
3. Both write their state back — one overwrites the other
4. Result: duplicate resources in AWS, one missing from state (orphaned), inconsistent state file

**How to think through this:**
1. State is a file, not a database — without a lock, last-write-wins and you lose data
2. DynamoDB provides atomic conditional writes — only one process holds the lock at a time
3. If a lock gets stuck (apply crashed), use `terraform force-unlock <lock-id>` to manually release it — but verify the apply is truly dead first

**Key takeaway:** State locking is the mutex for your infrastructure — without it, concurrent applies will corrupt your state and create drift.

</details>

📖 **Theory:** [state-locking](./05_state_management/remote_state.md#dynamodb-table-for-state-locking)


---

### Q23 · [Normal] · `providers-init`

> **What does `terraform init` do? What files and directories does it create?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`terraform init` initializes a working directory. It:
1. Downloads providers specified in `required_providers` from the Terraform Registry
2. Downloads modules referenced in `module` blocks
3. Initializes the configured backend (creates or migrates state)
4. Creates a lock file to pin provider versions

Files and directories created:
- `.terraform/` — directory containing downloaded providers and modules
- `.terraform.lock.hcl` — provider version lock file (should be committed to Git)

**How to think through this:**
1. You must run `init` before any other Terraform command in a new directory or after changing providers/backends
2. `.terraform/` is like `node_modules` — generated, not committed to Git
3. `.terraform.lock.hcl` is like `package-lock.json` — commit it to ensure the team uses the same provider versions
4. `terraform init -upgrade` forces provider upgrades within version constraints

**Key takeaway:** `init` is the setup step — it downloads dependencies and prepares the working directory; run it after cloning a repo or adding new providers.

</details>

📖 **Theory:** [providers-init](./03_providers_resources/providers.md#how-terraform-init-downloads-providers)


---

### Q24 · [Thinking] · `resource-attributes`

> **What is the difference between an `argument` and an `attribute` in a Terraform resource? How do you reference a resource attribute?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- **Argument**: a value you set in the resource block to configure it (input). Example: `bucket = "my-bucket"` in `aws_s3_bucket`
- **Attribute**: a value that the resource exposes after creation (output). Some attributes are set by arguments, others are computed by AWS. Example: `aws_instance.web.public_ip` is computed — you can't set it

Reference syntax: `<resource_type>.<local_name>.<attribute_name>`

Example: `aws_instance.web.public_ip`

**How to think through this:**
1. Arguments go inside the resource block when you write the config
2. Computed attributes only exist after the resource is created (they're `(known after apply)` in the plan)
3. Some attributes mirror arguments (you set `bucket = "x"` and `aws_s3_bucket.example.bucket` returns `"x"`)
4. Other attributes are purely computed (instance ID, ARN, assigned IP)

**Key takeaway:** Arguments are inputs you provide; attributes are outputs you consume — both use the same `resource_type.local_name.field` reference syntax.

</details>

📖 **Theory:** [resource-attributes](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q25 · [Normal] · `string-interpolation`

> **What does `"${var.env}-${var.project}-server"` do in HCL? What is the modern way to write this?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
It constructs a string by interpolating variable values. If `var.env = "prod"` and `var.project = "payments"`, the result is `"prod-payments-server"`.

The modern way (when the expression is only string references) is the same syntax — `${}` interpolation is still the standard. However, if the entire value is a single reference, you can skip interpolation:

```hcl
# Unnecessary interpolation (wrapping a single expression)
name = "${var.env}"

# Modern: reference directly
name = var.env

# Interpolation is still correct and preferred for concatenation
name = "${var.env}-${var.project}-server"
```

`terraform fmt` will automatically simplify `"${var.env}"` to `var.env` when there's no concatenation.

**How to think through this:**
1. `${}` is required when mixing variables with literal strings
2. For a bare variable reference with no surrounding text, use `var.name` directly
3. `terraform fmt` enforces this convention automatically

**Key takeaway:** Use `${}` interpolation for string concatenation; use bare `var.name` for single-value references — `terraform fmt` will enforce the distinction.

</details>

📖 **Theory:** [string-interpolation](./02_hcl_basics/syntax.md#string-interpolation)


---

### Q26 · [Normal] · `count-meta-arg`

> **What is the `count` meta-argument? Write an example that creates 3 EC2 instances and outputs each instance's ID.**

```hcl
resource "aws_instance" "web" {
  count         = 3
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"

  tags = {
    Name = "web-${count.index}"
  }
}

output "instance_ids" {
  value = aws_instance.web[*].id
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`count` creates multiple instances of a resource. Each instance is addressed by index: `aws_instance.web[0]`, `aws_instance.web[1]`, `aws_instance.web[2]`.

`count.index` gives the current index (0-based) within the resource block. The splat expression `[*]` collects all instances into a list.

**How to think through this:**
1. `count = 3` tells Terraform to create 3 copies of the resource block
2. Each copy is identical except for anything referencing `count.index`
3. If you later change `count = 2`, Terraform destroys instance `[2]` — the last one
4. This ordering behavior is `count`'s main weakness: removing an item from the middle shifts all subsequent indexes and causes unnecessary replacements

**Key takeaway:** `count` is simple and fine for identical resources; use `for_each` when resources have distinct identities to avoid index-shift problems.

</details>

📖 **Theory:** [count-meta-arg](./03_providers_resources/resources.md#meta-arguments)


---

### Q27 · [Thinking] · `for-each-meta-arg`

> **What is `for_each`? When is it better than `count`? Show an example using a map of strings.**

```hcl
variable "buckets" {
  type    = map(string)
  default = {
    logs    = "us-east-1"
    backups = "us-west-2"
  }
}

resource "aws_s3_bucket" "this" {
  for_each = var.buckets
  bucket   = each.key
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`for_each` creates one resource instance per item in a map or set. Each instance is addressed by key: `aws_s3_bucket.this["logs"]`, `aws_s3_bucket.this["backups"]`.

`for_each` is better than `count` when:
- Resources have distinct names/identities (not just numbered copies)
- You might add/remove items from the middle of the collection — `for_each` uses stable keys, not shifting indexes
- Your input is naturally a map (e.g., a map of environment configs)

**How to think through this:**
1. With `count`, removing `web[1]` of 3 causes `web[2]` to be renamed to `web[1]` — triggers a destroy/recreate
2. With `for_each`, removing key `"logs"` only destroys the `"logs"` instance — other instances are untouched
3. Use `each.key` for the map key, `each.value` for the map value inside the block

**Key takeaway:** Prefer `for_each` over `count` whenever resources have meaningful identities — it gives Terraform stable handles that survive collection changes.

</details>

📖 **Theory:** [for-each-meta-arg](./03_providers_resources/resources.md#meta-arguments)


---

### Q28 · [Normal] · `for-expressions`

> **What is a `for` expression in Terraform? Write an example that transforms a list of strings to uppercase.**

```hcl
variable "names" {
  type    = list(string)
  default = ["alice", "bob", "carol"]
}

locals {
  upper_names = [for name in var.names : upper(name)]
}
# Result: ["ALICE", "BOB", "CAROL"]
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A `for` expression transforms a collection, similar to a list comprehension in Python. It can produce a list `[for ...]` or a map `{for ...}`.

Syntax:
- List: `[for item in collection : transform(item)]`
- Map: `{for k, v in map : k => transform(v)}`
- With filter: `[for item in collection : item if condition]`

**How to think through this:**
1. `for` expressions are evaluated at plan time — they're pure transformations, not resource loops
2. They're different from `for_each` — `for_each` creates resources; `for` transforms data
3. Useful in `locals` to reshape data before using it in resource arguments
4. The `if` clause filters items: `[for s in list : s if s != ""]`

**Key takeaway:** `for` expressions are Terraform's data transformation tool — use them in locals to reshape collections before passing them to resources.

</details>

📖 **Theory:** [for-expressions](./02_hcl_basics/expressions.md#for-expressions)


---

### Q29 · [Normal] · `conditional-expression`

> **What is the Terraform conditional expression syntax? Write an example that uses a different instance type for `prod` vs `dev`.**

```hcl
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Terraform's conditional expression uses the ternary syntax: `condition ? true_value : false_value`

It works anywhere an expression is valid — in resource arguments, locals, and outputs.

**How to think through this:**
1. The condition can be any boolean expression: `==`, `!=`, `>`, `&&`, `||`
2. Both branches must return the same type (or compatible types)
3. Combine with locals for reusability: `instance_type = local.is_prod ? "m5.large" : "t3.micro"`
4. Avoid deeply nesting conditionals — it becomes unreadable; use a `map` lookup instead for many options

**Key takeaway:** The ternary conditional is Terraform's if/else for inline expressions — keep them simple; reach for a map variable when you have more than two options.

</details>

📖 **Theory:** [conditional-expression](./02_hcl_basics/expressions.md#conditional-expressions)


---

### Q30 · [Normal] · `terraform-fmt`

> **What does `terraform fmt` do? What does `terraform validate` do? How do they differ?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `terraform fmt` — reformats `.tf` files to the canonical HCL style (indentation, alignment, spacing). Makes no logical changes — purely cosmetic. Use `-check` flag in CI to fail if files aren't formatted.
- `terraform validate` — checks that the configuration is syntactically valid and internally consistent (correct block types, valid references, required arguments present). Does NOT contact any API — it only validates the config files.

Key differences:
| | `fmt` | `validate` |
|---|---|---|
| Purpose | Style/formatting | Correctness |
| Changes files | Yes | No |
| Requires `init` | No | Yes |
| Contacts API | No | No |

**How to think through this:**
1. Run `fmt` before committing to keep configs readable
2. Run `validate` in CI after `init` to catch config errors before plan
3. Neither catches runtime errors (wrong AMI ID, insufficient IAM permissions) — only `plan` and `apply` reveal those

**Key takeaway:** `fmt` fixes style; `validate` catches logical errors in your config — both should run in CI before `plan`.

</details>

📖 **Theory:** [terraform-fmt](./01_introduction/installation.md#installing-terraform--getting-your-workstation-ready)


---

### Q31 · [Normal] · `lifecycle-block`

> **What does the `lifecycle { prevent_destroy = true }` block do? Name 2 other lifecycle arguments.**

```hcl
resource "aws_db_instance" "main" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`prevent_destroy = true` causes Terraform to return an error if any plan attempts to destroy the resource. It protects critical resources (databases, S3 buckets) from accidental deletion.

Two other lifecycle arguments:
1. `create_before_destroy` — creates the replacement resource before destroying the old one (useful for zero-downtime replacements of resources that require recreation)
2. `ignore_changes` — tells Terraform to ignore diffs in specific attributes, useful when an external system modifies a resource and you don't want Terraform to revert it

```hcl
lifecycle {
  create_before_destroy = true
  ignore_changes        = [tags["LastModified"]]
}
```

**How to think through this:**
1. `prevent_destroy` is a guard rail — use it on anything stateful in production
2. `create_before_destroy` is critical for high-availability — without it, a resource recreation causes a gap in service
3. `ignore_changes` is a pragmatic escape hatch — use sparingly, as it hides drift

**Key takeaway:** `prevent_destroy` is your safety net for production data; `create_before_destroy` keeps services available during forced recreations.

</details>

📖 **Theory:** [lifecycle-block](./03_providers_resources/resources.md#the-resource-block-anatomy)


---

### Q32 · [Interview] · `import-command`

> **What does `terraform import` do? When would you use it? What does it NOT do automatically?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`terraform import` brings an existing real-world resource under Terraform management by adding it to the state file.

Syntax: `terraform import aws_s3_bucket.example my-existing-bucket-name`

When to use it:
- Adopting manually-created ("ClickOps") infrastructure into Terraform
- Recovering from a corrupted or lost state file
- Taking over infrastructure created by another tool

What it does NOT do automatically:
- **It does not generate the `.tf` configuration** — you must write the resource block yourself to match the existing resource
- After import, running `terraform plan` will show diffs between your (possibly incomplete) config and the actual resource state

**How to think through this:**
1. Import only updates the state file — it adds the resource mapping
2. You still need to write accurate HCL that matches the real resource, or the next `apply` will try to modify it
3. Terraform 1.5+ introduced `import` blocks in HCL, and `terraform plan -generate-config-out=generated.tf` can generate config automatically

**Key takeaway:** `terraform import` updates state but not config — always follow an import with a `terraform plan` to ensure your HCL accurately reflects the imported resource.

</details>

📖 **Theory:** [import-command](./05_state_management/state_commands.md#terraform-state-commands--inspecting-and-manipulating-state)


---

### Q33 · [Thinking] · `moved-block`

> **What is the `moved` block in Terraform? Why is it better than manually deleting and re-importing resources?**

```hcl
moved {
  from = aws_instance.old_name
  to   = aws_instance.new_name
}
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The `moved` block (introduced in Terraform 1.1) tells Terraform that a resource has been renamed or restructured in the config. It updates the state mapping without destroying and recreating the resource.

Why it's better than delete-and-reimport:
1. **No downtime** — the resource is never destroyed; only the state reference is updated
2. **No manual steps** — the `moved` block is code, not a CLI procedure; it's reviewable and repeatable
3. **Automation-safe** — works in CI/CD pipelines without special operator intervention
4. **Self-documenting** — the refactor is recorded in the codebase history

**How to think through this:**
1. Without `moved`, renaming `aws_instance.old_name` to `aws_instance.new_name` causes a destroy + create
2. With `moved`, Terraform sees the block and updates the state mapping — plan shows zero changes
3. After applying, remove the `moved` block (or keep it for a transition period)
4. Also works for moving resources into or out of modules: `from = aws_instance.web` → `to = module.app.aws_instance.web`

**Key takeaway:** The `moved` block makes refactoring Terraform configs safe and zero-downtime by updating state references instead of destroying and recreating real infrastructure.

</details>

📖 **Theory:** [moved-block](./05_state_management/state_commands.md#modern-import-block-terraform-15)


---

## 🟡 Tier 2 — Intermediate

### Q34 · [Normal] · `modules-basics`

> **What is a Terraform module? What is the root module? How do you call a child module?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A module is a container for multiple resources that are used together. Every Terraform configuration has at least one module — the root module — which consists of the `.tf` files in the working directory. A child module is any module called from another module.

**How to think through this:**
1. Think of a module as a reusable function: it takes inputs (variables), does work (creates resources), and returns outputs.
2. The root module is the entry point — what you run `terraform apply` against.
3. You call a child module with a `module` block, pointing `source` at a local path, Git URL, or registry address.

**Key takeaway:** Modules are the primary mechanism for code reuse and abstraction in Terraform.

</details>

📖 **Theory:** [modules-basics](./06_modules/creating_modules.md#creating-terraform-modules--writing-reusable-infrastructure-code)


---

### Q35 · [Normal] · `module-inputs-outputs`

> **How do you pass variables into a module and use its outputs? Show an example calling a VPC module.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
You pass variables into a module as arguments in the `module` block. You access its outputs with `module.<name>.<output_name>`.

**How to think through this:**
1. A child module declares `variable` blocks — these become the arguments you set in the caller.
2. A child module declares `output` blocks — these are what the caller can read back.
3. The calling pattern is: `module "label" { source = "..." var_name = value }` and then `module.label.output_name`.

```hcl
module "vpc" {
  source     = "./modules/vpc"
  cidr_block = "10.0.0.0/16"
  env        = "prod"
}

resource "aws_instance" "app" {
  subnet_id = module.vpc.public_subnet_id
}
```

**Key takeaway:** Module inputs are arguments in the `module` block; module outputs are read with `module.<label>.<output>`.

</details>

📖 **Theory:** [module-inputs-outputs](./06_modules/creating_modules.md#modulesnetworkingoutputstf)


---

### Q36 · [Normal] · `module-registry`

> **What is the Terraform Registry? How do you use a community module? What is a module version constraint?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The Terraform Registry (registry.terraform.io) is the public catalog of providers and modules. Community modules are referenced by their registry path, and you pin them with a `version` argument.

**How to think through this:**
1. Registry module sources follow the pattern `<namespace>/<module>/<provider>` (e.g., `terraform-aws-modules/vpc/aws`).
2. The `version` argument accepts constraint expressions like `~> 5.0`.
3. Without a version pin, Terraform will use the latest — risky in production.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"
  name    = "my-vpc"
  cidr    = "10.0.0.0/16"
}
```

**Key takeaway:** Always pin module versions from the registry to prevent unexpected breaking changes.

</details>

📖 **Theory:** [module-registry](./06_modules/module_registry.md#the-terraform-module-registry--pre-built-infrastructure-components)


---

### Q37 · [Normal] · `module-composition`

> **What is module composition? How do you pass the output of one module as the input of another?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Module composition is the pattern of wiring multiple modules together in the root module, passing outputs from one as inputs to another. This replaces deep nesting with a flat, explicit dependency graph.

**How to think through this:**
1. Module A (networking) creates a VPC and exports `vpc_id` and `subnet_ids` as outputs.
2. Module B (compute) needs `vpc_id` and `subnet_ids` as inputs.
3. In the root module, you set `module.compute.vpc_id = module.networking.vpc_id` — Terraform infers the dependency automatically.

**Key takeaway:** Prefer flat composition over deeply nested modules — it keeps dependencies explicit and the graph easier to reason about.

</details>

📖 **Theory:** [module-composition](./06_modules/module_composition.md#module-composition--building-large-infrastructure-from-modules)


---

### Q38 · [Normal] · `workspaces`

> **What are Terraform workspaces? What problem do they solve? What are their limitations compared to separate state files?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Workspaces allow multiple state files within a single configuration directory. They solve the problem of managing multiple environments (dev/staging/prod) without duplicating code. Their limitation is that all workspaces share the same backend config and the same code — making per-environment differences awkward.

**How to think through this:**
1. By default every configuration is in the `default` workspace.
2. Creating a new workspace creates a separate state file in the backend — infrastructure is isolated per workspace.
3. The downside: environment-specific differences require `terraform.workspace` conditionals in code, making it messy. Separate directories give full isolation.

**Key takeaway:** Workspaces are good for lightweight isolation (e.g., feature branches); for true environment isolation, separate state files per directory is more robust.

</details>

📖 **Theory:** [workspaces](./07_workspaces/workspaces.md#terraform-workspaces--one-codebase-multiple-environments)


---

### Q39 · [Normal] · `workspace-commands`

> **What do `terraform workspace new`, `list`, `select`, and `show` do? How do you reference the current workspace name in HCL?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `new <name>` — creates a new workspace and switches to it
- `list` — lists all workspaces; the current one is marked with `*`
- `select <name>` — switches to an existing workspace
- `show` — prints the name of the current workspace

In HCL, reference it with `terraform.workspace`.

**How to think through this:**
1. These commands manipulate workspace state in the configured backend.
2. The `terraform.workspace` expression lets you branch logic: different instance sizes per environment, different naming, etc.
3. Example: `name = "app-${terraform.workspace}"` creates `app-dev`, `app-prod`, etc.

**Key takeaway:** `terraform.workspace` is the HCL expression that returns the current workspace name — useful for tagging and naming resources per environment.

</details>

📖 **Theory:** [workspace-commands](./07_workspaces/workspaces.md#workspace-commands)


---

### Q40 · [Normal] · `environments-pattern`

> **What is the directory-per-environment pattern for Terraform? How does it compare to using workspaces?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The directory-per-environment pattern keeps a separate folder (and separate state file) for each environment: `environments/dev/`, `environments/staging/`, `environments/prod/`. Each calls shared modules with environment-specific variable files.

**How to think through this:**
1. With directories: each environment has its own `terraform.tfvars`, its own state, and can even pin different module versions. Full isolation.
2. With workspaces: one directory, one codebase, multiple states. Simpler to set up, but per-environment config differences creep into the code via conditionals.
3. Most teams at scale prefer the directory pattern because blast radius is smaller — a `terraform apply` in `dev/` can never touch `prod/` state.

**Key takeaway:** Directory-per-environment trades some duplication for full isolation and safety; workspaces trade isolation for simplicity.

</details>

📖 **Theory:** [environments-pattern](./07_workspaces/environments.md#example-environmentsdevmaintf)


---

### Q41 · [Normal] · `state-commands`

> **What do `terraform state list`, `state show`, `state mv`, and `state rm` do? When would you use `state rm`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `state list` — lists all resources tracked in state
- `state show <resource>` — prints the full attributes of one resource
- `state mv <src> <dst>` — renames/moves a resource in state (used when refactoring code)
- `state rm <resource>` — removes a resource from state without destroying it

**How to think through this:**
1. `state mv` is used when you rename a resource or move it into a module — without it, Terraform would destroy and recreate.
2. `state rm` is used when you want Terraform to "forget" a resource: e.g., a resource that was imported by mistake, or one you want to manage outside Terraform going forward.
3. `state rm` does NOT delete the real infrastructure — it only removes the state tracking.

**Key takeaway:** `state rm` orphans a resource from Terraform management without destroying it — use it deliberately.

</details>

📖 **Theory:** [state-commands](./05_state_management/state_commands.md#terraform-state-commands--inspecting-and-manipulating-state)


---

### Q42 · [Normal] · `state-refresh`

> **What does `terraform refresh` do? When is it needed? Why was it removed from the default `apply` workflow in newer Terraform?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`terraform refresh` queries real infrastructure and updates the state file to match current reality, without making any changes. It was removed from the default `apply` flow because it could cause unintended plan changes and was a source of confusion and accidental drift correction.

**How to think through this:**
1. If someone manually changed a resource outside Terraform, `refresh` would pull that change into state, potentially masking drift.
2. In Terraform 0.15.4+, the behavior was folded into `plan` as `-refresh-only` mode — a safer, explicit alternative.
3. `terraform apply -refresh-only` lets you reconcile state with reality without applying config changes.

**Key takeaway:** Use `terraform plan -refresh-only` to sync state with real infrastructure instead of the deprecated `terraform refresh`.

</details>

📖 **Theory:** [state-refresh](./05_state_management/state_commands.md#terraform-state-commands--inspecting-and-manipulating-state)


---

### Q43 · [Normal] · `taint-replace`

> **What did `terraform taint` do (deprecated)? What replaced it? How do you force-recreate a resource?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`terraform taint <resource>` marked a resource as "tainted" in state, forcing it to be destroyed and recreated on the next apply. It was deprecated in Terraform 0.15.2 and replaced by the `-replace` flag.

**How to think through this:**
1. The old flow: `terraform taint aws_instance.web` → `terraform apply` → instance recreated.
2. The new flow: `terraform apply -replace="aws_instance.web"` — does the same thing in one command without modifying state directly.
3. `-replace` is safer because it's visible in the plan output and doesn't leave taint state if the apply is cancelled.

**Key takeaway:** Replace `terraform taint` with `terraform apply -replace="resource.name"` in all modern workflows.

</details>

📖 **Theory:** [taint-replace](./05_state_management/state_commands.md#terraform-state-commands--inspecting-and-manipulating-state)


---

### Q44 · [Normal] · `target-flag`

> **What does `-target=resource.name` do in `terraform plan` and `apply`? Why should it be used sparingly?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`-target` restricts the plan or apply to a specific resource (and its dependencies). It tells Terraform to ignore everything else in the configuration for that operation.

**How to think through this:**
1. Useful in emergencies: you need to fix one broken resource without touching others.
2. The danger: it bypasses Terraform's full dependency graph. You can apply a partial state where dependent resources are out of sync with their sources.
3. It can lead to state drift — your code says one thing, your state says another — because related resources weren't updated together.
4. HashiCorp explicitly warns: "using -target routinely is a sign of architectural problems."

**Key takeaway:** `-target` is an escape hatch for emergencies, not a workflow tool — overuse leads to state inconsistency.

</details>

📖 **Theory:** [target-flag](./05_state_management/state_commands.md#importtf--import-as-code-no-cli-flag-needed)


---

### Q45 · [Normal] · `dynamic-blocks`

> **What is a Terraform `dynamic` block? Write an example that creates multiple security group rules from a variable list.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A `dynamic` block generates repeated nested blocks programmatically from a collection, avoiding copy-paste of repeated block structures.

**How to think through this:**
1. Some resources have nested blocks (like `ingress` in a security group) that can't use `for_each` directly — they're blocks, not top-level resources.
2. `dynamic "block_name"` iterates over a collection and renders one block per item.
3. Inside the dynamic block, `content {}` defines the block body; the iterator is accessed via `<label>.value`.

```hcl
variable "ingress_rules" {
  default = [
    { port = 80,  protocol = "tcp" },
    { port = 443, protocol = "tcp" },
  ]
}

resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

**Key takeaway:** Use `dynamic` blocks when a resource requires repeated nested blocks driven by a variable-length collection.

</details>

📖 **Theory:** [dynamic-blocks](./02_hcl_basics/expressions.md#dynamic-blocks)


---

### Q46 · [Normal] · `templatefile-function`

> **What does the `templatefile()` function do? Write an example that generates a user_data script from a template.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`templatefile(path, vars)` reads a file from disk and renders it as a template, substituting `${var}` placeholders with values from the `vars` map. It is the modern replacement for the `template_file` data source.

**How to think through this:**
1. You write a template file (e.g., `user_data.sh.tpl`) with `${variable}` placeholders.
2. You call `templatefile("path/to/file.tpl", { key = value })` in your HCL.
3. The rendered string can be passed directly to `user_data` on an EC2 instance.

```hcl
# user_data.sh.tpl
#!/bin/bash
echo "Hello from ${hostname}" > /etc/motd
yum install -y ${package}

# main.tf
resource "aws_instance" "app" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    hostname = "app-server-01"
    package  = "nginx"
  })
}
```

**Key takeaway:** `templatefile()` keeps shell scripts and config files out of HCL while letting Terraform inject dynamic values at plan time.

</details>

📖 **Theory:** [templatefile-function](./02_hcl_basics/expressions.md#hcl-expressions--making-your-code-dynamic-and-smart)


---

### Q47 · [Normal] · `built-in-functions`

> **Name 5 commonly used Terraform functions and what they do: `toset`, `merge`, `flatten`, `lookup`, `jsonencode`.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `toset(list)` — converts a list to a set (removes duplicates, enables `for_each`)
- `merge(map1, map2, ...)` — merges multiple maps; later maps override earlier keys
- `flatten(list_of_lists)` — collapses nested lists into a single flat list
- `lookup(map, key, default)` — safely retrieves a map value, returning a default if the key is missing
- `jsonencode(value)` — converts any Terraform value to a JSON string (common for IAM policies)

**How to think through this:**
1. `toset` is essential before using `for_each` on a list variable — `for_each` requires a set or map, not a list.
2. `merge` is used to combine a base tag map with resource-specific tags.
3. `flatten` handles outputs from `for_each` modules that return lists of lists.
4. `lookup` is defensive map access — prevents errors when a key might not exist.
5. `jsonencode` avoids writing raw JSON heredocs in HCL for IAM policies.

**Key takeaway:** These five functions cover the most common data transformation needs in real-world Terraform configs.

</details>

📖 **Theory:** [built-in-functions](./02_hcl_basics/expressions.md#hcl-expressions--making-your-code-dynamic-and-smart)


---

### Q48 · [Normal] · `null-resource`

> **What is a `null_resource`? When would you use it? What replaced it in modern Terraform?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A `null_resource` is a resource that does nothing by itself but can trigger provisioners or act as a dependency anchor. It was replaced by `terraform_data` in Terraform 1.4.

**How to think through this:**
1. Common use cases: run a local script after a resource is created, force re-execution when an input changes (via `triggers`), or create an explicit dependency between resources that Terraform wouldn't otherwise connect.
2. The `triggers` map re-creates the resource (and re-runs provisioners) when any trigger value changes.
3. `terraform_data` does the same thing but requires no provider — it is built into Terraform core.

**Key takeaway:** Prefer `terraform_data` over `null_resource` in Terraform 1.4+ — same functionality, no provider dependency required.

</details>

📖 **Theory:** [null-resource](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q49 · [Normal] · `terraform-null-provider`

> **What is `terraform_data` (introduced in Terraform 1.4)? How does it differ from `null_resource`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`terraform_data` is a built-in resource type (no provider needed) that stores arbitrary values in state and can trigger re-execution when inputs change. It is the official successor to `null_resource`.

**How to think through this:**
1. `null_resource` required the `hashicorp/null` provider — an extra dependency to manage and version.
2. `terraform_data` is part of Terraform core itself, so no provider block or version pin is needed.
3. It has an `input` argument (stores a value in state) and `triggers_replace` (replaces the resource when the value changes) — cleaner API than `null_resource`'s `triggers` map.

**Key takeaway:** `terraform_data` removes the provider dependency of `null_resource` and provides a cleaner API for storing values and triggering replacement.

</details>

📖 **Theory:** [terraform-null-provider](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q50 · [Normal] · `provisioners`

> **What are Terraform provisioners (`local-exec`, `remote-exec`, `file`)? Why does HashiCorp recommend avoiding them?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Provisioners run scripts or copy files during resource creation or destruction. `local-exec` runs a command on the machine running Terraform; `remote-exec` runs commands on the remote resource via SSH/WinRM; `file` copies files to a remote resource.

**How to think through this:**
1. They break Terraform's declarative model — provisioners are imperative and their success or failure is not captured in state.
2. If a provisioner fails mid-way, the resource is left in a "tainted" state, requiring manual intervention.
3. They create implicit dependencies on network connectivity, SSH access, and external tooling.
4. Better alternatives: bake AMIs with Packer, use cloud-init/user_data for bootstrapping, or use a real configuration management tool (Ansible, Chef).

**Key takeaway:** Provisioners are a last resort — they break idempotency and declarative guarantees; prefer immutable AMIs or user_data instead.

</details>

📖 **Theory:** [provisioners](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q51 · [Normal] · `sensitive-variables`

> **How do you mark a variable or output as sensitive in Terraform? What does this affect in plan/apply output?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Add `sensitive = true` to a `variable` or `output` block. Terraform will then redact the value in plan, apply, and `terraform output` terminal output, replacing it with `(sensitive value)`.

**How to think through this:**
1. Marking a variable sensitive prevents it from appearing in logs — important for passwords, API keys, and tokens.
2. The value is still stored in state in plaintext — sensitive = true only affects CLI output, not state encryption.
3. An output that references a sensitive variable is automatically treated as sensitive in Terraform 0.14+.
4. You can still retrieve the value with `terraform output -json` — the flag controls display, not access.

**Key takeaway:** `sensitive = true` prevents secrets from appearing in terminal output and logs, but state encryption is a separate concern.

</details>

📖 **Theory:** [sensitive-variables](./04_variables_outputs/variables.md#sensitive-variables)


---

### Q52 · [Normal] · `secrets-in-terraform`

> **What are the risks of storing secrets in Terraform state? What are the recommended patterns for managing secrets?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Terraform state stores all resource attributes in plaintext JSON, including any secrets returned by providers (RDS passwords, IAM access keys, etc.). If state is not encrypted and access-controlled, secrets are exposed.

**How to think through this:**
1. Risk: state files in unencrypted S3 buckets or local disk are a common secrets leak vector.
2. Mitigation for state: use S3 with server-side encryption + bucket policy + versioning, or Terraform Cloud (encrypts state at rest).
3. Pattern 1 — generate secrets outside Terraform: create RDS passwords in AWS Secrets Manager, then reference the ARN in Terraform without the plaintext ever entering state.
4. Pattern 2 — use `sensitive` outputs + restricted state access (IAM policies on the S3 bucket).
5. Pattern 3 — never hardcode secrets in `.tfvars` files; inject via environment variables (`TF_VAR_password`) in CI/CD.

**Key takeaway:** Encrypt and restrict access to state storage — it always contains sensitive data, regardless of `sensitive = true` in code.

</details>

📖 **Theory:** [secrets-in-terraform](./09_best_practices/security.md#security-best-practices--keeping-terraform-safe)


---

### Q53 · [Normal] · `aws-with-terraform-vpc`

> **Write the Terraform resources to create a VPC with one public subnet, an Internet Gateway, and a route table. (Describe the resources, don't write full HCL)**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
You need four resources: `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table`, plus `aws_route_table_association` to link the subnet to the route table.

**How to think through this:**
1. `aws_vpc` — defines the CIDR block and enables DNS support.
2. `aws_subnet` — references the VPC ID, specifies a CIDR subset, sets `map_public_ip_on_launch = true` for a public subnet.
3. `aws_internet_gateway` — attached to the VPC; enables outbound internet traffic.
4. `aws_route_table` — attached to the VPC; contains a route `0.0.0.0/0 → igw-id`.
5. `aws_route_table_association` — links the route table to the specific subnet (without this, the subnet uses the VPC's default route table).

**Key takeaway:** A public subnet requires three things beyond the subnet itself: an IGW, a route table with a default route to that IGW, and a route table association.

</details>

📖 **Theory:** [aws-with-terraform-vpc](./08_aws_with_terraform/vpc.md#building-a-vpc-with-terraform--complete-working-example)


---

### Q54 · [Normal] · `aws-with-terraform-ec2`

> **What Terraform resources do you need to launch an EC2 instance with a security group and IAM instance profile?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
You need: `aws_security_group`, `aws_iam_role`, `aws_iam_instance_profile`, and `aws_instance`.

**How to think through this:**
1. `aws_security_group` — defines inbound/outbound rules; reference its ID in the instance's `vpc_security_group_ids`.
2. `aws_iam_role` — with a trust policy allowing `ec2.amazonaws.com` to assume it; attach policies to grant permissions.
3. `aws_iam_instance_profile` — wraps the IAM role so EC2 can use it; the instance references `iam_instance_profile = aws_iam_instance_profile.this.name`.
4. `aws_instance` — combines everything: `ami`, `instance_type`, `subnet_id`, `vpc_security_group_ids`, `iam_instance_profile`.
5. Optionally: `aws_key_pair` if SSH access is needed.

**Key takeaway:** EC2 needs an instance profile (not a role directly) to assume an IAM role — the profile is the bridge between EC2 and IAM.

</details>

📖 **Theory:** [aws-with-terraform-ec2](./08_aws_with_terraform/ec2.md#ec2-with-terraform--launching-virtual-machines)


---

### Q55 · [Normal] · `aws-with-terraform-s3`

> **Write the key arguments for an `aws_s3_bucket` resource: versioning, server-side encryption, and public access blocking.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Since AWS provider v4+, these are separate resources from `aws_s3_bucket`.

**How to think through this:**
1. `aws_s3_bucket` — just the bucket name and tags.
2. `aws_s3_bucket_versioning` — references bucket ID; sets `versioning_configuration { status = "Enabled" }`.
3. `aws_s3_bucket_server_side_encryption_configuration` — sets `rule { apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" } }`.
4. `aws_s3_bucket_public_access_block` — sets all four block flags to `true`: `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`.

```hcl
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**Key takeaway:** In AWS provider v4+, S3 bucket configuration is split across multiple resources — don't use the deprecated inline blocks.

</details>

📖 **Theory:** [aws-with-terraform-s3](./08_aws_with_terraform/s3.md#s3-with-terraform--object-storage-buckets-and-policies)


---

### Q56 · [Normal] · `aws-with-terraform-iam`

> **How do you create an IAM role with a trust policy and attach a managed policy using Terraform? Name the resources needed.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
You need `aws_iam_role` (with the trust/assume-role policy) and `aws_iam_role_policy_attachment` (to attach a managed policy ARN).

**How to think through this:**
1. `aws_iam_role` — the `assume_role_policy` argument takes a JSON string defining who can assume the role (the trust policy). Use `jsonencode()` or a `data.aws_iam_policy_document`.
2. `aws_iam_role_policy_attachment` — attaches an existing managed policy (by ARN) to the role.
3. For inline policies: use `aws_iam_role_policy` instead.
4. For creating a custom managed policy first: use `aws_iam_policy`, then attach it.

**Key takeaway:** Trust policy (who can assume) lives on `aws_iam_role`; permission policies are attached separately via `aws_iam_role_policy_attachment`.

</details>

📖 **Theory:** [aws-with-terraform-iam](./08_aws_with_terraform/iam.md#iam-with-terraform--roles-policies-and-least-privilege)


---

### Q57 · [Normal] · `aws-with-terraform-rds`

> **What Terraform resources and arguments do you need for an RDS instance: engine, multi-AZ, storage, subnet group?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
You need `aws_db_subnet_group` and `aws_db_instance` (plus a security group).

**How to think through this:**
1. `aws_db_subnet_group` — lists the subnet IDs (must be in at least 2 AZs) that RDS can use; referenced by the instance.
2. `aws_db_instance` key arguments:
   - `engine` and `engine_version` — e.g., `"postgres"`, `"15.3"`
   - `instance_class` — e.g., `"db.t3.micro"`
   - `allocated_storage` — in GB
   - `multi_az = true` — enables standby replica in a second AZ
   - `db_subnet_group_name` — references the subnet group
   - `vpc_security_group_ids` — controls network access
   - `username`, `password` — master credentials (use `sensitive` or Secrets Manager)
   - `skip_final_snapshot = true` — required to destroy without error in dev

**Key takeaway:** RDS requires a subnet group (defines the VPC subnets) before the instance can be created — it's a dependency, not optional.

</details>

📖 **Theory:** [aws-with-terraform-rds](./08_aws_with_terraform/rds.md#rds-with-terraform--managed-relational-databases)


---

### Q58 · [Normal] · `version-constraints`

> **What do `~>`, `>=`, `=`, and `!=` mean in Terraform version constraints? What is the difference between provider version and Terraform version constraints?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- `~> 5.0` — pessimistic constraint: allows `5.x` but not `6.0` (patch/minor updates only)
- `>= 1.3.0` — minimum version
- `= 5.1.2` — exact pin
- `!= 5.0.0` — excludes a specific version

Provider version constraints go in the `required_providers` block inside `terraform {}`. The Terraform binary version constraint goes in `required_version` inside `terraform {}`.

**How to think through this:**
1. `~> 5.0` is shorthand for `>= 5.0, < 6.0` — the most common constraint for providers.
2. `~> 5.1.2` means `>= 5.1.2, < 5.2.0` — more restrictive, locks to a patch range.
3. `required_version` constrains which Terraform CLI can run the config — important for team consistency.
4. `required_providers` constrains the provider plugins downloaded by `terraform init`.

**Key takeaway:** Use `~>` for providers (allow minor updates, block majors) and set `required_version` to prevent teammates running an incompatible Terraform binary.

</details>

📖 **Theory:** [version-constraints](./03_providers_resources/providers.md#version-constraints-explained)


---

### Q59 · [Normal] · `terraform-lock-file`

> **What is `.terraform.lock.hcl`? Why should it be committed to version control? What does `terraform providers lock` do?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`.terraform.lock.hcl` is the dependency lock file generated by `terraform init`. It records the exact provider versions and their checksums selected during initialization. It must be committed to version control to ensure the entire team and CI/CD use identical provider versions.

**How to think through this:**
1. Without the lock file: two engineers running `terraform init` at different times may get different provider patch versions, leading to inconsistent behavior.
2. The file contains SHA256 hashes of provider binaries — Terraform verifies these on subsequent inits to detect tampering.
3. `terraform providers lock` regenerates or updates the lock file for specified platforms (e.g., `linux_amd64`, `darwin_arm64`) — useful when the CI platform differs from developer machines.
4. Update it intentionally with `terraform init -upgrade` when you want to move to a newer provider version.

**Key takeaway:** Commit `.terraform.lock.hcl` — it is the provider equivalent of `package-lock.json` and guarantees reproducible infrastructure builds.

</details>

📖 **Theory:** [terraform-lock-file](./03_providers_resources/providers.md#terraformlockhcl--commit-this-to-git)


---

### Q60 · [Normal] · `ci-cd-terraform`

> **Describe a CI/CD pipeline for Terraform. What are the stages? What tools integrate with Terraform (e.g., Atlantis, Terraform Cloud)?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A standard Terraform CI/CD pipeline has these stages: lint/validate → plan → manual approval → apply.

**How to think through this:**
1. **Lint/Validate**: `terraform fmt -check`, `terraform validate`, and static analysis tools like `tflint` or `checkov` for security policy checks.
2. **Plan**: `terraform plan -out=tfplan` saves the plan artifact; post the output as a PR comment so reviewers can see what will change.
3. **Manual approval**: A human reviews the plan output before apply — critical for production.
4. **Apply**: `terraform apply tfplan` executes the saved plan — using the saved file ensures what was reviewed is what gets applied.
5. Tools:
   - **Atlantis**: self-hosted bot that runs plan on PR open and apply on PR merge — GitOps workflow.
   - **Terraform Cloud/Enterprise**: managed platform with remote runs, policy enforcement (Sentinel), and team access controls.
   - **GitHub Actions / GitLab CI**: generic CI with Terraform steps wired in manually.

**Key takeaway:** The plan-then-approve pattern is the safety guarantee of Terraform CI/CD — never auto-apply without a human reviewing the plan diff.

</details>

📖 **Theory:** [ci-cd-terraform](./09_best_practices/ci_cd_integration.md#cicd-integration--automating-terraform-in-pipelines)


---

### Q61 · [Normal] · `code-organization`

> **Describe the recommended file structure for a Terraform project. What goes in `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The conventional file layout separates concerns by file type, not by resource:

- `providers.tf` — `terraform {}` block with `required_version`, `required_providers`, and `provider` configuration blocks.
- `variables.tf` — all `variable` blocks with descriptions, types, and defaults.
- `outputs.tf` — all `output` blocks exposing values to callers or operators.
- `main.tf` — the primary resource definitions and `module` calls.
- `locals.tf` (optional) — `locals {}` blocks for computed values.
- `terraform.tfvars` — actual variable values (not committed if sensitive).

**How to think through this:**
1. This split makes it easy to find things: "where are the inputs?" → `variables.tf`. "What does this expose?" → `outputs.tf`.
2. For large projects, split `main.tf` into topic files: `networking.tf`, `compute.tf`, `iam.tf`.
3. Modules follow the same layout in their own directory.

**Key takeaway:** Consistent file naming lets any Terraform practitioner navigate an unfamiliar codebase instantly — it is a convention, not enforcement.

</details>

📖 **Theory:** [code-organization](./09_best_practices/code_organization.md#code-organization--structuring-terraform-projects-for-maintainability)


---

### Q62 · [Normal] · `security-best-practices`

> **Name 5 Terraform security best practices: state encryption, least-privilege, secret management, code review, drift detection.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
1. **State encryption**: Store state in S3 with SSE-KMS enabled and bucket policies restricting access. Never use local state in production.
2. **Least-privilege**: The IAM role used by Terraform (in CI/CD or locally) should only have permissions to manage the resources it owns — not `AdministratorAccess`.
3. **Secret management**: Never hardcode secrets in `.tf` files or `.tfvars`. Inject via environment variables or retrieve from Secrets Manager/Vault at runtime.
4. **Code review with plan output**: Treat Terraform PRs like application code — require plan output review before merge, use tools like `checkov` or `tfsec` for automated policy checks.
5. **Drift detection**: Run `terraform plan` regularly in CI (or use Terraform Cloud drift detection) to identify out-of-band changes before they cause incidents.

**How to think through this:**
Each practice maps to a real attack vector: unencrypted state = secret exposure; overprivileged CI role = blast radius; hardcoded secrets = credential leak; unreviewed plans = accidental deletion; undetected drift = unknown attack surface.

**Key takeaway:** Terraform security is about protecting state, limiting permissions, keeping secrets out of code, and making changes visible before they happen.

</details>

📖 **Theory:** [security-best-practices](./09_best_practices/security.md#security-best-practices--keeping-terraform-safe)


---

### Q63 · [Normal] · `drift-detection`

> **What is infrastructure drift? How do you detect it with Terraform? What causes drift?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Infrastructure drift is when the real state of infrastructure diverges from what Terraform's state file (and config) describes. Terraform detects it by running `terraform plan` — any changes shown in the plan when no code changes were made indicate drift.

**How to think through this:**
1. Causes of drift: manual changes via console or CLI, automated remediation tools, expiring credentials that trigger rotations, cloud provider auto-updates (e.g., RDS minor version upgrades).
2. Detection: `terraform plan -refresh-only` shows what changed in the real world vs. state. A non-empty plan against unchanged code = drift.
3. Resolution: either update the code to match reality (import the change), or apply to force infrastructure back to the declared state.
4. Prevention: enforce "no console changes" policies, use SCPs or IAM deny policies to block manual changes in managed environments.

**Key takeaway:** Drift is the gap between declared and actual infrastructure — detected by `terraform plan`, resolved by either updating code or re-applying.

</details>

📖 **Theory:** [drift-detection](./05_state_management/state_commands.md#3-check-for-drift-state-vs-real-world)


---

### Q64 · [Normal] · `terraform-cloud`

> **What is Terraform Cloud? What features does it add over open-source Terraform (remote state, VCS integration, policy)?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Terraform Cloud is HashiCorp's managed platform for running Terraform. It adds remote execution, managed state storage, VCS-triggered runs, team access controls, and policy enforcement on top of open-source Terraform.

**How to think through this:**
1. **Remote state**: encrypted state storage with locking — no S3 bucket setup required.
2. **Remote execution**: plans and applies run on HCP-managed workers, not on developer laptops — consistent environment, audit logs.
3. **VCS integration**: connect a GitHub/GitLab repo; Terraform Cloud auto-runs `plan` on PR and `apply` on merge.
4. **Team access controls**: fine-grained permissions — who can plan, who can approve applies.
5. **Sentinel policies**: policy-as-code framework to enforce rules before apply (e.g., "no public S3 buckets").
6. **Private module registry**: share internal modules across teams.

**Key takeaway:** Terraform Cloud transforms Terraform from a CLI tool into a collaborative platform with audit trails, policy enforcement, and managed state.

</details>

📖 **Theory:** [terraform-cloud](./09_best_practices/ci_cd_integration.md#cicd-integration--automating-terraform-in-pipelines)


---

### Q65 · [Normal] · `sentinel-policies`

> **What is HashiCorp Sentinel? What kind of policies can you enforce with it? Give an example policy.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Sentinel is HashiCorp's policy-as-code framework, embedded in Terraform Cloud/Enterprise. It evaluates policies against the Terraform plan before apply is allowed — acting as a governance gate between plan and apply.

**How to think through this:**
1. Policies are written in the Sentinel language (similar to Python) and have three enforcement levels: `advisory` (warn only), `soft-mandatory` (can be overridden), `hard-mandatory` (blocks apply, no override).
2. Common policy types: cost controls (block instance types over a size), security rules (require encryption, block public resources), tagging enforcement (all resources must have `owner` tag), region restrictions.
3. Sentinel policies inspect the Terraform plan data — they can see every resource being created, changed, or destroyed.

Example policy concept: "All `aws_s3_bucket` resources must have `aws_s3_bucket_public_access_block` with all four flags set to true."

**Key takeaway:** Sentinel enforces organizational guardrails automatically — it prevents non-compliant infrastructure from being applied, not just flagged.

</details>

📖 **Theory:** [sentinel-policies](./09_best_practices/security.md#security-best-practices--keeping-terraform-safe)


---

### Q66 · [Normal] · `atlantis`

> **What is Atlantis? How does it enable GitOps for Terraform? What workflow does it implement?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Atlantis is an open-source, self-hosted Terraform pull request automation tool. It listens for webhook events from GitHub/GitLab/Bitbucket and runs `terraform plan` on PR open and `terraform apply` on PR merge (or via a comment command), making infrastructure changes fully GitOps-driven.

**How to think through this:**
1. The workflow: developer opens a PR → Atlantis detects changed `.tf` files → runs `terraform plan` → posts plan output as a PR comment → reviewer approves → developer comments `atlantis apply` → Atlantis applies and posts results.
2. GitOps principles it implements: Git is the single source of truth, all changes are via PR, the plan output is visible before merge, applies are triggered by merge (not manual CLI runs).
3. Key features: per-repo or global config (`atlantis.yaml`), locks to prevent concurrent applies on the same workspace, supports multiple workspaces and directories in a monorepo.
4. Compared to Terraform Cloud: Atlantis is self-hosted and free; Terraform Cloud is managed but paid for team features.

**Key takeaway:** Atlantis closes the loop between Git and infrastructure — no Terraform command is ever run outside of a PR review cycle.

</details>

📖 **Theory:** [atlantis](./09_best_practices/ci_cd_integration.md#atlantis--gitops-for-terraform)


---

## 🟠 Tier 3 — Advanced

### Q67 · [Thinking] · `provider-alias`

> **What is a provider alias in Terraform? Write an example that deploys resources in two different AWS regions using the same provider.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A provider alias lets you register multiple instances of the same provider with different configurations. Without aliases, you can only have one configuration per provider. With aliases, you can deploy to multiple regions, accounts, or environments in a single root module.

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_s3_bucket" "east" {
  bucket = "my-bucket-east"
  # uses the default provider (us-east-1)
}

resource "aws_s3_bucket" "west" {
  provider = aws.west
  bucket   = "my-bucket-west"
}
```

**How to think through this:**
1. Terraform identifies providers by type + alias. `aws` and `aws.west` are two distinct provider instances.
2. Resources use the default provider unless you specify `provider = aws.<alias>`.
3. Modules can also accept provider aliases via the `providers` argument.

**Key takeaway:** Provider aliases allow multi-region or multi-account deployments within a single Terraform configuration.

</details>

📖 **Theory:** [provider-alias](./03_providers_resources/providers.md#provider-aliases--multiple-regions-or-accounts)


---

### Q68 · [Thinking] · `cross-module-data`

> **How do you share data between two independent Terraform modules (not parent-child)? What are the options?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Independent modules (separate state files) cannot reference each other's resources directly. The options are:

1. **Remote state data source** — the most common approach. One module reads another module's outputs via `terraform_remote_state`.
2. **SSM Parameter Store / Secrets Manager** — one module writes a value, another reads it using a data source.
3. **Hard-coded or variable injection** — pass values manually (least elegant, breaks automation).

```hcl
# In module B — reading outputs from module A
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "my-tf-state"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "app" {
  subnet_id = data.terraform_remote_state.networking.outputs.subnet_id
}
```

**How to think through this:**
1. Ask whether the two modules are truly independent or if one should be a child of the other.
2. If truly independent, remote state is clean because it stays in the Terraform ecosystem.
3. SSM is preferred when the producing module is non-Terraform or when you want to decouple state access from IAM roles.

**Key takeaway:** Use `terraform_remote_state` for Terraform-to-Terraform sharing; use SSM/Parameter Store when you want looser coupling or cross-tool sharing.

</details>

📖 **Theory:** [cross-module-data](./06_modules/module_composition.md#module-composition--building-large-infrastructure-from-modules)


---

### Q69 · [Thinking] · `backends-advanced`

> **What is the difference between partial configuration for a backend and hardcoded backend config? Why is partial config useful for CI/CD?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **hardcoded backend** has all values in the `terraform {}` block:

```hcl
terraform {
  backend "s3" {
    bucket = "my-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

A **partial configuration** leaves some or all values out of the block and supplies them at `terraform init` time:

```hcl
terraform {
  backend "s3" {}
}
```

Then at init:
```bash
terraform init \
  -backend-config="bucket=my-state-bucket" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

**How to think through this:**
1. Hardcoded config couples the code to a specific bucket/key — every environment needs a different file or you risk overwriting state.
2. Partial config lets the same code be initialized into different state locations by passing different `-backend-config` flags.
3. In CI/CD, you inject backend values as environment variables or pipeline parameters, keeping sensitive values out of source code.

**Key takeaway:** Partial backend configuration enables the same Terraform code to be deployed to multiple environments without modifying source files.

</details>

📖 **Theory:** [backends-advanced](./05_state_management/remote_state.md#backendsprodhcl)


---

### Q70 · [Thinking] · `state-migration`

> **How do you migrate Terraform state from local to S3 backend? Walk through the steps.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Step 1 — Back up local state**
```bash
cp terraform.tfstate terraform.tfstate.backup
```

**Step 2 — Add the S3 backend block to your config**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "myproject/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

**Step 3 — Run `terraform init`**
```bash
terraform init
```
Terraform detects the backend change and asks: "Do you want to copy existing state to the new backend?" Answer `yes`.

**Step 4 — Verify**
```bash
terraform state list
```
Confirm all resources are present. Check the S3 bucket for the state file.

**Step 5 — Remove local state (optional)**
```bash
rm terraform.tfstate terraform.tfstate.backup
```

**How to think through this:**
1. Never skip the backup step — state migration is non-destructive by default but accidents happen.
2. The `init` copy is atomic from Terraform's perspective, but the S3 bucket must already exist.
3. DynamoDB locking should be set up before migration if other engineers may run apply.

**Key takeaway:** Terraform handles state migration automatically during `terraform init` when you add or change a backend — you just need to confirm the copy.

</details>

📖 **Theory:** [state-migration](./05_state_management/remote_state.md#remote-state--sharing-terraform-state-across-teams)


---

### Q71 · [Thinking] · `resource-graph`

> **How does Terraform build its dependency graph? What is the difference between implicit and explicit dependency? How do `depends_on` and `terraform graph` help?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Terraform builds a **directed acyclic graph (DAG)** of all resources before any action. Nodes are resources/data sources; edges are dependencies.

**Implicit dependency** — Terraform detects it automatically when one resource references another's attribute:
```hcl
resource "aws_subnet" "main" { vpc_id = aws_vpc.main.id }
# Terraform knows aws_vpc.main must exist first
```

**Explicit dependency** — You declare it with `depends_on` when there is no attribute reference but an ordering requirement exists:
```hcl
resource "aws_iam_role_policy_attachment" "attach" {
  depends_on = [aws_iam_role.main]
}
```

`terraform graph` outputs the dependency graph in DOT format, which you can visualize with Graphviz:
```bash
terraform graph | dot -Tsvg > graph.svg
```

**How to think through this:**
1. Prefer implicit dependencies — they are self-documenting and always accurate.
2. Use `depends_on` only for non-obvious ordering (e.g., IAM propagation delay, API Gateway deployments).
3. Overusing `depends_on` serializes work that could run in parallel, slowing apply time.

**Key takeaway:** Terraform's dependency graph determines creation order and parallelism; implicit dependencies from attribute references are preferred over explicit `depends_on`.

</details>

📖 **Theory:** [resource-graph](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q72 · [Thinking] · `for-each-vs-count`

> **A resource was deployed with `count = 3`. You need to switch to `for_each`. What happens if you just change the code? How do you migrate safely?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
If you simply swap `count = 3` for `for_each`, Terraform sees the old resources (`resource[0]`, `resource[1]`, `resource[2]`) and the new ones (keyed by string) as completely different resources. The plan will **destroy all 3 and create 3 new ones** — destructive.

**Safe migration using `terraform state mv`:**

```bash
# Assuming for_each keys will be "a", "b", "c"
terraform state mv 'aws_instance.main[0]' 'aws_instance.main["a"]'
terraform state mv 'aws_instance.main[1]' 'aws_instance.main["b"]'
terraform state mv 'aws_instance.main[2]' 'aws_instance.main["c"]'
```

After moving state, `terraform plan` should show no changes (or only tag/metadata changes).

**How to think through this:**
1. `count` addresses resources by integer index; `for_each` addresses by map/set key.
2. Changing the addressing scheme without moving state = destroy + recreate.
3. Plan first after state moves to confirm zero destructive changes before applying.

**Key takeaway:** Switching from `count` to `for_each` requires `terraform state mv` for each instance to remap integer indexes to string keys without destroying resources.

</details>

📖 **Theory:** [for-each-vs-count](./03_providers_resources/resources.md#2-for_each--create-copies-from-a-map-or-set)


---

### Q73 · [Thinking] · `provider-upgrades`

> **How do you upgrade a provider version in Terraform? What can break and how do you test it safely?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Upgrade steps:**
1. Update the version constraint in `required_providers`:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```
2. Run `terraform init -upgrade` to download the new version.
3. Run `terraform plan` to check for diff.

**What can break:**
- **Removed resources or data sources** — deprecated things get removed in major versions.
- **Attribute renames** — field names change between major versions.
- **Default behavior changes** — a provider may start enforcing a previously optional argument.
- **State schema changes** — rare, but provider upgrades can require state migrations.

**Safe testing approach:**
1. Check the provider's CHANGELOG for breaking changes.
2. Test in a non-production workspace or throwaway environment first.
3. Run `terraform plan` and review every diff carefully.
4. Use `checkov` or `tfsec` to catch policy violations introduced by new defaults.

**Key takeaway:** Always read the provider CHANGELOG before upgrading and validate with `terraform plan` in a safe environment before applying to production.

</details>

📖 **Theory:** [provider-upgrades](./03_providers_resources/providers.md#terraform-providers--plugins-that-talk-to-the-world)


---

### Q74 · [Thinking] · `testing-terraform`

> **What tools exist for testing Terraform code: Terratest, terraform test, checkov, tfsec? What does each test?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

| Tool | Type | What it tests |
|---|---|---|
| **Terratest** | Integration test (Go) | Deploys real infrastructure, runs assertions, tears down. Tests that resources are actually created correctly. |
| **terraform test** | Unit/integration test (native HCL) | Runs `plan` or `apply` against mock or real providers, asserts on output values and resource attributes. Built into Terraform 1.6+. |
| **checkov** | Static analysis (Python) | Scans HCL for security misconfigurations (e.g., S3 bucket public access, unencrypted EBS). No deployment needed. |
| **tfsec** | Static analysis (Go) | Similar to checkov — scans for security issues in HCL. Faster, integrates well with CI. |

**How to think through this:**
1. Static analysis (checkov, tfsec) is fast and cheap — run on every PR.
2. `terraform test` is the new standard for unit-style tests without needing Go knowledge.
3. Terratest is powerful but slow and costly — reserve for critical modules that touch production-like infra.

**Key takeaway:** Layer your testing: static analysis in CI, `terraform test` for module logic, Terratest for full end-to-end integration on critical paths.

</details>

📖 **Theory:** [testing-terraform](./09_best_practices/code_organization.md#code-organization--structuring-terraform-projects-for-maintainability)


---

### Q75 · [Thinking] · `terraform-cdk`

> **What is CDK for Terraform (CDKTF)? How does it differ from writing HCL? When would you choose it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**CDKTF (Cloud Development Kit for Terraform)** lets you write Terraform infrastructure using general-purpose programming languages (TypeScript, Python, Go, Java, C#) instead of HCL. Under the hood it synthesizes HCL JSON that Terraform executes.

```python
# Python CDKTF example
from cdktf_cdktf_provider_aws.s3_bucket import S3Bucket

bucket = S3Bucket(self, "my-bucket", bucket="my-app-bucket")
```

**Differences from HCL:**

| | HCL | CDKTF |
|---|---|---|
| Language | Declarative DSL | Imperative (Python, TS, etc.) |
| Loops | `for_each`, `count` | Native language loops |
| Abstractions | Modules | Classes, inheritance |
| Ecosystem | Terraform Registry | NPM, PyPI |
| Learning curve | Lower for ops | Lower for developers |

**When to choose CDKTF:**
- Your team is composed of software engineers comfortable with Python/TypeScript but not HCL.
- You need complex logic (dynamic resource counts based on API calls, inheritance patterns).
- You want to reuse existing OOP abstractions across infrastructure components.

**When to stick with HCL:**
- Your team is ops-focused and HCL is already the standard.
- Simplicity and readability matter more than programmatic power.

**Key takeaway:** CDKTF brings general-purpose programming power to Terraform infrastructure definition — choose it when your team's language skills align and logic complexity justifies it.

</details>

📖 **Theory:** [terraform-cdk](./01_introduction/terraform_vs_others.md#terraform-vs-other-iac-tools--choosing-the-right-wrench)


---

## 🔵 Tier 4 — Interview / Scenario

### Q76 · [Interview] · `explain-state-junior`

> **A junior engineer asks why Terraform needs a state file and why they shouldn't just delete it if something goes wrong. Explain.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Think of the state file as Terraform's memory. Without it, Terraform has no way to connect the code you wrote to the real infrastructure that exists in AWS. It's the mapping: "this `aws_instance.web` in my code corresponds to `i-0abc123def456` in us-east-1."

**Why you can't delete it:**
If you delete state, Terraform doesn't know those resources exist. On the next `terraform apply`, it will try to create everything from scratch — while the real resources are still running. You now have duplicate infrastructure, and the orphaned originals will never be cleaned up by Terraform because it has no record of them.

**What to do instead when something goes wrong:**
- If state is corrupted: restore from backup (S3 versioning, local `.backup` file).
- If a resource is stuck: use `terraform state rm` to remove just that resource from state.
- If a resource was created outside Terraform: use `terraform import` to bring it into state.

**How to think through this:**
1. State = the bridge between code and reality. Remove the bridge, and the two sides become disconnected.
2. The cloud provider has no concept of Terraform — it just has resources. State is how Terraform tracks what it owns.
3. Recovering from state problems is surgical (state commands), not a full delete.

**Key takeaway:** Never delete state — it is Terraform's source of truth for what it manages; losing it means losing control of existing infrastructure.

</details>

📖 **Theory:** [explain-state-junior](./05_state_management/state_file.md#the-terraform-state-file--terraforms-memory)


---

### Q77 · [Interview] · `compare-terraform-cloudformation`

> **Compare Terraform and CloudFormation for managing AWS infrastructure. When would you choose each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

| | Terraform | CloudFormation |
|---|---|---|
| **Provider** | HashiCorp (open source) | AWS (native) |
| **Multi-cloud** | Yes — AWS, GCP, Azure, and 3000+ providers | No — AWS only |
| **State** | External state file (S3 + DynamoDB) | Managed by AWS internally |
| **Drift detection** | `terraform plan` | Stack drift detection (limited) |
| **Language** | HCL | YAML / JSON |
| **Rollback** | Manual (no built-in auto-rollback) | Automatic rollback on failure |
| **AWS integration** | Excellent (via AWS provider) | Native — zero-day support for new services |
| **Community modules** | Massive (Terraform Registry) | Limited (CDK constructs via CloudFormation) |

**Choose Terraform when:**
- You manage infrastructure across multiple cloud providers.
- Your team prefers HCL and values the Terraform ecosystem.
- You need portability and community modules.

**Choose CloudFormation when:**
- You are AWS-only and want native integration with no external state to manage.
- You need guaranteed automatic rollback on stack failures.
- You need zero-day support for new AWS services (Terraform providers lag slightly).

**How to think through this:**
1. CloudFormation is a managed service — AWS handles state, rollback, and service integration automatically.
2. Terraform requires more operational setup (state backend, locking) but pays off with multi-cloud flexibility.

**Key takeaway:** Use Terraform for multi-cloud or when portability matters; use CloudFormation when AWS-native simplicity and automatic rollback are priorities.

</details>

📖 **Theory:** [compare-terraform-cloudformation](./01_introduction/terraform_vs_others.md#terraform-vs-other-iac-tools--choosing-the-right-wrench)


---

### Q78 · [Interview] · `explain-modules`

> **Explain Terraform modules to someone who has only used the root module. What problem do they solve?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Imagine you build an EC2 instance with a security group, an IAM role, and a CloudWatch alarm. You do this for your web app. Then you need to do the same for your API service. And your worker service. Without modules, you copy-paste all that code three times — and when you need to change the CloudWatch alarm threshold, you change it in three places and inevitably miss one.

A **module** is a folder of Terraform code with defined inputs (variables) and outputs. You call it like a function:

```hcl
module "web_server" {
  source        = "./modules/ec2-service"
  instance_type = "t3.medium"
  name          = "web"
}

module "api_server" {
  source        = "./modules/ec2-service"
  instance_type = "t3.small"
  name          = "api"
}
```

The module encapsulates the EC2 + security group + IAM + alarm pattern. Change it once, all callers get the update.

**Problems modules solve:**
1. **Reuse** — write the pattern once, call it many times.
2. **Encapsulation** — hide complexity behind a clean interface (inputs/outputs).
3. **Consistency** — enforces standards across teams (e.g., all EC2 instances must have a CloudWatch alarm).

**How to think through this:**
1. Root module = your main working directory. It's just a module that Terraform runs directly.
2. Child modules = reusable building blocks called from the root or other modules.
3. Public modules in the Terraform Registry are community-built modules you can call directly.

**Key takeaway:** Modules are reusable, encapsulated building blocks that eliminate code duplication and enforce consistent infrastructure patterns across your organization.

</details>

📖 **Theory:** [explain-modules](./06_modules/creating_modules.md#creating-terraform-modules--writing-reusable-infrastructure-code)


---

### Q79 · [Interview] · `compare-workspaces-directories`

> **Compare workspace-per-environment vs directory-per-environment. Which do you prefer and why?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Workspace-per-environment:**
- One set of code, multiple state files (one per workspace: `dev`, `staging`, `prod`).
- Switch environments with `terraform workspace select prod`.
- Use `terraform.workspace` in code to vary config.
- All environments must have identical resource structures.

**Directory-per-environment:**
- Separate folders: `environments/dev/`, `environments/staging/`, `environments/prod/`.
- Each directory has its own `terraform.tfvars` and may slightly differ in structure.
- No shared state between environments — completely isolated.

| | Workspaces | Directories |
|---|---|---|
| Code duplication | Low | Medium (mitigated by shared modules) |
| Isolation | Logical (same backend, different key) | Physical (separate state, separate config) |
| Structural drift | Not supported | Supported |
| Risk of cross-env mistakes | Higher (easy to be in wrong workspace) | Lower (explicit directory selection) |
| Best for | Simple, identical environments | Enterprise, regulated, or divergent environments |

**Preference:** Directory-per-environment is generally safer and more explicit for production workloads. The risk of accidentally applying to the wrong workspace is real; separate directories make the blast radius explicit. Workspaces are fine for dev/test environments where isolation requirements are lower.

**Key takeaway:** Directory-per-environment offers stronger isolation and supports structural divergence between environments; workspaces trade isolation for simplicity and work best when all environments are structurally identical.

</details>

📖 **Theory:** [compare-workspaces-directories](./07_workspaces/environments.md#strategy-1-workspaces)


---

### Q80 · [Interview] · `explain-plan-apply`

> **Explain the Terraform plan/apply workflow to a new team member. What could go wrong between plan and apply?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Think of `terraform plan` as Terraform reading your code, checking the current state of your infrastructure, and producing a diff — a precise list of what it will create, change, or destroy. Nothing changes in the real world during plan.

`terraform apply` executes that plan — it makes the actual API calls to create, update, or delete resources.

**The workflow:**
```
Write code → terraform plan → review diff → terraform apply → verify
```

**What can go wrong between plan and apply:**

1. **Infrastructure drift** — someone manually changes a resource after you planned. Your plan is now stale. Terraform may show unexpected diffs or fail with conflicts.
2. **Race conditions** — another engineer applies a change to the same state between your plan and apply. Terraform's state lock prevents concurrent applies but not the window between plan and apply.
3. **API rate limiting or quota errors** — plan succeeded but apply hits a service limit.
4. **IAM permission changes** — you had permission during plan but a policy was tightened before apply.
5. **Saved plan files go stale** — if you save a plan with `terraform plan -out=plan.tfplan` and apply it days later, reality may have changed.

**How to think through this:**
1. Always apply soon after planning in production — the longer the gap, the more drift risk.
2. Use saved plan files in CI/CD to ensure what was reviewed is exactly what gets applied.
3. Enable state locking to prevent concurrent applies but understand it doesn't prevent the plan-to-apply window problem.

**Key takeaway:** The window between `plan` and `apply` is a risk window — minimize it, and always review the plan diff carefully before confirming.

</details>

📖 **Theory:** [explain-plan-apply](./01_introduction/installation.md#installing-terraform--getting-your-workstation-ready)


---

### Q81 · [Design] · `scenario-state-corruption`

> **Your Terraform state file in S3 becomes corrupted after a failed apply. How do you recover?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Step 1 — Do not panic and do not apply again.** Running apply on corrupted state can create duplicate resources or cause unintended deletions.

**Step 2 — Restore from S3 versioning.**
S3 versioning should always be enabled on your state bucket. Navigate to the S3 console (or use CLI) and restore the previous version of the state file:
```bash
aws s3api list-object-versions \
  --bucket my-tf-state \
  --prefix myproject/terraform.tfstate

aws s3api get-object \
  --bucket my-tf-state \
  --key myproject/terraform.tfstate \
  --version-id <previous-version-id> \
  terraform.tfstate.restored
```

**Step 3 — Validate the restored state.**
```bash
terraform show terraform.tfstate.restored
```
Compare with known good resource list.

**Step 4 — Upload the restored state** (if using S3 backend, overwrite the current object with the restored version).

**Step 5 — Run `terraform plan`** to confirm state matches reality. Expect a clean plan.

**Step 6 — If no backup exists:** manually reconstruct state using `terraform import` for each resource. This is painful — it is why S3 versioning and DynamoDB locking are non-negotiable.

**Prevention checklist:**
- S3 versioning: enabled
- DynamoDB locking: enabled
- State backup before any risky operation: `terraform state pull > backup.tfstate`

**Key takeaway:** S3 versioning is your primary recovery mechanism for corrupted state — enable it from day one and restore the previous version rather than trying to fix corruption manually.

</details>

📖 **Theory:** [scenario-state-corruption](./05_state_management/state_commands.md#terraform-state-commands--inspecting-and-manipulating-state)


---

### Q82 · [Design] · `scenario-team-conflict`

> **Two engineers run `terraform apply` at the same time without state locking. What can happen? How do you prevent this?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**What can happen without state locking:**

1. **State corruption** — both engineers read the same state, make changes in parallel, and write back. The second write overwrites the first, losing the changes from the first apply. Resources exist in AWS but not in state.
2. **Duplicate resources** — both engineers try to create the same resource (e.g., a security group). One succeeds, one fails — or worse, both partially succeed leaving orphaned resources.
3. **Inconsistent state** — one apply's changes to state are overwritten, leaving state out of sync with reality. Future plans will show phantom diffs.
4. **Cascading failures** — resources that depend on each other get created in the wrong order across two concurrent applies.

**Prevention — enable DynamoDB state locking:**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

The DynamoDB table must have a primary key named `LockID` (String). Terraform acquires a lock before reading state and releases it after writing.

**Additional process controls:**
- Use CI/CD pipelines as the only apply path — no local applies to production.
- Require PR approval before pipeline runs apply.
- Use Atlantis or Terraform Cloud for automated, serialized apply workflows.

**Key takeaway:** DynamoDB state locking serializes Terraform operations — always enable it on shared state backends and eliminate local applies to production environments.

</details>

📖 **Theory:** [scenario-team-conflict](./05_state_management/remote_state.md#remote-state--sharing-terraform-state-across-teams)


---

### Q83 · [Design] · `scenario-large-codebase`

> **Your single Terraform repo has grown to 500 resources. `terraform plan` takes 10 minutes. How do you refactor it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The root problem is that every `terraform plan` refreshes all 500 resources against the live cloud provider — even when you are only changing one service's configuration. The solution is decomposition.

**Refactoring strategy:**

**1. Split into independent state boundaries (separate root modules):**
```
infrastructure/
├── networking/        # VPCs, subnets, route tables
├── security/          # IAM roles, KMS keys, security groups
├── data/              # RDS, ElastiCache, S3
├── compute/           # ECS, EC2 ASGs
└── platform/          # EKS, shared services
```

Each directory has its own state file. A plan in `compute/` only refreshes compute resources.

**2. Use `terraform_remote_state` or SSM for cross-boundary data sharing.**

**3. Use `-target` for emergency speed** (not for regular workflow):
```bash
terraform plan -target=aws_ecs_service.api
```

**4. Enable provider-level parallelism** (default is 10):
```bash
terraform apply -parallelism=20
```

**5. Use `terraform plan -refresh=false`** if state drift is not a concern and you just want a fast diff against state only.

**How to think through this:**
1. Start by drawing ownership boundaries: which team owns which resources?
2. Minimize cross-boundary dependencies — they add coupling.
3. Migrate state with `terraform state mv` to avoid destroying resources during refactor.

**Key takeaway:** Split large Terraform codebases by ownership or lifecycle boundary into separate state files — this reduces plan scope and enables parallel team workflows.

</details>

📖 **Theory:** [scenario-large-codebase](./09_best_practices/code_organization.md#folder-structure-for-large-projects)


---

### Q84 · [Design] · `scenario-migrate-existing`

> **You need to manage 50 existing AWS resources that were created manually. How do you import them into Terraform? What are the challenges?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**The import workflow:**

**Step 1 — Write the resource block in HCL** for each resource (code must exist before import):
```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-existing-bucket"
}
```

**Step 2 — Run `terraform import`** to map the real resource to the state entry:
```bash
terraform import aws_s3_bucket.data my-existing-bucket
```

**Step 3 — Run `terraform plan`** to see the diff between your HCL and the imported state. You will likely see many attributes your HCL does not specify yet.

**Step 4 — Reconcile** — add missing attributes to your HCL until `terraform plan` shows no changes.

**Terraform 1.5+ import blocks (declarative):**
```hcl
import {
  to = aws_s3_bucket.data
  id = "my-existing-bucket"
}
```
Run `terraform plan -generate-config-out=generated.tf` to auto-generate HCL from the real resource.

**Challenges:**
1. **Scale** — 50 resources = 50 import commands + 50 HCL blocks to write and reconcile.
2. **Attribute drift** — real resources may have settings applied via console that are hard to express in HCL.
3. **Unsupported resources** — not all AWS resources are importable via the Terraform AWS provider.
4. **Dependencies** — importing resource B before resource A (which B depends on) requires careful ordering.
5. **Destructive defaults** — if your HCL is wrong, `terraform apply` can change or delete things.

**Key takeaway:** Use `terraform import` (or declarative import blocks in 1.5+) to bring existing resources under Terraform management, but expect significant time reconciling HCL attributes to achieve a clean plan.

</details>

📖 **Theory:** [scenario-migrate-existing](./05_state_management/state_commands.md#terraform-state-commands--inspecting-and-manipulating-state)


---

### Q85 · [Design] · `scenario-destroy-protection`

> **A critical RDS instance was accidentally destroyed by `terraform destroy`. How would you have prevented this? What do you do now?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Prevention — what should have been in place:**

1. **`prevent_destroy` lifecycle rule:**
```hcl
resource "aws_db_instance" "prod" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```
Terraform will error and refuse to destroy this resource, even with `terraform destroy`.

2. **RDS deletion protection:**
```hcl
deletion_protection = true
```
This is an AWS-level safeguard — even if Terraform tries to delete the instance, AWS will reject the API call.

3. **Automated RDS snapshots** — enabled by default in RDS, but verify `backup_retention_period > 0`.

4. **Restrict `terraform destroy`** — use IAM or pipeline controls so only specific roles can destroy production resources.

5. **Require `target` on destroys** — process control: never run bare `terraform destroy` in production.

**Recovery steps now:**

1. Check if RDS automated snapshots exist:
```bash
aws rds describe-db-snapshots --db-instance-identifier my-prod-db
```
2. Restore from the most recent snapshot to a new instance.
3. Update your application's DB endpoint to point to the restored instance.
4. If no automated snapshots: check for manual snapshots, AWS Backup, or read replica.
5. Add `prevent_destroy` and `deletion_protection = true` immediately after recovery.

**Key takeaway:** Always combine `prevent_destroy` in Terraform and `deletion_protection = true` at the AWS level for stateful production resources — defense in depth.

</details>

📖 **Theory:** [scenario-destroy-protection](./03_providers_resources/resources.md#destroy-a-specific-resource)


---

### Q86 · [Interview] · `compare-provisioners-cloud-init`

> **Compare Terraform provisioners vs cloud-init for bootstrapping EC2 instances. Which approach is more reliable?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Terraform provisioners** (`remote-exec`, `local-exec`, `file`) run scripts during Terraform's apply phase, over SSH or WinRM, or locally:
```hcl
provisioner "remote-exec" {
  inline = ["sudo apt-get update", "sudo apt-get install -y nginx"]
}
```

**cloud-init** is a standard Linux bootstrapping system. You pass a script via `user_data` in the EC2 resource:
```hcl
resource "aws_instance" "web" {
  user_data = file("bootstrap.sh")
}
```
The instance runs cloud-init on first boot, independently of Terraform.

| | Provisioners | cloud-init |
|---|---|---|
| Execution | During `terraform apply` | On instance boot (independent) |
| Failure behavior | Marks resource as tainted, apply fails | Failure is logged on instance; Terraform doesn't know |
| SSH required | Yes (remote-exec) | No |
| Network dependency | Must be reachable by Terraform runner | Instance bootstraps itself |
| Idempotency | Not guaranteed | Can be designed to be idempotent |
| HashiCorp recommendation | Last resort | Preferred |

**cloud-init is more reliable** because:
1. It doesn't require Terraform to maintain an SSH connection.
2. Failures don't block the Terraform apply (though this can also be a downside if you need to detect failures).
3. It works in airgapped VPCs where Terraform cannot reach the instance.
4. It is the cloud-native standard — supported by all major Linux AMIs.

**Key takeaway:** Prefer cloud-init (via `user_data`) over Terraform provisioners for EC2 bootstrapping — it is more reliable, doesn't require network access from the Terraform runner, and aligns with cloud-native patterns.

</details>

📖 **Theory:** [compare-provisioners-cloud-init](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q87 · [Interview] · `compare-cdktf-hcl`

> **What are the advantages and disadvantages of CDKTF vs HCL for a team of Python engineers?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Advantages of CDKTF for Python engineers:**

1. **Familiar language** — write infrastructure in Python, no need to learn HCL syntax.
2. **Native loops and conditionals** — Python's `for` loops, list comprehensions, and `if` statements replace `for_each`, `count`, and ternary expressions.
3. **OOP abstractions** — classes and inheritance enable reusable infrastructure patterns beyond what HCL modules offer.
4. **IDE support** — autocompletion, type checking, and refactoring tools work natively.
5. **Testing** — use pytest to test infrastructure logic without deploying anything.
6. **Dynamic configuration** — call APIs, read files, or compute values at synthesis time using Python.

**Disadvantages of CDKTF:**

1. **Additional abstraction layer** — bugs can live in the synthesis step (Python → HCL JSON) before Terraform even runs.
2. **Debugging complexity** — when something goes wrong, you must trace through synthesized JSON, not your Python code.
3. **Ecosystem mismatch** — Terraform Registry modules are HCL; using them from CDKTF requires extra wrappers.
4. **Team knowledge split** — if ops engineers join the team, they need to learn CDKTF on top of Terraform concepts.
5. **Maturity** — CDKTF is newer than HCL; some edge cases and provider features lag.
6. **Synthesis step** — adds latency and a build step to the workflow.

**How to think through this:**
1. For a pure Python team building complex, dynamic infrastructure, CDKTF reduces the cognitive load of HCL.
2. For simple, mostly static infrastructure, HCL is more readable and requires less toolchain.

**Key takeaway:** CDKTF is a strong fit for Python teams with complex infrastructure logic, but adds toolchain complexity and a synthesis layer that can obscure debugging.

</details>

📖 **Theory:** [compare-cdktf-hcl](./01_introduction/terraform_vs_others.md#terraform-vs-other-iac-tools--choosing-the-right-wrench)


---

### Q88 · [Design] · `scenario-multi-team`

> **Design a Terraform project structure for an organization with 5 teams, each managing their own AWS account, with shared networking managed centrally.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Structure:**
```
infrastructure/
├── modules/                     # Shared modules (owned by platform team)
│   ├── vpc/
│   ├── ecs-service/
│   └── rds-instance/
│
├── shared/                      # Central networking (platform team owns, single state)
│   ├── main.tf                  # Transit Gateway, shared VPCs, DNS
│   ├── outputs.tf               # Exports subnet IDs, TGW ID, etc.
│   └── backend.tf               # s3://central-state/shared/terraform.tfstate
│
└── teams/
    ├── team-alpha/
    │   ├── dev/
    │   │   ├── main.tf
    │   │   └── backend.tf       # s3://team-alpha-state/dev/terraform.tfstate
    │   └── prod/
    │       ├── main.tf
    │       └── backend.tf       # s3://team-alpha-state/prod/terraform.tfstate
    ├── team-beta/
    │   └── ...
    └── ...
```

**Key design decisions:**

1. **Separate state per team per environment** — blast radius isolation. Team Alpha cannot corrupt Team Beta's state.
2. **Shared module registry** — platform team maintains `modules/` and teams consume via versioned Git refs or a private registry.
3. **Central networking as its own root module** — only the platform team applies changes here. Teams consume outputs via `terraform_remote_state` or SSM parameters.
4. **Separate AWS accounts per team** — IAM isolation. Each team's CI/CD role only has access to their account.
5. **Cross-account networking** — Transit Gateway or VPC peering managed by the shared module, IDs exported for team consumption.

**Governance layer:**
- Teams must use the shared module for VPC creation (enforced via Sentinel or OPA policy).
- Mandatory tags enforced via `default_tags` in the provider block.
- All applies go through CI/CD pipelines — no local applies to production.

**Key takeaway:** Separate state files per team and environment provide blast radius isolation; shared networking as a dedicated root module with exported outputs enables central governance without blocking team autonomy.

</details>

📖 **Theory:** [scenario-multi-team](./09_best_practices/code_organization.md#code-organization--structuring-terraform-projects-for-maintainability)


---

### Q89 · [Design] · `scenario-secret-rotation`

> **A database password is stored in Terraform state. Security asks you to remove it. Walk through how you migrate to using Secrets Manager without recreating the database.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**The problem:** `aws_db_instance` has `password` as a plain-text attribute stored in state. Security wants it in Secrets Manager.

**Migration plan — zero recreation:**

**Step 1 — Store the current password in Secrets Manager (outside Terraform or via a separate apply):**
```hcl
resource "aws_secretsmanager_secret" "db_password" {
  name = "prod/myapp/db-password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password  # Supply once, then remove
}
```

**Step 2 — Update the RDS resource to use `manage_master_user_password`** (AWS-native Secrets Manager integration, available in newer provider versions):
```hcl
resource "aws_db_instance" "prod" {
  # Remove: password = var.db_password
  manage_master_user_password = true
  # ...
}
```

This tells RDS to rotate and manage the password in Secrets Manager automatically. No `password` attribute = no secret in state.

**Step 3 — Alternatively, use `ignore_changes` if you manage the password externally:**
```hcl
lifecycle {
  ignore_changes = [password]
}
```
Then rotate the password via AWS CLI or console — Terraform will not revert it.

**Step 4 — Remove the secret from existing state** (if it was previously stored):
```bash
terraform state list  # find the resource address
# The secret is already in state — just ensure the code no longer writes it
```

**Step 5 — Update application code** to read from Secrets Manager instead of an environment variable.

**Step 6 — Redact the old state value** — note that previous state file versions in S3 still contain the password. Apply S3 Object Lock or delete old versions after confirming the migration is stable.

**Key takeaway:** Use `manage_master_user_password = true` or `ignore_changes = [password]` to remove database passwords from Terraform state without recreating the database, then handle S3 state version cleanup.

</details>

📖 **Theory:** [scenario-secret-rotation](./09_best_practices/security.md#variable-files-that-might-contain-secrets)


---

### Q90 · [Design] · `scenario-compliance`

> **Your security team requires that all AWS resources created by Terraform have specific mandatory tags. How do you enforce this at scale?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Three layers of enforcement:**

**Layer 1 — Provider default tags (DRY, automatic):**
```hcl
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = var.environment
      Team        = var.team
      ManagedBy   = "terraform"
      CostCenter  = var.cost_center
    }
  }
}
```
All resources created by this provider automatically receive these tags. No per-resource tagging needed.

**Layer 2 — Terraform variable validation (shift-left):**
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

**Layer 3 — Static analysis in CI (policy as code):**

Using **checkov**:
```bash
checkov -d . --check CKV_AWS_RESOURCE_TAGGING
```

Using **OPA/Sentinel** (Terraform Cloud/Enterprise):
```rego
# Deny any resource missing mandatory tags
deny[msg] {
  resource := input.resource_changes[_]
  required_tags := {"Environment", "Team", "CostCenter"}
  missing := required_tags - {tag | resource.change.after.tags[tag]}
  count(missing) > 0
  msg := sprintf("Resource %v missing tags: %v", [resource.address, missing])
}
```

**Layer 4 — AWS Config rules** as a backstop — detect untagged resources that slipped through.

**How to think through this:**
1. `default_tags` handles the majority of cases automatically — it's the 80% solution with no per-resource effort.
2. CI checks (checkov, OPA) catch issues before they reach production.
3. AWS Config catches anything that bypassed Terraform.

**Key takeaway:** Combine provider `default_tags` for automatic tag propagation with OPA/Sentinel or checkov in CI to enforce mandatory tagging before any resource reaches production.

</details>

📖 **Theory:** [scenario-compliance](./09_best_practices/security.md#security-best-practices--keeping-terraform-safe)


---

## 🔴 Tier 5 — Critical Thinking

### Q91 · [Logical] · `predict-plan-output`

> **A resource was created with `count = 2`. You change it to `count = 1`. What does `terraform plan` show and what happens to the remaining resource?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```hcl
# Before
resource "aws_instance" "web" {
  count = 2
  ami   = "ami-0abc123"
  instance_type = "t3.micro"
}

# After
resource "aws_instance" "web" {
  count = 1
  ami   = "ami-0abc123"
  instance_type = "t3.micro"
}
```

**Plan output:**
```
  # aws_instance.web[1] will be destroyed
  - resource "aws_instance" "web" {
      - id = "i-0abc123def456"
      ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.
```

**What happens:**
- `aws_instance.web[0]` remains unchanged — Terraform sees it is still declared and matches state.
- `aws_instance.web[1]` is **destroyed** — it is no longer declared in the configuration.

**Critical nuance — count always destroys from the highest index:**
If you had `count = 5` and reduced to `count = 3`, indexes `[3]` and `[4]` are destroyed. This is why `for_each` is preferred over `count` for resources where identity matters — with `for_each`, you control which key gets removed.

**How to think through this:**
1. Terraform computes: "how many declared? how many in state?" — the difference is destroyed.
2. It always removes from the end (highest index).
3. If `[1]` was your important server and `[0]` was your test, you cannot choose which to keep with `count`.

**Key takeaway:** Reducing `count` destroys resources from the highest index downward — use `for_each` when the identity of individual resources matters.

</details>

📖 **Theory:** [predict-plan-output](./05_state_management/state_commands.md#terraform-state-commands--inspecting-and-manipulating-state)


---

### Q92 · [Logical] · `predict-for-each-key`

> **You have `for_each = toset(["a", "b", "c"])`. You remove "b" from the set. What does the plan show for the "b" resource?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```hcl
# Before
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["a", "b", "c"])
  bucket   = "my-bucket-${each.key}"
}

# After
resource "aws_s3_bucket" "buckets" {
  for_each = toset(["a", "c"])
  bucket   = "my-bucket-${each.key}"
}
```

**Plan output:**
```
  # aws_s3_bucket.buckets["b"] will be destroyed
  - resource "aws_s3_bucket" "buckets" {
      - id     = "my-bucket-b"
      - bucket = "my-bucket-b"
      ...
    }

Plan: 0 to add, 0 to change, 1 to destroy.
```

**What happens:**
- `buckets["a"]` and `buckets["c"]` are unchanged.
- `buckets["b"]` is **destroyed** because the key "b" no longer exists in the set.

**Key difference from count:**
With `for_each`, you explicitly control which resource is removed by removing its key. With `count`, removing index 1 from `[0,1,2]` always removes the highest index. With `for_each = toset(["a","c"])` you remove precisely "b" — `"a"` and `"c"` are unaffected regardless of their position.

**How to think through this:**
1. `for_each` tracks resources by key identity, not position.
2. Removing a key from the set = declaring that resource no longer should exist.
3. The remaining resources are identified by their keys, not re-indexed.

**Key takeaway:** With `for_each`, removing a key from the set destroys exactly that resource by name — preserving all others regardless of their position in the collection.

</details>

📖 **Theory:** [predict-for-each-key](./03_providers_resources/resources.md#2-for_each--create-copies-from-a-map-or-set)


---

### Q93 · [Logical] · `predict-depends-on`

> **Two resources have no data dependency but you add `depends_on`. Does this change the order of creation? What does it change?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

```hcl
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"
  # ...
}

resource "aws_lambda_function" "processor" {
  function_name = "processor"
  role          = "arn:aws:iam::123456789:role/lambda-exec-role"  # hardcoded, no reference
  depends_on    = [aws_iam_role.lambda_exec]
}
```

**Does it change creation order? Yes.**
Without `depends_on` and no attribute reference, Terraform may create both resources in parallel. With `depends_on`, `aws_lambda_function.processor` will not start creating until `aws_iam_role.lambda_exec` is fully created.

**What exactly changes:**
1. **Parallelism** — the dependent resource waits, reducing concurrency.
2. **Destruction order** — `depends_on` also affects destroy: the dependent resource is destroyed first.
3. **Plan refresh** — changes to the depended-upon resource will cause a more thorough plan evaluation of the dependent resource.

**What it does NOT change:**
- The final state of either resource.
- Whether the resources are created at all.
- The configuration attributes of either resource.

**When `depends_on` is justified without attribute reference:**
- IAM policy propagation delay (Lambda needs the role to be fully propagated in IAM before it can be assumed).
- API Gateway deployment depends on all routes being configured first.
- A null_resource that runs a script that must run after a database is ready.

**Key takeaway:** `depends_on` enforces ordering and disables parallelism between resources — use it only when a non-obvious operational dependency exists that Terraform cannot detect from attribute references alone.

</details>

📖 **Theory:** [predict-depends-on](./03_providers_resources/resources.md#3-depends_on--explicit-dependencies)


---

### Q94 · [Debug] · `debug-state-lock`

> **`terraform plan` hangs with "Acquiring state lock..." and never completes. What happened and how do you fix it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**What happened:**
A previous `terraform` operation (apply, plan, or even a crashed process) acquired a lock in DynamoDB and never released it. The lock entry is a row in the DynamoDB table with the `LockID` key. Until it is deleted, all subsequent operations wait indefinitely.

Common causes:
- A `terraform apply` was killed mid-run (Ctrl+C, CI job timeout, network drop).
- A CI runner was terminated while holding the lock.
- A local apply crashed due to a system error.

**How to fix:**

**Step 1 — Identify the lock.**
Terraform will eventually print the lock ID. Or check DynamoDB directly:
```bash
aws dynamodb scan --table-name terraform-state-lock
```

**Step 2 — Force-unlock using the lock ID:**
```bash
terraform force-unlock <LOCK_ID>
```

**Step 3 — Verify the lock is cleared:**
```bash
aws dynamodb scan --table-name terraform-state-lock
# Should return empty or no matching entry
```

**Step 4 — Investigate what the interrupted operation did** before re-running:
```bash
terraform plan
```
Look for partially created resources or a tainted resource. Fix or untaint before applying.

**Safety check before force-unlocking:**
Confirm that no other `terraform apply` is actively running. Force-unlocking while an apply is in progress will allow concurrent state writes — which is exactly what locking prevents.

**Key takeaway:** A stuck state lock means a previous operation died while holding the DynamoDB lock — use `terraform force-unlock <LOCK_ID>` after confirming no live operation is running.

</details>

📖 **Theory:** [debug-state-lock](./05_state_management/remote_state.md#block-all-public-access-to-state)


---

### Q95 · [Debug] · `debug-provider-version`

> **After running `terraform init` on a new machine, `terraform plan` shows different changes than expected. The colleague who last ran it had a different provider version. What is the fix?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Root cause:**
The `.terraform.lock.hcl` file (the dependency lock file) was either not committed to version control, or the version constraint in `required_providers` is too loose (e.g., `~> 4.0` matches both `4.5.0` and `4.67.0`). Different provider versions can have different default behaviors, resource schema changes, or bug fixes that cause different plan outputs.

**The fix:**

**Step 1 — Commit `.terraform.lock.hcl` to version control.** This file pins exact provider versions and checksums:
```
# .terraform.lock.hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.31.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:abc123...",
  ]
}
```

**Step 2 — Use `terraform init` without `-upgrade`** on existing checkouts. With the lock file present, init installs the exact pinned version regardless of what is latest.

**Step 3 — If you need to match your colleague's exact version right now:**
```bash
terraform init -upgrade  # not recommended for production
```
Or edit the lock file to match the version your colleague used, then run `terraform init`.

**Step 4 — Tighten version constraints** to prevent surprise upgrades:
```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "= 5.31.0"  # exact pin — or "~> 5.31" for patch-only
  }
}
```

**Key takeaway:** Always commit `.terraform.lock.hcl` to version control — it is the provider equivalent of a `requirements.txt` lockfile and ensures every engineer and CI job uses identical provider versions.

</details>

📖 **Theory:** [debug-provider-version](./03_providers_resources/providers.md#terraform-providers--plugins-that-talk-to-the-world)


---

### Q96 · [Debug] · `debug-cyclic-dependency`

> **Terraform errors with "Cycle: resource_a.main, resource_b.main". What is a cyclic dependency and how do you break it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**What is a cyclic dependency:**
A cyclic dependency occurs when resource A depends on resource B, and resource B also depends on resource A — creating a circular reference in the dependency graph. Terraform builds a DAG (Directed Acyclic Graph) and cannot determine which resource to create first.

```hcl
# Cycle example
resource "aws_security_group" "app" {
  vpc_id = aws_vpc.main.id
  ingress {
    security_groups = [aws_security_group.db.id]  # depends on db
  }
}

resource "aws_security_group" "db" {
  vpc_id = aws_vpc.main.id
  ingress {
    security_groups = [aws_security_group.app.id]  # depends on app — CYCLE
  }
}
```

**How to break it:**

**Option 1 — Use `aws_security_group_rule` resources** to decouple rule creation from group creation:
```hcl
resource "aws_security_group" "app" {
  vpc_id = aws_vpc.main.id
  # No inline ingress rules
}

resource "aws_security_group" "db" {
  vpc_id = aws_vpc.main.id
  # No inline ingress rules
}

resource "aws_security_group_rule" "app_from_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.app.id
}
```

**Option 2 — Redesign the dependency** — ask whether the circular reference indicates a design flaw. Often it does.

**Diagnosis:**
```bash
terraform graph | dot -Tsvg > graph.svg
```
Visualize the graph to find cycles.

**Key takeaway:** Cyclic dependencies indicate that resource creation order is logically impossible — break them by decoupling rule/policy resources from the base resources they reference.

</details>

📖 **Theory:** [debug-cyclic-dependency](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q97 · [Design] · `design-zero-downtime`

> **How do you update a Launch Template used by an Auto Scaling Group with zero downtime in Terraform? What lifecycle argument helps?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**The problem:**
By default, when you update a Launch Template, Terraform updates the resource in place (or destroys and recreates it). If the ASG is using the Launch Template, the old instances are not automatically replaced. If Terraform destroys the Launch Template before creating the new one, there is a gap.

**Solution — `create_before_destroy`:**

```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = var.ami_id
  instance_type = "t3.medium"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  min_size         = 2
  max_size         = 10
  desired_capacity = 2

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}
```

**How `create_before_destroy` works:**
Normally: destroy old → create new (gap exists).
With flag: create new → verify → destroy old (no gap).

**`instance_refresh` for ASG rolling replacement:**
When the Launch Template changes, `instance_refresh` triggers a rolling replacement of instances in the ASG — new instances launch with the new template before old ones are terminated.

**How to think through this:**
1. `create_before_destroy` ensures the new Launch Template version exists before the old one is removed.
2. `instance_refresh` ensures ASG instances are replaced gradually, respecting `min_healthy_percentage`.
3. Together they provide zero-downtime AMI or instance type changes.

**Key takeaway:** Use `create_before_destroy` on Launch Templates and `instance_refresh` on the ASG to achieve zero-downtime instance fleet updates with automatic rolling replacement.

</details>

📖 **Theory:** [design-zero-downtime](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q98 · [Design] · `design-conditional-resources`

> **How do you conditionally create a resource in Terraform? Show both `count` and `for_each` approaches. Which is cleaner?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**Using `count` (the classic approach):**
```hcl
variable "enable_bastion" {
  type    = bool
  default = false
}

resource "aws_instance" "bastion" {
  count         = var.enable_bastion ? 1 : 0
  ami           = "ami-0abc123"
  instance_type = "t3.micro"
}

# Reference the resource safely:
output "bastion_ip" {
  value = var.enable_bastion ? aws_instance.bastion[0].public_ip : null
}
```

**Using `for_each` (alternative):**
```hcl
resource "aws_instance" "bastion" {
  for_each      = var.enable_bastion ? toset(["bastion"]) : toset([])
  ami           = "ami-0abc123"
  instance_type = "t3.micro"
}

output "bastion_ip" {
  value = var.enable_bastion ? aws_instance.bastion["bastion"].public_ip : null
}
```

**Which is cleaner:**
For a simple on/off conditional on a single resource, **`count = 0/1` is cleaner** — it is idiomatic, widely understood, and less verbose. The `for_each` approach adds unnecessary complexity for binary presence/absence.

`for_each` becomes cleaner when:
- You are creating 0 or N resources based on a map (not just on/off).
- The resource has a meaningful identity beyond just "does it exist."

**How to think through this:**
1. `count = var.enabled ? 1 : 0` is the Terraform community convention for conditional resources.
2. The awkward part of `count` is referencing `resource[0]` — always check `length > 0` or use a ternary.
3. `for_each` with an empty set is semantically equivalent but less conventional for simple toggles.

**Key takeaway:** Use `count = condition ? 1 : 0` for simple conditional resource creation — it is the idiomatic Terraform pattern; reserve `for_each` for dynamic multi-instance scenarios.

</details>

📖 **Theory:** [design-conditional-resources](./03_providers_resources/resources.md#terraform-resources--creating-and-managing-infrastructure)


---

### Q99 · [Critical] · `edge-case-null-value`

> **A Terraform variable has type `string` and no default. You pass it as `null` via CLI. What happens? How do you write a validation block that rejects null?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**What happens when you pass `null`:**
```bash
terraform apply -var="db_name=null"
```
This passes the string literal `"null"` — not a null value. The variable will equal the four-character string `"null"`.

To pass an actual null:
```bash
TF_VAR_db_name=""   # passes empty string, not null
```
Or in a `terraform.tfvars`:
```hcl
db_name = null
```

When a required variable (no default) receives `null` from a `.tfvars`, Terraform treats it as "not set" — which causes an error: "No value for required variable."

If the variable has `default = null`, then `null` is valid and the variable's value will be `null`. Resources that receive `null` for an optional attribute will omit that attribute from the API call.

**Validation block that rejects null:**
```hcl
variable "db_name" {
  type = string

  validation {
    condition     = var.db_name != null && length(var.db_name) > 0
    error_message = "db_name must not be null or empty."
  }
}
```

Note: validation blocks run after the value is set. If the variable is required (no default), Terraform errors before reaching validation. Add `default = null` to enable validation of null:
```hcl
variable "db_name" {
  type    = string
  default = null

  validation {
    condition     = var.db_name != null && length(var.db_name) > 0
    error_message = "db_name must be provided and non-empty."
  }
}
```

**How to think through this:**
1. `-var="x=null"` passes the string `"null"`, not a null value — a common footgun.
2. Null in `.tfvars` is an actual null value in HCL.
3. To validate against null, the variable must allow null first (via `default = null` or `type = string`), then the validation condition checks it.

**Key takeaway:** Passing `null` via CLI `-var` flag sends the literal string "null" — actual null requires a `.tfvars` file; validate against null by checking `var.name != null` in a validation block.

</details>

📖 **Theory:** [edge-case-null-value](./04_variables_outputs/variables.md#how-to-provide-variable-values)


---

### Q100 · [Critical] · `edge-case-destroy-create`

> **A change to a resource requires destroy-then-recreate (`-/+` in plan). The resource is a database in production. How do you prevent the destroy from happening while still applying the rest of the changes?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**

**The situation:**
```
  # aws_db_instance.prod must be replaced
-/+ resource "aws_db_instance" "prod" {
      ~ identifier = "prod-db" -> "prod-db-v2"  # forces replacement
    }
```

**Option 1 — `prevent_destroy` to block the apply entirely (safest short term):**
```hcl
resource "aws_db_instance" "prod" {
  lifecycle {
    prevent_destroy = true
  }
}
```
Terraform will error on the plan and refuse to proceed. This gives you time to rethink.

**Option 2 — `ignore_changes` to prevent Terraform from acting on the diff:**
```hcl
resource "aws_db_instance" "prod" {
  lifecycle {
    ignore_changes = [identifier]
  }
}
```
Terraform will not detect changes to `identifier` and will not plan a replacement. Use when the attribute change was unintentional.

**Option 3 — `create_before_destroy` to make replacement safer:**
```hcl
resource "aws_db_instance" "prod" {
  lifecycle {
    create_before_destroy = true
  }
}
```
New database is created first, then old one is destroyed. Still causes a new DB — only appropriate if you have a migration plan.

**Option 4 — `-target` to apply everything except the database:**
```bash
terraform apply -target=aws_ecs_service.app -target=aws_security_group.web
```
Apply all other changes now, skip the database until you have a blue/green migration plan. Note: `-target` is a tactical tool, not a permanent strategy.

**Option 5 — Redesign to avoid the force-replace attribute change** (root cause fix):
If `identifier` is what triggers replacement, and the change was accidental, revert it in code. If intentional, plan a proper blue/green database migration outside of Terraform's destroy cycle.

**How to think through this:**
1. First ask: why is Terraform planning to destroy it? Is this change intentional?
2. If unintentional: `ignore_changes` or revert the code change.
3. If intentional but dangerous: `prevent_destroy` blocks it; `-target` defers it; `create_before_destroy` makes it slightly safer.
4. For production databases, the correct answer is almost always a planned blue/green migration — not relying on Terraform's `-/+` cycle.

**Key takeaway:** Use `prevent_destroy` to block accidental database destruction, `ignore_changes` for unintentional drift, and `-target` to defer a risky change — but treat any `-/+` on a production database as a signal to plan a proper migration rather than accepting the destroy.

</details>

📖 **Theory:** [edge-case-destroy-create](./03_providers_resources/resources.md#1-count--create-multiple-copies)
