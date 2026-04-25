# 01 — Mission: Terraform Full AWS Stack for E-Commerce API

## The Scenario

You've been clicking through the AWS Console to build infrastructure. It works, but it's fragile: you can't reproduce it, you can't review it in a pull request, and you can't tear it down reliably. One misclick and production is broken.

**Terraform** is the answer. You describe infrastructure as code in `.tf` files — VPCs, subnets, EC2 instances, databases, load balancers — and Terraform figures out the right order to create them. One `terraform apply` builds your entire e-commerce API stack. One `terraform destroy` tears it all down. No console clicking required.

---

## What You'll Build

A production-ready AWS stack for an e-commerce API:

- A **VPC** with public and private subnets across two availability zones
- **EC2 instances** in an Auto Scaling Group behind an **Application Load Balancer**
- An **RDS Postgres** database in private subnets (never reachable from the internet)
- **Security groups** with least-privilege rules — each layer only talks to its neighbor
- **IAM roles** for EC2 instances to access AWS services without hardcoded credentials

---

## Skills You'll Practice

| Skill | What you'll do |
|---|---|
| Terraform providers + state | Configure AWS provider, understand state files |
| VPC networking | Subnets, IGW, route tables, NAT gateway |
| Security groups | Layer-by-layer firewall rules |
| EC2 + user_data | Bootstrap script that installs your app on first boot |
| ALB | Load balancer with health checks and target groups |
| RDS | Managed Postgres in private subnets |
| Outputs | Export useful values (ALB DNS, RDS endpoint) |

---

## Prerequisites

Before starting, you should be comfortable with:

- Terraform basics: `init`, `plan`, `apply`, `destroy`
- AWS networking concepts: VPC, subnets, CIDR blocks, internet gateways
- EC2 fundamentals (from Project 01)

If Terraform is new to you, work through section 04 (Terraform) before starting this project.

---

## Project Metadata

| Field | Value |
|---|---|
| Difficulty | 🟡 Partially Guided |
| Estimated time | 5 hours |
| Approximate AWS cost | ~$5-10/day (NAT gateway + RDS are not free tier) |
| Stack | Terraform 1.7+, AWS provider ~5.0, VPC, EC2, RDS Postgres, ALB |

**Important:** Run `terraform destroy` when done. The NAT gateway and RDS instance accrue hourly charges.

---

## Acceptance Criteria

You've succeeded when:

1. `terraform apply` completes with no errors
2. `curl http://<alb_dns_name>/health` returns `{"status": "ok"}`
3. The RDS instance is NOT reachable from your laptop (only from EC2 in the private subnet)
4. Terminating one EC2 instance causes ASG to replace it within 3 minutes
5. `terraform destroy` cleanly removes all resources

---

## 📂 Navigation

**Prev:** [01 — JWT Auth API on EC2](../01_JWT_Auth_API_EC2/01_MISSION.md) &nbsp;&nbsp; **Next:** [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
