# 04 — Recap: Terraform Full AWS Stack

## What You Built

A complete, reproducible AWS infrastructure for an API. No console clicking. No manual steps to document and forget. Every resource is defined in code, reviewable in a pull request, and destroyable in one command.

---

## 3 Key Concepts

### 1. Terraform State Management

Terraform maintains a **state file** (`terraform.tfstate`) that maps your HCL resource definitions to real AWS resource IDs. When you run `plan`, Terraform compares the state file against your configuration and against the actual AWS API to determine what changes to make.

The danger: the state file is the source of truth. If you delete it, Terraform doesn't know it created those resources and will try to create duplicates. For teams, store state in an S3 backend with DynamoDB locking:

```hcl
backend "s3" {
  bucket         = "my-terraform-state"
  key            = "ecommerce-api/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-locks"  # ← prevents two people applying simultaneously
}
```

### 2. Resource Dependencies

Terraform builds a dependency graph automatically. When you write `subnet_id = aws_subnet.public[0].id`, Terraform knows the subnet must exist before this resource can be created.

Some dependencies aren't implicit — you have to declare them with `depends_on`. The NAT gateway needs the internet gateway attached to the VPC before it can be provisioned, so: `depends_on = [aws_internet_gateway.main]`.

### 3. Least-Privilege Security Groups

The pattern to internalize: each layer's security group only accepts traffic from the security group of the layer above it — not from a CIDR range. This means:

- Even if someone figures out the EC2 IP, they can't hit port 8000 directly (only the ALB SG can)
- Even if someone gets onto the EC2 instance, RDS port 5432 still won't accept connections from their laptop (only the EC2 SG can)

This is defense in depth at the network level.

---

## Common Failures and Fixes

| Error | Cause | Fix |
|---|---|---|
| "No VPC found" on subnet creation | Dependency issue | Add `vpc_id = aws_vpc.main.id` |
| Health check failing (unhealthy targets) | App not running on 8000 | Check user_data logs in `/var/log/user-data.log` on the instance |
| "InvalidDBSubnetGroup" on RDS | Subnet group needs 2+ AZs | Ensure you have private subnets in 2 different AZs |
| ALB DNS returns 502 | Target group has no healthy targets | User_data may have failed; use SSM Session Manager to SSH-less debug |
| "DuplicateResource" on re-apply | State file deleted or out of sync | Run `terraform import` to re-associate or `terraform refresh` |

---

## Extend It

**Add S3 for media storage**
Add `aws_s3_bucket` with an IAM policy attached to the EC2 role. The app can upload product images to S3 and serve them via CloudFront.

**Add ElastiCache for session caching**
Add a Redis ElastiCache cluster in private subnets. Connect EC2 via a new `elasticache_sg` that only allows inbound from `ec2_sg`. Session lookups drop from 5ms (RDS) to 0.1ms (Redis).

**Add Route53 DNS record**
Add `aws_route53_record` pointing your domain to the ALB. Combine with ACM certificate and an HTTPS listener on the ALB to get proper TLS.

**Enable RDS Multi-AZ**
Change `multi_az = false` to `multi_az = true`. RDS maintains a standby replica in a second AZ. Failover during maintenance or failure is automatic and takes ~60 seconds.

---

## ✅ What you mastered
- Declaring full AWS infrastructure as Terraform HCL
- Security group chaining for defense-in-depth networking
- ASG + ALB for automatic instance replacement and load distribution

## 🔨 What to build next
- Extract the flat resources into modules (networking, compute, database) and wire them together via outputs → inputs

## ➡️ Next project
Replace EC2 with containers that AWS manages: [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md)

---

## 📂 Navigation

**Prev:** [01 — JWT Auth API on EC2](../01_JWT_Auth_API_EC2/01_MISSION.md) &nbsp;&nbsp; **Next:** [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
