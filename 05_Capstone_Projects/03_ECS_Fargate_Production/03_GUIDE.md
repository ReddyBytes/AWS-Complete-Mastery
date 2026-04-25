# 03 — Guide: ECS Fargate Production Deployment

This project is 🟠 Minimal Hints. Each step gives you the shape of what to build, but you write the HCL. Refer to the architecture doc and the solution when stuck.

---

## Step 1 — Build and Push Docker Image to ECR

Before Terraform can deploy anything, you need a container image in ECR. Create the ECR repo, build the image, push it.

<details>
<summary>💡 Hint</summary>

Create an ECR repo with Terraform, then authenticate the Docker CLI with `aws ecr get-login-password`. The ECR login command produces a Docker password that expires in 12 hours.

```bash
# After terraform apply creates the ECR repo:
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com

docker build -t myapp-api .
docker tag myapp-api:latest ${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/myapp-api:latest
docker push ${AWS_ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/myapp-api:latest
```
</details>

Write a `Dockerfile` that:
- Uses `python:3.11-slim` as the base
- Copies `requirements.txt` and installs dependencies
- Copies the FastAPI app
- Runs gunicorn on port 8000

Then write the Terraform `aws_ecr_repository` resource with a lifecycle policy that keeps only the last 10 tagged images.

---

## Step 2 — ECS Cluster + Task Definition

Create the ECS cluster with Container Insights enabled, then write the Fargate task definition with Secrets Manager environment variable injection.

<details>
<summary>💡 Hint: Container Insights in Terraform</summary>

```hcl
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"  # ← enables CloudWatch Container Insights
  }
}
```

For the task definition, the `secrets` block in `container_definitions` (it's a JSON string) looks like:
```json
"secrets": [
  {
    "name": "DB_PASSWORD",
    "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:myapp/db-password"
  }
]
```
</details>

Key requirements:
- `requiresCompatibilities = ["FARGATE"]`
- `networkMode = "awsvpc"` (required for Fargate)
- CPU 256, memory 512
- Two IAM roles: `executionRoleArn` (for ECR pull + Secrets Manager) and `taskRoleArn` (for app permissions)
- CloudWatch log group for container logs

---

## Step 3 — ECS Service with ALB Integration

Create the ECS service. This is where desired task count, deployment configuration, and ALB attachment are defined.

<details>
<summary>💡 Hint: network_configuration block</summary>

Fargate tasks need an explicit network configuration since each task gets its own ENI:

```hcl
network_configuration {
  subnets          = var.private_subnet_ids  # ← tasks run in private subnets
  security_groups  = [aws_security_group.ecs_tasks.id]
  assign_public_ip = false  # ← private subnets; they reach internet via NAT
}
```
</details>

Requirements:
- `desired_count = 2`
- `launch_type = "FARGATE"`
- Attach to the ALB target group via `load_balancer` block
- Set `deployment_minimum_healthy_percent = 50` and `deployment_maximum_percent = 200` (enables rolling deployment: at most 2x tasks during deploy)

---

## Step 4 — Auto-Scaling (Target Tracking)

Set up Application Auto Scaling for the ECS service. Target tracking is the simplest form: you pick a metric and a target value, AWS adjusts task count automatically.

<details>
<summary>💡 Hint: resource types</summary>

You need two Terraform resources:
1. `aws_appautoscaling_target` — registers the ECS service as a scalable target
2. `aws_appautoscaling_policy` — defines the target tracking policy (use `ECSServiceAverageCPUUtilization`)
</details>

Requirements:
- Min capacity: 2, max capacity: 10
- Scale-out: CPU > 60%
- Scale-in cooldown: 300 seconds (avoid flapping)

---

## Step 5 — CloudWatch Container Insights

Container Insights automatically publishes metrics and logs to CloudWatch when enabled on the cluster. Create a CloudWatch alarm that fires when CPU > 80% (above the scale-out target — this means scaling isn't keeping up).

<details>
<summary>💡 Hint: ECS metric namespace</summary>

Container Insights metrics are in the `ECS/ContainerInsights` namespace. The relevant metric for this alarm is `CpuUtilized` with dimensions `ClusterName` and `ServiceName`.
</details>

---

## Step 6 — Deploy and Verify Tasks Healthy

After `terraform apply`:

```bash
# Check service status
aws ecs describe-services \
  --cluster <cluster-name> \
  --services <service-name> \
  --query 'services[0].{running:runningCount,desired:desiredCount,pending:pendingCount}'

# Verify secrets are configured in the task definition
aws ecs describe-task-definition \
  --task-definition myapp-api \
  --query 'taskDefinition.containerDefinitions[0].secrets'

# Test via ALB
curl http://$(terraform output -raw alb_dns_name)/health
```

---

## Step 7 — Simulate Load and Watch Auto-Scaling

Trigger auto-scaling by generating load against the service.

```bash
# Install apache bench if not present
sudo apt-get install apache2-utils  # or: brew install ab

ALB_DNS=$(terraform output -raw alb_dns_name)

# Send 50,000 requests with 200 concurrent connections
ab -n 50000 -c 200 http://${ALB_DNS}/health

# In another terminal — watch tasks being added
watch -n 5 "aws ecs describe-services \
  --cluster myapp-cluster \
  --services myapp-service \
  --query 'services[0].{running:runningCount,desired:desiredCount}'"
```

You should see `desiredCount` increase within 2-3 minutes of sustained load.

---

## 📂 Navigation

**Prev:** [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md) &nbsp;&nbsp; **Next:** [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
