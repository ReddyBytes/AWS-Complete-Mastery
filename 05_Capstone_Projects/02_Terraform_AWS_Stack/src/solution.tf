# =============================================================================
# Project 02: Terraform Full AWS Stack — COMPLETE SOLUTION
# =============================================================================
# Single-file Terraform configuration (no modules) for clarity.
# All resources inline with explanation comments.
#
# Usage:
#   export TF_VAR_db_password="$(openssl rand -base64 24)"
#   terraform init
#   terraform plan -out=tfplan
#   terraform apply tfplan
#   terraform output alb_dns_name
#   terraform destroy  # <-- always run this when done to avoid charges!
# =============================================================================

terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Apply these tags to every resource Terraform creates
  default_tags {
    tags = {
      Project     = var.project_name
      ManagedBy   = "terraform"
      Environment = "demo"
    }
  }
}

# ── Variables ─────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "ecommerce-api"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_password" {
  description = "RDS master password — set via TF_VAR_db_password"
  type        = string
  sensitive   = true  # ← won't appear in plan/apply output or state in plaintext
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

# ── Data Sources ──────────────────────────────────────────────────────────────

data "aws_availability_zones" "available" {
  state = "available"  # ← only return AZs that are currently operational
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # ← Canonical's official AWS account ID
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true  # ← required so EC2 can resolve RDS hostnames like db.xxx.rds.amazonaws.com
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

# ── Subnets ───────────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"  # ← 10.0.1.0/24 and 10.0.2.0/24
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true  # ← EC2 instances in public subnets get public IPs automatically

  tags = { Name = "${var.project_name}-public-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 3}.0/24"  # ← 10.0.3.0/24 and 10.0.4.0/24
  availability_zone = data.aws_availability_zones.available.names[count.index]
  # No map_public_ip_on_launch — private subnets never get public IPs

  tags = { Name = "${var.project_name}-private-${count.index + 1}" }
}

# ── Internet Gateway (public internet access) ─────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# ── NAT Gateway (private → internet, not the other way) ──────────────────────

resource "aws_eip" "nat" {
  domain     = "vpc"  # ← VPC-scoped EIP (as opposed to classic EC2)
  depends_on = [aws_internet_gateway.main]
  tags       = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # ← NAT gateway lives in one public subnet
  depends_on    = [aws_internet_gateway.main]
  tags          = { Name = "${var.project_name}-nat" }
}

# ── Route Tables ──────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id  # ← public traffic goes to IGW
  }

  tags = { Name = "${var.project_name}-rt-public" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id  # ← private traffic exits via NAT (one-way)
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

# ── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB: accept HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # ← -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "EC2: only accept traffic from ALB, not from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from ALB only"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # ← SG reference, not CIDR — this is key
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ec2-sg" }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS: only accept traffic from EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from EC2 only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

# ── IAM Role for EC2 ──────────────────────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  # ← allows SSM Session Manager (no SSH needed)
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ── ALB ───────────────────────────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false  # ← internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id  # ← ALB needs to span both AZs

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"  # ← same port as the target (8000)
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"  # ← only 200 OK counts as healthy
  }

  tags = { Name = "${var.project_name}-tg" }
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

# ── Launch Template ───────────────────────────────────────────────────────────

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # user_data runs as root on first boot — install and start the app
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail
    exec > >(tee /var/log/user-data.log) 2>&1

    apt-get update -y
    apt-get install -y python3.11 python3.11-venv python3-pip

    mkdir -p /opt/myapp/app
    chown -R ubuntu:ubuntu /opt/myapp

    cat > /opt/myapp/app/main.py << 'PYEOF'
    import socket
    from fastapi import FastAPI
    app = FastAPI(title="E-Commerce API")

    @app.get("/health")
    def health():
        return {"status": "ok", "host": socket.gethostname()}

    @app.get("/products")
    def list_products():
        return {"products": [{"id": 1, "name": "Widget", "price": 9.99}]}
    PYEOF

    echo "fastapi==0.111.0
    uvicorn[standard]==0.29.0
    gunicorn==22.0.0" > /opt/myapp/app/requirements.txt

    python3.11 -m venv /opt/myapp/venv
    /opt/myapp/venv/bin/pip install -r /opt/myapp/app/requirements.txt -q

    cat > /etc/systemd/system/myapp.service << 'SVCEOF'
    [Unit]
    Description=E-Commerce API
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
    create_before_destroy = true  # ← when updating the template, new instances start before old ones stop
  }
}

# ── Auto Scaling Group ────────────────────────────────────────────────────────

resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  min_size            = 1
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"  # ← ASG uses ALB health checks to decide when to replace instances
  health_check_grace_period = 120  # ← wait 2 min before checking health (app startup time)

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"  # ← replace instances one at a time during template updates
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }
}

# ── RDS ───────────────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id  # ← RDS only in private subnets

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
  password = var.db_password  # ← from TF_VAR_db_password env var

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false  # ← set true for production HA ($2x cost)
  publicly_accessible = false  # ← NEVER make RDS public
  deletion_protection = false  # ← set true for production
  skip_final_snapshot = true   # ← for dev; remove in production to keep a backup

  tags = { Name = "${var.project_name}-rds" }
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "Hit this URL to test the API"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS connection host"
  value       = aws_db_instance.postgres.address
  sensitive   = true
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "test_command" {
  description = "Quick test after apply"
  value       = "curl http://${aws_lb.main.dns_name}/health"
}
