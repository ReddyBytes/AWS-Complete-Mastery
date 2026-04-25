# =============================================================================
# Project 03: ECS Fargate Production Deployment — STARTER
# =============================================================================
# Fill in all TODO sections to build the ECS Fargate stack.
# Assumes VPC, subnets, ALB, and RDS already exist (from Project 02 or manual).
#
# Usage:
#   export TF_VAR_db_password="your-password"
#   export TF_VAR_account_id=$(aws sts get-caller-identity --query Account --output text)
#   terraform init && terraform plan
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
}

# ── Variables ─────────────────────────────────────────────────────────────────

variable "aws_region"    { type = string; default = "us-east-1" }
variable "project_name"  { type = string; default = "myapp" }
variable "account_id"    { type = string }  # set via TF_VAR_account_id
variable "db_password"   { type = string; sensitive = true }
variable "vpc_id"        { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "public_subnet_ids"  { type = list(string) }
variable "alb_sg_id"     { type = string }
variable "task_cpu"      { type = string; default = "256" }
variable "task_memory"   { type = string; default = "512" }

# ── ECR Repository ────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "app" {
  # TODO: Set name = "${var.project_name}-api"
  # TODO: Set image_tag_mutability = "MUTABLE"
  # TODO: Add image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecr_lifecycle_policy" "app" {
  # TODO: Set repository = aws_ecr_repository.app.name
  # TODO: Write policy JSON that keeps only the last 10 tagged images
  # Hint: use "tagStatus": "tagged", "countType": "imageCountMoreThan", "countNumber": 10
}

# ── Secrets Manager ───────────────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "db_password" {
  # TODO: Set name = "${var.project_name}/db-password"
  # TODO: Set recovery_window_in_days = 0 (for dev — allows immediate deletion)
}

resource "aws_secretsmanager_secret_version" "db_password" {
  # TODO: Set secret_id = aws_secretsmanager_secret.db_password.id
  # TODO: Set secret_string = var.db_password
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "app" {
  # TODO: Set name = "/ecs/${var.project_name}-api"
  # TODO: Set retention_in_days = 30
}

# ── IAM Roles ─────────────────────────────────────────────────────────────────

resource "aws_iam_role" "ecs_execution" {
  # TODO: Create role with assume_role_policy for ecs-tasks.amazonaws.com
  # TODO: Attach AmazonECSTaskExecutionRolePolicy managed policy
  # TODO: Add inline policy to allow secretsmanager:GetSecretValue on the DB secret
}

resource "aws_iam_role" "ecs_task" {
  # TODO: Create role for the running app
  # TODO: For now, just the assume_role_policy — add permissions as needed
}

# ── ECS Cluster ───────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  # TODO: Set name
  # TODO: Enable Container Insights via setting block
}

# ── Security Group for ECS Tasks ─────────────────────────────────────────────

resource "aws_security_group" "ecs_tasks" {
  # TODO: Allow inbound 8000 from alb_sg only
  # TODO: Allow all outbound (tasks need to reach ECR, Secrets Manager, RDS)
}

# ── ECS Task Definition ───────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  # TODO: Write container_definitions JSON with:
  # - image from ECR repo
  # - portMappings: containerPort 8000
  # - secrets: DB_PASSWORD from Secrets Manager ARN
  # - logConfiguration: awslogs driver → log group above
  container_definitions = "[]"  # replace with actual JSON
}

# ── ALB Target Group + Listener ───────────────────────────────────────────────

resource "aws_lb_target_group" "app" {
  # TODO: Set name, port=8000, protocol=HTTP, vpc_id
  # TODO: target_type = "ip"  ← Fargate uses IP targets, not instance targets
  # TODO: Add health_check block with path = "/health"
}

resource "aws_lb" "main" {
  # TODO: Create ALB in public subnets with alb_sg
}

resource "aws_lb_listener" "http" {
  # TODO: Listen on port 80, forward to target group
}

# ── ECS Service ───────────────────────────────────────────────────────────────

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # TODO: Add network_configuration block
  # TODO: Add load_balancer block pointing to target group
  # TODO: Set deployment_minimum_healthy_percent = 50
  # TODO: Set deployment_maximum_percent = 200
}

# ── Auto-Scaling ──────────────────────────────────────────────────────────────

resource "aws_appautoscaling_target" "ecs" {
  # TODO: max_capacity=10, min_capacity=2
  # TODO: resource_id = "service/${cluster_name}/${service_name}"
  # TODO: scalable_dimension = "ecs:service:DesiredCount"
  # TODO: service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  # TODO: policy_type = "TargetTrackingScaling"
  # TODO: target_tracking_scaling_policy_configuration:
  #   predefined_metric_type = "ECSServiceAverageCPUUtilization"
  #   target_value = 60.0
  #   scale_in_cooldown = 300
  #   scale_out_cooldown = 60
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "ecr_repository_url" {
  # TODO: Output the ECR repo URL (used for docker push)
  value = ""
}

output "alb_dns_name" {
  value = ""
}
