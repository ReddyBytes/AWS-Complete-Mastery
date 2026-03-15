<div align="center">

<img src="../docs/assets/aws_banner.svg" alt="AWS Mastery" width="100%"/>

# ☁️ AWS Mastery

[![AWS](https://img.shields.io/badge/AWS-F97316?style=for-the-badge&logo=amazonaws&logoColor=white)](#)
[![Cloud](https://img.shields.io/badge/Cloud_Engineering-EA580C?style=for-the-badge)](#)
[![Solutions Architect](https://img.shields.io/badge/Solutions_Architect-C2410C?style=for-the-badge)](#)

[![Stages](https://img.shields.io/badge/Stages-16-FB923C?style=flat-square)](#curriculum)
[![Files](https://img.shields.io/badge/Files-43+-FED7AA?style=flat-square)](#curriculum)
[![Level](https://img.shields.io/badge/Level-Beginner_to_Expert-F97316?style=flat-square)](#)

**From what is cloud to designing multi-region, AI-powered production architectures — the complete AWS journey.**

</div>

---

## Why AWS?

Amazon Web Services is the most widely used cloud platform in the world — 33% market share, used by Netflix, Airbnb, NASA, and millions of companies.

Every DevOps engineer, SRE, and backend developer works with AWS daily. This section covers every core AWS service with:
- **Story-based analogies** so concepts actually stick
- **Console walkthroughs** matching exactly what you see in AWS
- **Real production examples** from actual systems
- **Interview Q&A** to pass any cloud interview

---

## 🗺️ Learning Path

```
Foundations  ──►  Compute & Storage  ──►  Networking & Security  ──►  Databases
                                                                           │
AI/ML  ◄──  Cost  ◄──  Architecture  ◄──  DevOps  ◄──  Data  ◄──  Serverless
```

**Recommendation:** Complete Stages 01–07 before jumping ahead. Everything else builds on these foundations.

---

## 📚 Curriculum

### Stage 01–02 — Foundations

| Folder | What You Learn |
|--------|---------------|
| [01 Cloud Foundations](./01_cloud_foundations/) | What is cloud computing, IaaS vs PaaS vs SaaS, pricing models, shared responsibility |
| [02 Global Infrastructure](./02_global_infrastructure/) | Regions, Availability Zones, Edge Locations, free tier |

---

### Stage 03–04 — Compute & Storage

| Folder | What You Learn |
|--------|---------------|
| [03 Compute](./03_compute/) | EC2 instance types, AMIs, Auto Scaling, ALB/NLB, Elastic Beanstalk |
| [04 Storage](./04_storage/) | S3 storage classes, EBS volume types, EFS shared filesystem |

---

### Stage 05–07 — Networking, Security & Databases

| Folder | What You Learn |
|--------|---------------|
| [05 Networking](./05_networking/) | VPC, subnets, route tables, NAT gateway, Route 53, CloudFront |
| [06 Security](./06_security/) | IAM roles/policies, KMS encryption, Cognito, WAF, GuardDuty |
| [07 Databases](./07_databases/) | RDS, Aurora, DynamoDB, ElastiCache Redis |

---

### Stage 08–10 — Observability, IaC & Containers

| Folder | What You Learn |
|--------|---------------|
| [08 Monitoring](./08_monitoring/) | CloudWatch metrics/alarms/logs, CloudTrail, X-Ray, OpenTelemetry |
| [09 IaC](./09_iac/) | CloudFormation templates, CDK constructs, Terraform on AWS |
| [10 Containers](./10_containers/) | ECS + Fargate, EKS Kubernetes, ECR image registry |

---

### Stage 11–13 — Serverless, Data & DevOps

| Folder | What You Learn |
|--------|---------------|
| [11 Serverless](./11_serverless/) | Lambda, API Gateway, SQS, SNS, EventBridge, Step Functions |
| [12 Data Analytics](./12_data_analytics/) | Kinesis streams, Athena SQL on S3, Glue ETL, Redshift data warehouse |
| [13 DevOps/CICD](./13_devops_cicd/) | CodePipeline, CodeBuild, CodeDeploy, GitHub Actions with AWS |

---

### Stage 14–16 — Architecture, Cost & AI/ML

| Folder | What You Learn |
|--------|---------------|
| [14 Architecture](./14_architecture/) | Well-Architected 6 pillars, HA patterns, disaster recovery, RTO/RPO |
| [15 Cost Optimization](./15_cost_optimization/) | Reserved instances, Spot instances, Savings Plans, FinOps |
| [16 AI/ML](./16_ai_ml/) | Bedrock foundation models, Agents, Knowledge Bases (RAG), SageMaker |

---

### Stage 99 — Interview Master

| Folder | What You Learn |
|--------|---------------|
| [99 Interview Master](./99_interview_master/) | 100+ Q&As, architecture scenarios, service comparisons, SAA-C03 prep |

---

## ⚡ Quick Service Decision Guide

| I need to... | Use this |
|--------------|----------|
| Run a virtual machine | EC2 |
| Run code without servers | Lambda |
| Run Docker containers (simple) | ECS + Fargate |
| Run Kubernetes | EKS |
| Store files / objects | S3 |
| Fast persistent storage for EC2 | EBS gp3 |
| Shared file system across servers | EFS |
| Managed SQL database | RDS / Aurora |
| Scalable NoSQL | DynamoDB |
| Cache layer | ElastiCache Redis |
| DNS + routing | Route 53 |
| Global CDN | CloudFront |
| User authentication | Cognito |
| Async task queue | SQS |
| Pub/sub notifications | SNS |
| Multi-step workflows | Step Functions |
| Real-time stream processing | Kinesis |
| Serverless SQL on S3 | Athena |
| Call AI foundation models | Bedrock |
| Build AI agents | Bedrock Agents |
| Custom ML training | SageMaker |

---

<div align="center">

[![Back: Bash](https://img.shields.io/badge/←_Back:_Bash-F59E0B?style=for-the-badge&logo=gnubash&logoColor=white)](../02_Bash-Scripting/README.md)
[![Back to Root](https://img.shields.io/badge/←_Root-14B8A6?style=for-the-badge)](../README.md)
[![Next: Terraform](https://img.shields.io/badge/Next:_Terraform_→-7C3AED?style=for-the-badge&logo=terraform&logoColor=white)](../04_Terraform/README.md)

**Start:** [01 Cloud Foundations →](./01_cloud_foundations/)

</div>
