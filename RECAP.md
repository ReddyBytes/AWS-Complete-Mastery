# Linux-Terraform-AWS Mastery — Topic Recap

> One-line summary of every module. Use this to quickly review what each section covers before diving deeper.

---

## 01 — Linux

| Topic | Summary |
|---|---|
| Linux Fundamentals | History, distributions, kernel vs shell, why Linux powers the cloud |
| Filesystem Hierarchy | /, /etc, /var, /home, /proc — what lives where and why |
| Shell Basics | bash, zsh, terminal navigation, man pages, file operations |
| Users & Groups | adduser, passwd, sudo, /etc/passwd — multi-user system management |
| File Permissions | chmod, chown, rwx bits, setuid/setgid, umask |
| Processes | ps, top, kill, signals, foreground/background, process tree |
| Networking | ip, ifconfig, netstat, ss, ping, curl, /etc/hosts, DNS resolution |
| Package Management | apt, yum, dnf — installing, updating, removing software |
| System Administration | systemd, journalctl, cron jobs, log files, disk usage |

---

## 02 — Bash Scripting

| Topic | Summary |
|---|---|
| Shell Basics | Shebang, execution, PATH, variables, quoting rules |
| Variables & Data Types | String, integer, arrays, environment variables, export |
| Control Flow | if/elif/else, case, while, for, until loops |
| Functions | Defining, calling, arguments, return values, local scope |
| Input & Output | read, stdin/stdout/stderr, redirection, pipes, here-docs |
| Error Handling | exit codes, set -e, set -o pipefail, trap for cleanup |
| String Operations | Substring, length, pattern matching, sed, awk basics |
| Automation & Cron | crontab syntax, scheduling, log rotation, backup scripts |
| Real-World Scripts | Deploy scripts, health checks, file processing, API polling |

---

## 03 — AWS

| Topic | Summary |
|---|---|
| Cloud Foundations | IaaS/PaaS/SaaS, shared responsibility model, cloud economics |
| Global Infrastructure | Regions, AZs, edge locations, how AWS routes traffic |
| EC2 | Instance types, AMIs, key pairs, security groups, Elastic IPs |
| S3 | Buckets, objects, storage classes, lifecycle rules, versioning, presigned URLs |
| EBS & Storage | Block storage, volume types, snapshots, EFS shared storage |
| VPC & Networking | Subnets, route tables, IGW, NAT gateway, security groups, NACLs |
| IAM | Users, roles, policies, least privilege, instance profiles, STS |
| RDS & Databases | Managed Postgres/MySQL, Multi-AZ, read replicas, parameter groups |
| CloudWatch | Metrics, logs, alarms, dashboards, log insights queries |
| Elastic Load Balancing | ALB vs NLB, target groups, health checks, SSL termination |
| ECS & Containers | Task definitions, services, Fargate vs EC2 mode, ECR registry |
| Lambda & Serverless | Functions, triggers, event sources, concurrency, cold starts |
| Route 53 | DNS records, routing policies, health checks, domain registration |
| Infrastructure as Code | CloudFormation basics, CDK overview, parameter passing |
| CI/CD | CodePipeline, CodeBuild, CodeDeploy, GitHub Actions integration |
| Cost Optimization | Reserved instances, Savings Plans, Cost Explorer, tagging strategy |
| Security Best Practices | MFA, key rotation, S3 bucket policies, VPC flow logs, GuardDuty |

---

## 04 — Terraform

| Topic | Summary |
|---|---|
| What is Terraform | IaC concept, declarative vs imperative, idempotency, HCL |
| HCL Basics | Blocks, arguments, expressions, comments, .tf file structure |
| Providers & Resources | Provider configuration, resource blocks, resource lifecycle |
| Variables & Outputs | input variables, locals, output values, tfvars files |
| State Management | terraform.tfstate, remote backends (S3+DynamoDB), state locking |
| Modules | Reusable components, module sources, version pinning, registry |
| Workspaces | Environment isolation — dev/staging/prod with single config |
| AWS with Terraform | EC2, VPC, RDS, S3, IAM — full infrastructure examples |
| Best Practices | Naming conventions, DRY principles, remote state, CI/CD integration |

---

*Total modules: 4 · Last updated: 2026-04-21*
