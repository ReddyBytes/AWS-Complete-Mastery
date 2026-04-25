# 02 — Architecture: ECS Fargate Production Deployment

## The Big Picture

In Project 02, you managed EC2 instances like individual pets — each one had a name, state, and you cared if it died. Fargate treats compute like **cattle** — you declare "I need 2 running tasks", Fargate places them on hardware you never see, and if one dies, a new one appears.

```
Internet
    |
    | HTTPS :443
    v
+------------------------------------------+
|         Application Load Balancer         |
|     Target Group: ECS tasks on :8000      |
+------------------------------------------+
        |                      |
    AZ-a                   AZ-b
    (private subnet)       (private subnet)
+------------------+  +------------------+
| Fargate Task     |  | Fargate Task     |
| Container: api   |  | Container: api   |
| Port: 8000       |  | Port: 8000       |
| CPU: 256 (.25)   |  | CPU: 256 (.25)   |
| Mem: 512MB       |  | Mem: 512MB       |
+------------------+  +------------------+
        |                      |
        +----------+-----------+
                   |
          (private subnets, same VPC)
                   |
    +------------------------------+
    |  RDS Aurora Serverless v2    |
    |  engine: postgres            |
    |  auto-scales 0.5 → 4 ACUs   |
    +------------------------------+

Note: Fargate tasks are in private subnets.
They reach the internet (for ECR image pulls) via NAT Gateway.
```

---

## ECR Image Pull Flow

When a new ECS task starts, Fargate needs to download the container image. This happens in the private subnet:

```
ECS Service decides to start a new task
    |
    v
Fargate agent pulls image from ECR
    |
    | (HTTPS via NAT Gateway → internet → ECR endpoint)
    | OR (via VPC Endpoint if configured — no NAT needed)
    v
Image layers cached on Fargate compute (not persistent)
    |
    v
Container starts, health check passes
    |
    v
ALB target group registers the task
    |
    v
Traffic routes to the new task
```

---

## Secrets Manager Injection Flow

Never put database passwords in environment variables baked into the task definition or Docker image. Secrets Manager injects them at runtime when the task starts:

```
Task starts on Fargate
    |
    v
ECS task execution role calls secretsmanager:GetSecretValue
    |
    v
Secret: arn:aws:secretsmanager:us-east-1:123:secret:myapp/db-password
    |
    v
Value injected as environment variable: DB_PASSWORD
    |
    v
Container sees:  os.environ["DB_PASSWORD"] = "actualpassword"
    |
    v
Container connects to RDS using the injected credentials
```

The task execution role (different from the task role) handles this call. The secret is never stored on disk or in the task definition — it's injected at start time.

---

## Auto-Scaling Policy

Target tracking auto-scaling works like a thermostat. You set a target, and AWS adds or removes tasks to keep the metric near that target.

```
Metric: ECSService/CPUUtilization (average across all tasks)

CPU > 60% for 2 minutes
    |
    v
Application Auto Scaling adds tasks (scale-out)
    scale-out cooldown: 60s (don't add more within 60s of last scale-out)

CPU < 30% for 5 minutes
    |
    v
Application Auto Scaling removes tasks (scale-in)
    scale-in cooldown: 300s (be conservative — don't remove too fast)

Limits: min=2, max=10
```

---

## Task Definition Anatomy

A task definition is a blueprint for one or more containers. Think of it like a Kubernetes Pod spec.

```
TaskDefinition: myapp-api:revision-5
    |
    ├── family: "myapp-api"
    ├── requiresCompatibilities: ["FARGATE"]
    ├── networkMode: "awsvpc"          ← each task gets its own ENI + private IP
    ├── cpu: "256"                     ← task-level CPU (shared by all containers)
    ├── memory: "512"                  ← task-level memory
    ├── executionRoleArn: arn:...      ← pulls images, writes logs, reads secrets
    ├── taskRoleArn: arn:...           ← what the running app is allowed to do
    └── containerDefinitions:
         └── container: "api"
              ├── image: 123.dkr.ecr.../myapp:latest
              ├── portMappings: [{containerPort: 8000}]
              ├── secrets: [
              │    {name: "DB_PASSWORD", valueFrom: "arn:...secret/db-password"}
              │   ]
              └── logConfiguration:
                   driver: "awslogs"
                   options:
                     awslogs-group: "/ecs/myapp-api"
                     awslogs-region: "us-east-1"
```

---

## 📂 Navigation

**Prev:** [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md) &nbsp;&nbsp; **Next:** [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
