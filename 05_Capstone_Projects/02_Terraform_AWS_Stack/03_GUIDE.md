# 03 — Guide: Terraform Full AWS Stack

This guide walks you through building the full e-commerce API stack with Terraform. Each step includes a partial hint and enough code to verify you're on track.

---

## Step 1 — Root Module: variables.tf + providers.tf

Start with the root of the Terraform project. `providers.tf` declares which cloud provider to use and where to store state. `variables.tf` declares all inputs so nothing is hardcoded.

<details>
<summary>💡 Hint: Key variables to declare</summary>

- `aws_region` (string, default "us-east-1")
- `project_name` (string, default "ecommerce-api") — used for Name tags
- `db_password` (string, sensitive = true) — pass via env var `TF_VAR_db_password`
- `instance_type` (string, default "t3.micro")
- `db_instance_class` (string, default "db.t3.micro")
</details>

<details>
<summary>✅ Answer: providers.tf and variables.tf</summary>

```hcl
# providers.tf
terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Optional: use S3 backend for real team workflows
  # backend "s3" {
  #   bucket = "my-terraform-state"
  #   key    = "ecommerce-api/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Environment = "demo"
    }
  }
}
```

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "ecommerce-api"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_password" {
  description = "RDS master password — pass via TF_VAR_db_password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}
```
</details>

---

## Step 2 — Networking Module

The networking module creates the VPC plumbing: public subnets (where EC2 lives), private subnets (where RDS lives), an internet gateway for public outbound traffic, a NAT gateway so private instances can download packages without being publicly routable.

<details>
<summary>💡 Hint: Resources to create</summary>

```
aws_vpc                        (cidr 10.0.0.0/16)
aws_subnet x4                  (2 public /24, 2 private /24 in different AZs)
aws_internet_gateway           (attached to VPC)
aws_eip                        (for the NAT gateway)
aws_nat_gateway                (in a public subnet)
aws_route_table x2             (one for public → IGW, one for private → NAT)
aws_route_table_association x4 (connect subnets to route tables)
```
</details>

<details>
<summary>✅ Answer: networking/main.tf</summary>

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true   # ← allows EC2 to resolve RDS hostnames
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true  # ← EC2 in public subnets get public IPs

  tags = { Name = "${var.project_name}-public-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 3}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.project_name}-private-${count.index + 1}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # ← NAT goes in ONE public subnet
  tags          = { Name = "${var.project_name}-nat" }
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${var.project_name}-rt-public" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id  # ← private traffic → NAT → internet
  }
  tags = { Name = "${var.project_name}-rt-private" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

data "aws_availability_zones" "available" {
  state = "available"
}
```
</details>

---

## Step 3 — Security Groups

Security groups are the most important part of the architecture to get right. Each group has the minimum permissions needed. The key insight: EC2's inbound rule references the ALB security group, not a CIDR — so only traffic that passed through the ALB is allowed.

<details>
<summary>💡 Hint: Three security groups, one rule each</summary>

- `alb_sg`: inbound 80+443 from 0.0.0.0/0, outbound all
- `ec2_sg`: inbound 8000 from `alb_sg` (not from the internet), outbound all
- `rds_sg`: inbound 5432 from `ec2_sg` only, no outbound needed
</details>

<details>
<summary>✅ Answer: security groups</summary>

```hcl
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB: accept HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "EC2: accept traffic from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # ← reference to SG, not CIDR
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS: accept traffic from EC2 only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]  # ← EC2 → RDS, nothing else
  }
}
```
</details>

---

## Step 4 — EC2 Module (Launch Template + ASG)

The launch template defines what each EC2 instance looks like. `user_data` is a bash script that runs once on first boot — use it to install your app. The Auto Scaling Group manages how many instances you have and replaces unhealthy ones.

<details>
<summary>💡 Hint: user_data structure</summary>

user_data runs as root at boot. Use it to: install Python, copy your app, write a systemd service, start it. The content must be base64-encoded.

```hcl
user_data = base64encode(<<-EOF
  #!/bin/bash
  set -euo pipefail
  apt-get update -y
  # ... install deps ...
  # ... write app files ...
  # ... systemctl enable + start ...
EOF
)
```
</details>

