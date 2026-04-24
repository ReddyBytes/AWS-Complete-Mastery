# Dynamic Blocks, null_resource, and Advanced HCL Patterns

## The Spreadsheet Formula Analogy

Imagine building a spreadsheet to track employees. You could type each person's name, department, and salary into individual cells — a separate row for every person. But when you have 500 employees and the company changes the health insurance rate, you edit 500 cells.

Or you write a formula once. The formula takes a list of data and generates all the rows automatically. Change one thing, everything updates.

That is exactly why **dynamic blocks** exist in Terraform. Without them, a security group with 10 inbound rules requires 10 identical `ingress {}` blocks, each hardcoded. With dynamic blocks, you write the block shape once and Terraform generates all 10 from a list.

---

## Dynamic Block Syntax

A **dynamic block** is a special construct that generates repeated nested blocks from a collection. The basic structure:

```hcl
resource "some_resource" "example" {
  # Static arguments
  name = "my-resource"

  # Dynamic block
  dynamic "block_name" {
    for_each = var.my_list_or_map    # ← iterate over this collection

    content {
      # Use each.value to access the current element
      argument = each.value
      key_arg  = each.key     # ← if iterating a map
    }
  }
}
```

The keyword `dynamic` is followed by the name of the nested block you want to repeat. Terraform generates one instance of `content {}` for every element in `for_each`.

### each.key and each.value

- When `for_each` is a **list**: `each.key` is the index (0, 1, 2...), `each.value` is the list element
- When `for_each` is a **map**: `each.key` is the map key, `each.value` is the map value

```hcl
variable "ports" {
  default = [80, 443, 8080]
}

dynamic "ingress" {
  for_each = var.ports          # ← list

  content {
    from_port = each.value      # ← the port number (80, 443, 8080)
    to_port   = each.value
    protocol  = "tcp"
  }
}
```

### The iterator argument

By default, inside `content {}` you refer to the current element as `each`. If the block name and `each` feel ambiguous — especially with nested dynamics — you can rename it with `iterator`:

```hcl
dynamic "ingress" {
  for_each = var.ports
  iterator = port              # ← rename "each" to "port"

  content {
    from_port = port.value     # ← clearer than each.value
    to_port   = port.value
    protocol  = "tcp"
  }
}
```

---

## Practical Examples

### Security group ingress rules from a list of ports

