# 04 — Recap: ECS Fargate Production Deployment

## What You Built

A container-native production stack where AWS manages the compute entirely. You define what to run (task definition) and how many copies (service desired count), and ECS handles placement, rolling deployments, failure recovery, and auto-scaling.

---

## 3 Key Concepts

### 1. Serverless Containers: What Fargate Actually Removes

With EC2, you own a virtual machine. You patch it, resize it, pay for it while it's idle. Fargate's billing model is different: you pay per **vCPU-second and GB-second** that your tasks actually consume. A task with 256 CPU units costs $0.04048/vCPU/hour — about $0.01/hour. Idle tasks still accrue that charge, but there's no "instance" to maintain.

What you give up: control over the underlying OS, the ability to run custom kernel modules, and predictable network placement (though VPC networking still works as expected).

### 2. Secrets Manager Injection

The separation of concerns is critical:

- The **execution role** (`ecs_execution`) handles infrastructure concerns: pulling the image from ECR, writing to CloudWatch Logs, and reading secrets from Secrets Manager. It runs before the container starts.
- The **task role** (`ecs_task`) is what the container itself can do: call S3, DynamoDB, etc. It runs during execution.

The `secrets` field in the container definition triggers the execution role to call `secretsmanager:GetSecretValue` at task start. The value is injected as an environment variable. The secret never touches disk and is not visible in `docker inspect` or ECS API responses.

### 3. Auto-Scaling with Target Tracking

Target tracking is distinct from step scaling. With step scaling you define explicit rules ("when CPU > 70%, add 2 tasks"). With target tracking you just say "keep average CPU at 60%" — AWS figures out the rules.

Under the hood, target tracking creates CloudWatch alarms automatically (one for scale-out, one for scale-in). You can see them in the CloudWatch console as `TargetTracking-service/myapp/myapp-service-AlarmHigh` and `-AlarmLow`. Do not delete or modify them manually — Terraform manages them.

---

## Deployment Troubleshooting

| Symptom | How to investigate |
|---|---|
| Tasks keep stopping and restarting | `aws ecs describe-tasks` → look at `stopCode` and `stoppedReason` |
| Tasks stuck in PENDING | Check if subnets have route to NAT (for ECR pull) |
| Health check failing | `aws logs tail /ecs/myapp-api --follow` |
| Secrets not injected | Check execution role has `secretsmanager:GetSecretValue` on the right ARN |
| Image not found | Verify ECR URI in task definition matches the pushed image |

---

## Extend It

**Blue/green deployment with CodeDeploy**
Add `deployment_controller { type = "CODE_DEPLOY" }` to the ECS service. CodeDeploy manages the rollover: it starts a new task set on a test listener port, you validate, then shifts traffic. Supports instant rollback.

**Add SQS for async tasks**
Add an SQS queue and a second ECS service (the "worker") that polls it. The API writes to SQS and returns immediately; the worker processes in the background. Scales independently of the API.

**Add X-Ray tracing**
Add the X-Ray daemon as a sidecar container in the task definition. Instrument the FastAPI app with `aws-xray-sdk`. View distributed traces in the X-Ray console — see where each request spends its time.

**Use Aurora Serverless v2**
Replace `aws_db_instance` with `aws_rds_cluster` (Aurora Serverless v2). Aurora scales ACUs (Aurora Capacity Units) from 0.5 to 64 in seconds. During idle periods it scales down to near-zero. Eliminates the fixed RDS hourly charge for low-traffic environments.

---

## ✅ What you mastered
- ECS Fargate architecture: cluster, service, task definition, ENI networking
- Secrets Manager injection via the ECS execution role
- Application Auto Scaling with CPU target tracking

## 🔨 What to build next
- Add a second container to the task definition (sidecar pattern): a metrics exporter, log router, or AWS X-Ray daemon

## ➡️ Next project
Go beyond a generic API — deploy a working AI RAG system to AWS: [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md)

---

## 📂 Navigation

**Prev:** [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md) &nbsp;&nbsp; **Next:** [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
