# =============================================================================
# Project 03: ECS Fargate Production Deployment — COMPLETE SOLUTION
# =============================================================================
# Full Terraform configuration for ECS Fargate with:
#   - ECR repository with lifecycle policy
#   - Secrets Manager for DB credentials
#   - ECS Fargate cluster + service with rolling deployments
#   - Container Insights
#   - Application Auto Scaling (CPU target tracking)
#   - CloudWatch alarms
#
# Assumes VPC + subnets exist. Pass their IDs as variables.
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
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

# ── Variables ─────────────────────────────────────────────────────────────────

variable "aws_region"          { type = string; default = "us-east-1" }
variable "project_name"        { type = string; default = "myapp" }
variable "db_password"         { type = string; sensitive = true }
variable "vpc_id"              { type = string }
variable "private_subnet_ids"  { type = list(string) }
variable "public_subnet_ids"   { type = list(string) }
variable "task_cpu"            { type = string; default = "256" }
variable "task_memory"         { type = string; default = "512" }

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── ECR Repository ────────────────────────────────────────────────────────────

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"  # ← allow re-tagging (e.g., re-push :latest)

  image_scanning_configuration {
    scan_on_push = true  # ← ECR scans each pushed image for CVEs
  }

  tags = { Name = "${var.project_name}-ecr" }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  # Keep only the 10 most recently pushed tagged images — prevents ECR from growing unbounded
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 tagged images"
      selection = {
        tagStatus   = "tagged"
        tagPrefixList = ["v", "latest"]
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }, {
      rulePriority = 2
      description  = "Remove untagged images after 1 day"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 1
      }
      action = { type = "expire" }
    }]
  })
}

# ── Secrets Manager ───────────────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}/db-password"
  recovery_window_in_days = 0  # ← for dev: allow immediate deletion; set 7+ for production

  tags = { Name = "${var.project_name}-db-secret" }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.project_name}-api"
  retention_in_days = 30  # ← logs older than 30 days are automatically deleted

  tags = { Name = "${var.project_name}-logs" }
}

# ── IAM: Task Execution Role (Fargate control plane) ─────────────────────────

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_base" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  # ← grants: ECR pull, CloudWatch Logs write
}

resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project_name}-secrets-policy"
  role = aws_iam_role.ecs_execution.id

  # The execution role needs to read the secret at task start time
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [aws_secretsmanager_secret.db_password.arn]
    }]
  })
}

# ── IAM: Task Role (running application permissions) ─────────────────────────

resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  # Add inline policies here for S3, DynamoDB, etc. as your app needs them
}

# ── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB: internet-facing"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Fargate tasks: only accept from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # ← tasks need outbound for ECR, Secrets Manager, RDS
  }
}

# ── ECS Cluster ───────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"  # ← publishes per-task CPU/memory metrics to CloudWatch
  }

  tags = { Name = "${var.project_name}-cluster" }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]  # ← FARGATE_SPOT is ~70% cheaper for fault-tolerant workloads

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# ── ALB ───────────────────────────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"  # ← Fargate uses IP targets (each task ENI gets its own IP)

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
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

# ── ECS Task Definition ───────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"  # ← required for Fargate; each task gets its own ENI
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "api"
    image = "${aws_ecr_repository.app.repository_url}:latest"

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    # Secrets injected at task start — never stored in the image or environment
    secrets = [{
      name      = "DB_PASSWORD"
      valueFrom = aws_secretsmanager_secret.db_password.arn
    }]

    environment = [
      { name = "APP_ENV",    value = "production" },
      { name = "APP_PORT",   value = "8000" },
      { name = "LOG_LEVEL",  value = "info" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "ecs"  # ← log streams named: ecs/api/<task-id>
      }
    }

    # Graceful shutdown: SIGTERM → 30s wait → SIGKILL
    stopTimeout = 30
  }])

  tags = { Name = "${var.project_name}-task-def" }
}

# ── ECS Service ───────────────────────────────────────────────────────────────

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Rolling deployment: always maintain 50% healthy, allow up to 200% during deploy
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false  # ← private subnets — outbound via NAT Gateway
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "api"
    container_port   = 8000
  }

  deployment_circuit_breaker {
    enable   = true   # ← automatically rolls back if deployment fails
    rollback = true
  }

  depends_on = [aws_lb_listener.http]  # ← ensure ALB listener exists before service registers

  lifecycle {
    ignore_changes = [desired_count]  # ← let auto-scaling manage desired count after creation
  }

  tags = { Name = "${var.project_name}-service" }
}

# ── Application Auto Scaling ──────────────────────────────────────────────────

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.app]
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60.0  # ← scale when average CPU across all tasks exceeds 60%
    scale_in_cooldown  = 300   # ← wait 5 min before scaling in (avoid flapping)
    scale_out_cooldown = 60    # ← scale out faster than scale in
  }
}

# ── CloudWatch Alarm: CPU too high (scaling not keeping up) ───────────────────

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-very-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85  # ← 85% = auto-scaling isn't keeping up with load

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_description = "CPU > 85% — auto-scaling cannot keep up. Investigate."
  alarm_actions     = []  # ← add SNS topic ARN here to get paged
  ok_actions        = []
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "ecr_repository_url" {
  description = "Use this for: docker tag myapp <ecr_url>:latest && docker push <ecr_url>:latest"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "Test with: curl http://<alb_dns>/health"
  value       = aws_lb.main.dns_name
}

output "docker_push_commands" {
  description = "Commands to build and push image after apply"
  value = <<-EOT
    aws ecr get-login-password --region ${var.aws_region} | \
      docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    docker build -t ${var.project_name}-api .
    docker tag ${var.project_name}-api:latest ${aws_ecr_repository.app.repository_url}:latest
    docker push ${aws_ecr_repository.app.repository_url}:latest

    # Force ECS to redeploy with the new image:
    aws ecs update-service --cluster ${aws_ecs_cluster.main.name} \
      --service ${aws_ecs_service.app.name} --force-new-deployment
  EOT
}