```hcl
variable "allowed_ports" {
  type    = list(number)
  default = [22, 80, 443, 8080]
}

resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_ports    # ← one block per port
    iterator = port

    content {
      from_port   = port.value      # ← port number
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### IAM policy statements from a map

```hcl
variable "s3_permissions" {
  type = map(object({
    actions   = list(string)
    resources = list(string)
  }))
  default = {
    read_prod = {
      actions   = ["s3:GetObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::prod-bucket", "arn:aws:s3:::prod-bucket/*"]
    }
    write_staging = {
      actions   = ["s3:PutObject", "s3:DeleteObject"]
      resources = ["arn:aws:s3:::staging-bucket/*"]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  dynamic "statement" {
    for_each = var.s3_permissions    # ← one statement per map entry
    iterator = perm

    content {
      sid       = perm.key           # ← "read_prod", "write_staging"
      effect    = "Allow"
      actions   = perm.value.actions
      resources = perm.value.resources
    }
  }
}
```

### S3 lifecycle rules from a list

```hcl
variable "lifecycle_rules" {
  type = list(object({
    id      = string
    prefix  = string
    days    = number
  }))
  default = [
    { id = "archive-logs",    prefix = "logs/",    days = 30  },
    { id = "expire-tmp",      prefix = "tmp/",     days = 7   },
    { id = "archive-reports", prefix = "reports/", days = 90  },
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.data.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    iterator = r

    content {
      id     = r.value.id
      status = "Enabled"

      filter {
        prefix = r.value.prefix    # ← which objects this rule applies to
      }

      transition {
        days          = r.value.days
        storage_class = "GLACIER"
      }
    }
  }
}
```

### Tags from a map (the most common pattern)

Many AWS resources accept a `tags` argument directly as a map — no dynamic block needed there. But some nested blocks require dynamic:

```hcl
variable "common_tags" {
  type = map(string)
  default = {
    Environment = "prod"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}

# For resources that accept tags as a map argument — no dynamic needed
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  tags          = var.common_tags    # ← direct map assignment, no dynamic needed
}

# For resources with a nested tag block structure — dynamic is needed
resource "aws_autoscaling_group" "app" {
  name               = "app-asg"
  min_size           = 1
  max_size           = 5
  desired_capacity   = 2
  vpc_zone_identifier = var.subnet_ids

  dynamic "tag" {
    for_each = var.common_tags    # ← iterate the tags map

    content {
      key                 = tag.key      # ← "Environment", "Team", ...
      value               = tag.value    # ← "prod", "platform", ...
      propagate_at_launch = true         # ← apply tag to EC2 instances created by ASG
    }
  }
}
```

---

## Nested Dynamic Blocks

You can put a dynamic block inside another dynamic block. Use this sparingly — nested dynamics become hard to read and debug.

```hcl
# Example: security group rules with multiple CIDR blocks per port
variable "rules" {
  default = [
    {
      port  = 443
      cidrs = ["10.0.0.0/8", "172.16.0.0/12"]
    }
  ]
}

dynamic "ingress" {
  for_each = var.rules
  iterator = rule

  content {
    from_port = rule.value.port
    to_port   = rule.value.port
    protocol  = "tcp"

    # Nested dynamic not needed here since cidr_blocks takes a list,
    # but shown for illustration when a sub-block requires iteration:
    dynamic "cidr_block_association" {
      for_each = rule.value.cidrs    # ← inner loop
      iterator = cidr

      content {
        cidr_block = cidr.value
      }
    }
  }
}
```

If you find yourself writing nested dynamics, consider whether a flattened `locals` expression would be clearer.

---

## Conditionally Omitting Blocks

A common requirement: include a block only when a feature flag is enabled. The pattern uses a ternary that produces either a one-element list (block appears once) or an empty list (block is omitted):

```hcl
variable "enable_logging" {
  type    = bool
  default = false
}

resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"

  dynamic "logging" {
    for_each = var.enable_logging ? [1] : []    # ← [1] = include once, [] = omit
    # The value "1" is arbitrary — we only care that the list has one element

    content {
      target_bucket = aws_s3_bucket.logs.id
      target_prefix = "s3-access-logs/"
    }
  }
}
```

This pattern appears everywhere in production modules. It replaces the older `count` hack on resources with a clean, intention-revealing syntax.

```hcl
# Multiple optional blocks controlled by different flags
resource "aws_cloudwatch_log_group" "app" {
  name = "/app/logs"

  dynamic "retention_policy" {
    for_each = var.log_retention_days != null ? [var.log_retention_days] : []

    content {
      retention_in_days = retention_policy.value    # ← the value from the list
    }
  }
}
```

---

## null_resource — A Placeholder That Does Things

Here is the puzzle: you need to run a shell script after Terraform creates an RDS database. But there is no AWS resource type for "run this command." You want Terraform to manage the lifecycle of this action — only re-run it when the database changes.

**null_resource** solves this. It is a resource that creates no real infrastructure. Its only job is to hold a `provisioner` block and a `triggers` map. Think of it as a sticky note attached to a real resource: "after this changes, run this command."

```hcl
resource "null_resource" "example" {
  # triggers: when any value here changes, the null_resource is replaced
  # (which re-runs the provisioner)
  triggers = {
    always_run = timestamp()    # ← re-run on every apply
    # OR:
    db_endpoint = aws_db_instance.main.endpoint  # ← re-run when DB changes
  }

  provisioner "local-exec" {
    command = "echo 'Hello from null_resource'"
  }
}
```

### triggers — controlling when it re-runs

The `triggers` map is the key to null_resource's behavior. Terraform computes a hash of all trigger values. If the hash changes between applies, the null_resource is destroyed and re-created — which re-runs all its provisioners.

```hcl
triggers = {
  # Re-run when the RDS instance endpoint changes (new database)
  db_endpoint = aws_db_instance.main.endpoint

  # Re-run when the script file itself changes
  script_hash = filemd5("${path.module}/scripts/seed.sh")

  # Re-run on every apply (use sparingly — breaks idempotency)
  always = timestamp()
}
```

### local-exec provisioner — run commands on the Terraform host

`local-exec` runs a command on the machine executing Terraform — your laptop, a CI runner, a Terraform Cloud agent.

```hcl
resource "null_resource" "db_seed" {
  triggers = {
    db_endpoint = aws_db_instance.main.endpoint
    script_hash = filemd5("${path.module}/scripts/seed.sh")
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/seed.sh"

    # Optional: override the working directory
    working_dir = path.module

    # Optional: override the interpreter (default: sh on Linux/mac, cmd on Windows)
    interpreter = ["/bin/bash", "-c"]

    # Optional: pass environment variables
    environment = {
      DB_HOST     = aws_db_instance.main.address
      DB_PASSWORD = random_password.db.result
    }
  }
}
```

### remote-exec provisioner — run commands on a remote host

`remote-exec` SSHs into a remote machine and runs commands there. Requires a `connection` block.

```hcl
resource "null_resource" "configure_server" {
  triggers = {
    instance_id = aws_instance.web.id
  }

  connection {
    type        = "ssh"
    host        = aws_instance.web.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")    # ← path to SSH key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
    ]
  }
}
```

Note: In modern AWS architectures, remote-exec is largely replaced by EC2 user data or AWS Systems Manager. Use it only when you have no other option.

---

## local-exec Patterns in Practice

### Calling kubectl after EKS cluster creation

```hcl
resource "null_resource" "update_kubeconfig" {
  triggers = {
    cluster_name = aws_eks_cluster.main.name
    cluster_endpoint = aws_eks_cluster.main.endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig \
        --name ${aws_eks_cluster.main.name} \
        --region ${var.aws_region}
    EOT
    # ↑ heredoc for multi-line commands
  }

  depends_on = [aws_eks_cluster.main]    # ← explicit dependency
}
```

### Seeding a database after RDS creation

```hcl
resource "null_resource" "seed_database" {
  triggers = {
    db_endpoint = aws_db_instance.app.endpoint
    seed_hash   = filemd5("${path.module}/sql/seed.sql")
  }

  provisioner "local-exec" {
    command = "psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f ${path.module}/sql/seed.sql"
    environment = {
      DB_HOST     = aws_db_instance.app.address
      DB_USER     = var.db_username
      DB_NAME     = var.db_name
      PGPASSWORD  = random_password.db.result  # ← psql reads this env var
    }
  }

  depends_on = [aws_db_instance.app]
}
```

### Calling a webhook after deployment

```hcl
resource "null_resource" "notify_deployment" {
  triggers = {
    # Only trigger on real changes, not every apply
    app_version = var.app_version
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST \
        -H "Content-Type: application/json" \
        -d '{"version":"${var.app_version}","env":"${var.environment}"}' \
        ${var.webhook_url}
    EOT
  }
}
```

---

## terraform_data — The Modern Replacement (Terraform 1.4+)

In Terraform 1.4, **terraform_data** was introduced as a built-in replacement for null_resource. It requires no provider (null_resource requires the `hashicorp/null` provider) and has a cleaner syntax with an explicit `input` attribute.

```hcl
# Old way — null_resource
resource "null_resource" "example" {
  triggers = {
    db_id = aws_db_instance.main.id
  }
  provisioner "local-exec" {
    command = "echo ${aws_db_instance.main.endpoint}"
  }
}