<details>
<summary>✅ Answer: launch template and ASG</summary>

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # ← Canonical's AWS account ID
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.ec2_sg_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y python3.11 python3.11-venv python3-pip

    mkdir -p /opt/myapp/app
    cat > /opt/myapp/app/main.py << 'PYEOF'
    from fastapi import FastAPI
    app = FastAPI()

    @app.get("/health")
    def health():
        return {"status": "ok", "host": __import__("socket").gethostname()}
    PYEOF

    echo "fastapi==0.111.0
    uvicorn[standard]==0.29.0
    gunicorn==22.0.0" > /opt/myapp/app/requirements.txt

    python3.11 -m venv /opt/myapp/venv
    /opt/myapp/venv/bin/pip install -r /opt/myapp/app/requirements.txt -q

    cat > /etc/systemd/system/myapp.service << 'SVCEOF'
    [Unit]
    After=network.target
    [Service]
    WorkingDirectory=/opt/myapp
    ExecStart=/opt/myapp/venv/bin/gunicorn -w 2 -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:8000
    Restart=always
    [Install]
    WantedBy=multi-user.target
    SVCEOF

    systemctl daemon-reload
    systemctl enable myapp
    systemctl start myapp
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-ec2" }
  }

  lifecycle {
    create_before_destroy = true  # ← zero-downtime ASG updates
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"  # ← use ALB health check, not EC2 status checks

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
```
</details>

---

## Step 5 — ALB Module

The Application Load Balancer distributes traffic across your EC2 instances. It also runs health checks — if an instance fails `/health`, the ALB stops sending traffic to it while ASG replaces it.

<details>
<summary>💡 Hint: Three resources you need</summary>

`aws_lb` (the load balancer itself), `aws_lb_target_group` (defines the health check), `aws_lb_listener` (listens on port 80, forwards to target group).
</details>

<details>
<summary>✅ Answer</summary>

```hcl
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false   # ← internet-facing
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids  # ← ALB spans both AZs
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2     # ← 2 successes = healthy
    unhealthy_threshold = 3     # ← 3 failures = unhealthy (remove from rotation)
    interval            = 30
    timeout             = 5
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```
</details>

---

## Step 6 — RDS Module

RDS Postgres lives in the private subnets and is never directly accessible from the internet. The DB subnet group tells RDS which subnets to use; it needs at least two subnets in different AZs for Multi-AZ support.

<details>
<summary>💡 Hint: Key RDS parameters</summary>

- `engine = "postgres"`, `engine_version = "16.1"`
- `db_subnet_group_name` pointing at your private subnets
- `vpc_security_group_ids` pointing at the RDS security group
- `skip_final_snapshot = true` for dev/test (set to false in production!)
</details>

<details>
<summary>✅ Answer</summary>

```hcl
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids  # ← private subnets only

  tags = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.project_name}-db"
  engine            = "postgres"
  engine_version    = "16.1"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "ecommerce"
  username = "appuser"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]

  multi_az               = false  # ← set true for production HA
  publicly_accessible    = false  # ← never expose RDS publicly
  deletion_protection    = false  # ← set true for production
  skip_final_snapshot    = true   # ← for dev; remove for production

  tags = { Name = "${var.project_name}-rds" }
}
```
</details>

---

## Step 7 — outputs.tf

Outputs are how Terraform surfaces important values after `apply`. They also enable module-to-module data passing.

<details>
<summary>✅ Answer</summary>

```hcl
# outputs.tf (root module)
output "alb_dns_name" {
  description = "URL to hit the API"
  value       = module.compute.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS connection host (use in app config)"
  value       = module.database.rds_endpoint
  sensitive   = true  # ← won't print to console on apply
}

output "vpc_id" {
  value = module.networking.vpc_id
}
```
</details>

---

## Step 8 — Init, Plan, Apply, Test

```bash
# Set DB password via environment variable (don't put it in code)
export TF_VAR_db_password="$(openssl rand -base64 24)"

# Initialize Terraform (download providers)
terraform init

# Review what will be created (always do this before apply)
terraform plan -out=tfplan

# Create all resources
terraform apply tfplan

# Test the ALB
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://${ALB_DNS}/health

# When done, tear everything down to avoid charges
terraform destroy
```

---

## 📂 Navigation

**Prev:** [01 — JWT Auth API on EC2](../01_JWT_Auth_API_EC2/01_MISSION.md) &nbsp;&nbsp; **Next:** [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
