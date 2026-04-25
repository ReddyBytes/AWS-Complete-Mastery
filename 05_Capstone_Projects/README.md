# 05 — Capstone Projects

Five end-to-end projects that combine everything from sections 01-04: Linux, Terraform, AWS, and containers. Each project deploys a real system to real AWS infrastructure.

---

## Projects

| # | Project | Stack | Difficulty | Time |
|---|---------|-------|------------|------|
| 01 | [JWT Auth API to EC2](./01_JWT_Auth_API_EC2/01_MISSION.md) | EC2, Nginx, systemd, Let's Encrypt | 🟢 Fully Guided | 3h |
| 02 | [Terraform Full AWS Stack](./02_Terraform_AWS_Stack/01_MISSION.md) | Terraform, VPC, EC2, RDS, ALB | 🟡 Partially Guided | 5h |
| 03 | [ECS Fargate Production](./03_ECS_Fargate_Production/01_MISSION.md) | ECS Fargate, ECR, Secrets Manager, Auto-Scaling | 🟠 Minimal Hints | 6h |
| 04 | [RAG System on AWS](./04_RAG_on_AWS/01_MISSION.md) | ECS, RDS + pgvector, S3, EventBridge | 🟠 Minimal Hints | 7h |
| 05 | [Serverless AI Agent](./05_Serverless_AI_Agent/01_MISSION.md) | Lambda, API Gateway, DynamoDB, SSM | 🔴 Build Yourself | 8h |

---

## Difficulty Guide

| Symbol | Meaning |
|---|---|
| 🟢 Fully Guided | Every step has a hint and a full answer. Best for first-timers. |
| 🟡 Partially Guided | Key steps have partial code stubs. Some filling in required. |
| 🟠 Minimal Hints | One hint per step. You write all the code. |
| 🔴 Build Yourself | Spec + acceptance criteria only. Reference solution in `src/solution.*`. |

---

## Cost Warning

These projects create real AWS resources that accrue charges. NAT Gateways, RDS instances, and Fargate tasks are not free-tier eligible.

Always run `terraform destroy` when done with a project. Estimated daily costs:

| Project | Approximate cost |
|---|---|
| 01 (EC2 t2.micro) | ~$0.01/hour (free tier eligible) |
| 02 (VPC + RDS + ALB) | ~$5-10/day |
| 03 (ECS + RDS + ALB) | ~$3-8/day |
| 04 (ECS + RDS + S3) | ~$5-10/day |
| 05 (Lambda + DynamoDB) | ~$0-2/month at low traffic |

---

## Prerequisites

- AWS account with IAM user credentials configured (`aws configure`)
- Terraform 1.7+ installed
- Docker installed (Projects 03, 04)
- Basic AWS CLI familiarity

---

## 📂 Navigation

**Repo:** [Linux-Terraform-AWS-Mastery](../README.md)