# New way — terraform_data (Terraform 1.4+)
resource "terraform_data" "example" {
  # input stores a value; when it changes, the resource is replaced
  input = aws_db_instance.main.endpoint    # ← replaces "triggers"

  provisioner "local-exec" {
    command = "echo ${self.input}"         # ← access via self.input
  }
}
```

For complex triggers (multiple values), use a map as the input:

```hcl
resource "terraform_data" "db_seed" {
  input = {
    endpoint    = aws_db_instance.main.endpoint
    script_hash = filemd5("${path.module}/scripts/seed.sh")
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/seed.sh"
    environment = {
      DB_HOST = self.input.endpoint
    }
  }
}
```

Prefer `terraform_data` for new code. Use `null_resource` when you need to support Terraform versions before 1.4.

---

## lifecycle meta-argument

Dynamic blocks and null_resource control _what_ resources are created and _when_ provisioners run. The `lifecycle` meta-argument controls _how_ Terraform manages the replacement lifecycle of a resource: whether to create before destroy, ignore certain attribute changes, or prevent accidental deletion.

This is covered in detail in [hooks_across_the_stack.md](../03_state_and_lifecycle/hooks_across_the_stack.md). The key patterns (`create_before_destroy`, `prevent_destroy`, `ignore_changes`, `replace_triggered_by`) all integrate naturally with dynamic blocks.

---

## Common Mistakes

| Mistake | Why it happens | Fix |
|---|---|---|
| null_resource not re-running when expected | `triggers` map does not reference the value that changed | Add the changing value to `triggers`; use `filemd5()` for scripts |
| null_resource re-running on every apply unexpectedly | `triggers = { always = timestamp() }` left in from debugging | Remove the `timestamp()` trigger; only use for one-off applies |
| local-exec command fails silently | Default shell interprets the command differently on Linux vs macOS | Specify `interpreter = ["/bin/bash", "-c"]` explicitly |
| Working directory confusion | local-exec runs in the root module directory, not the module's folder | Set `working_dir = path.module` explicitly |
| Quoting breaks in heredoc commands | Variable interpolation collides with shell quotes | Wrap shell variables in single quotes; Terraform vars in `${}` |
| Provisioners are not idempotent | Script runs `CREATE TABLE` without `IF NOT EXISTS` | Always write scripts that can be safely re-run |
| Dynamic block iterates over null | `var.my_list` is null when feature is disabled | Use `var.my_list != null ? var.my_list : []` in `for_each` |
| Nested dynamic blocks are unreadable | Built incrementally over time without refactoring | Flatten with a `locals` computed map before the dynamic block |

---

## Navigation

Back to [02_hcl_basics README](./README.md)

Previous: [expressions.md](./expressions.md) | Next: [data_types.md](./data_types.md)

Related: [syntax.md](./syntax.md) | [variables.md](../01_core_concepts/variables.md) | [ci_cd_integration.md](../09_best_practices/ci_cd_integration.md)
