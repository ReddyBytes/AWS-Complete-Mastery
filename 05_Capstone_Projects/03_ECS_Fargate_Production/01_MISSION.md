# 01 — Mission: ECS Fargate + RDS + ALB Production Deployment

## The Scenario

EC2 is powerful but high-maintenance. You have to patch the OS, manage disk space, rotate logs, and babysit the instance. When you deploy a new version, you SSH in and restart the service — with a gap of a few seconds where nothing is running.

**ECS Fargate** removes all of that. You describe your app as a Docker container and Fargate runs it on AWS-managed infrastructure. You never see an OS. You never SSH in. AWS handles the underlying compute, and your deployments are rolling updates with zero downtime.

This project takes the same API from Project 02 and containerizes it properly — with ECR for image storage, Secrets Manager for database credentials, Container Insights for observability, and auto-scaling based on CPU load.

---

## What You'll Build

A container-native production stack:

- **ECR** repository for Docker image storage + lifecycle policy (keep last 10 images)
- **ECS cluster** with Container Insights enabled
- **Fargate task definition** with Secrets Manager injection for DB credentials
- **ECS service** with rolling deployment and ALB integration
- **Auto-scaling** policy: scale out when CPU > 60%, scale in when CPU < 30%
- **CloudWatch** Container Insights dashboard

---

## Skills You'll Practice

| Skill | What you'll do |
|---|---|
| Docker + ECR | Build image, tag it, push to private registry |
| ECS concepts | Cluster vs Service vs Task vs Task Definition |
| Fargate networking | Tasks in private subnets, NAT for outbound |
| Secrets Manager | Inject DB password as environment variable at runtime |
| ECS auto-scaling | Application Auto Scaling with target tracking |
| CloudWatch | Container Insights, log groups, metric alarms |

---

## Prerequisites

- Comfortable with Docker (build, tag, push)
- Completed Project 02 (or understand VPC, ALB, RDS, security groups)
- AWS CLI configured

---

## Project Metadata

| Field | Value |
|---|---|
| Difficulty | 🟠 Minimal Hints |
| Estimated time | 6 hours |
| AWS cost | ~$3-8/day (Fargate + NAT + RDS) |
| Stack | Terraform 1.7+, ECS Fargate, ECR, RDS Aurora, ALB, Secrets Manager |

---

## Acceptance Criteria

You've succeeded when:

1. `docker push` to ECR succeeds
2. `terraform apply` completes with no errors
3. ECS service shows desired count = 2, running count = 2
4. `curl http://<alb_dns>/health` returns 200
5. `aws ecs describe-tasks` shows tasks pulling DB credentials from Secrets Manager (check the `secrets` field in the task definition)
6. Running `ab -n 10000 -c 100 http://<alb_dns>/health` triggers auto-scaling (watch in CloudWatch or `watch aws ecs describe-services`)

---

## 📂 Navigation

**Prev:** [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md) &nbsp;&nbsp; **Next:** [04 — RAG on AWS](../04_RAG_on_AWS/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
