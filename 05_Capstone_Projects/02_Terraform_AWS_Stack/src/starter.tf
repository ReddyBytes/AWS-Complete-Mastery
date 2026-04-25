# =============================================================================
# Project 02: Terraform Full AWS Stack — STARTER
# =============================================================================
# Fill in all TODO sections to provision the full e-commerce API stack.
#
# Usage:
#   export TF_VAR_db_password="your-secure-password"
#   terraform init
#   terraform plan
#   terraform apply
# =============================================================================

# ── Terraform and provider configuration ──────────────────────────────────────
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
  # TODO: Set the region variable
  region = var.aws_region
}

# ── Variables ─────────────────────────────────────────────────────────────────
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ecommerce-api"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_password" {
  type      = string
  sensitive = true
  # TODO: Pass via TF_VAR_db_password env var — never hardcode
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

# ── Data sources ──────────────────────────────────────────────────────────────
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ── Networking ────────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  # TODO: Set cidr_block to 10.0.0.0/16
  # TODO: Enable DNS hostnames and support
}

resource "aws_subnet" "public" {
  count = 2
  # TODO: Set vpc_id, cidr_block (10.0.1.0/24 and 10.0.2.0/24),
  #       availability_zone (use data.aws_availability_zones),
  #       map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count = 2
  # TODO: Set vpc_id, cidr_block (10.0.3.0/24 and 10.0.4.0/24),
  #       availability_zone
  #       (no map_public_ip_on_launch — these are private)
}

resource "aws_internet_gateway" "main" {
  # TODO: Attach to aws_vpc.main
}

resource "aws_eip" "nat" {
  domain = "vpc"
  # TODO: Add a Name tag
}

resource "aws_nat_gateway" "main" {
  # TODO: Set allocation_id (from aws_eip.nat)
  # TODO: Set subnet_id (put it in public subnet [0])
  # TODO: Add depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  # TODO: Set vpc_id
  # TODO: Add route: 0.0.0.0/0 → aws_internet_gateway.main
}

resource "aws_route_table" "private" {
  # TODO: Set vpc_id
  # TODO: Add route: 0.0.0.0/0 → aws_nat_gateway.main
}

resource "aws_route_table_association" "public" {
  count = 2
  # TODO: Associate public subnets with public route table
}

resource "aws_route_table_association" "private" {
  count = 2
  # TODO: Associate private subnets with private route table
}

# ── Security Groups ───────────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  # TODO: Allow inbound 80 and 443 from 0.0.0.0/0
  # TODO: Allow all outbound
}

resource "aws_security_group" "ec2" {
  # TODO: Allow inbound 8000 from aws_security_group.alb only
  # TODO: Allow all outbound
}

resource "aws_security_group" "rds" {
  # TODO: Allow inbound 5432 from aws_security_group.ec2 only
  # TODO: No outbound needed (RDS never initiates connections)
}

# ── ALB ───────────────────────────────────────────────────────────────────────
resource "aws_lb" "main" {
  # TODO: internet-facing, application type, alb security group, public subnets
}

resource "aws_lb_target_group" "app" {
  # TODO: port 8000, HTTP, vpc_id
  # TODO: health_check block: path = "/health"
}

resource "aws_lb_listener" "http" {
  # TODO: Listen on port 80, forward to aws_lb_target_group.app
}

# ── EC2 + Auto Scaling ────────────────────────────────────────────────────────
resource "aws_launch_template" "app" {
  # TODO: Use data.aws_ami.ubuntu, var.instance_type, ec2 security group
  # TODO: Add user_data that installs Python + FastAPI + systemd service
}

resource "aws_autoscaling_group" "app" {
  # TODO: min=1, max=3, desired=2
  # TODO: Use public subnets, attach to target group
  # TODO: health_check_type = "ELB"
}

# ── RDS ───────────────────────────────────────────────────────────────────────
resource "aws_db_subnet_group" "main" {
  # TODO: Use private subnets
}

resource "aws_db_instance" "postgres" {
  # TODO: postgres 16.1, db.t3.micro, 20GB
  # TODO: db_name, username, password
  # TODO: publicly_accessible = false, skip_final_snapshot = true
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "alb_dns_name" {
  # TODO: Output the ALB DNS name
  value = ""
}

output "rds_endpoint" {
  # TODO: Output the RDS address (sensitive)
  value     = ""
  sensitive = true
}
