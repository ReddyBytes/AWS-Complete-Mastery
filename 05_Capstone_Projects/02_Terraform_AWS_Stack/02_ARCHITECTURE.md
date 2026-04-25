# 02 — Architecture: Terraform Full AWS Stack

## The Big Picture

Think of this stack like a building: the VPC is the plot of land, subnets are floors, security groups are locked doors between floors, and the ALB is the lobby receptionist who directs visitors to the right EC2 apartment.

```
                    Internet
                        |
               [ Application Load Balancer ]
               |   listeners: :80, :443     |
               +---------------------------+
               |     Target Group          |
               | health check: GET /health |
               +---------------------------+
                     |         |
              AZ-a (us-east-1a) AZ-b (us-east-1b)
              +----------+   +----------+
              | EC2 inst |   | EC2 inst |  ← public subnets
              | (ASG)    |   | (ASG)    |
              +----------+   +----------+
                     |         |
              +----------+   +----------+
              | RDS      |   | RDS      |  ← private subnets
              | primary  |   | standby  |  (Multi-AZ)
              +----------+   +----------+

VPC CIDR: 10.0.0.0/16
  Public  subnets: 10.0.1.0/24 (AZ-a)  10.0.2.0/24 (AZ-b)
  Private subnets: 10.0.3.0/24 (AZ-a)  10.0.4.0/24 (AZ-b)
```

---

## Terraform Resource Dependency Tree

Terraform builds a dependency graph and creates resources in the right order. Resources that depend on others wait; independent resources are created in parallel.

```
aws_vpc
  └─ aws_subnet (x4: 2 public, 2 private)
       ├─ aws_internet_gateway  (attached to VPC)
       ├─ aws_nat_gateway       (in public subnet, needs EIP)
       │    └─ aws_eip
       ├─ aws_route_table (public)  → IGW
       ├─ aws_route_table (private) → NAT GW
       └─ aws_route_table_association (x4)

aws_security_group (alb_sg)   → VPC
aws_security_group (ec2_sg)   → VPC, alb_sg (ingress from ALB only)
aws_security_group (rds_sg)   → VPC, ec2_sg (ingress from EC2 only)

aws_lb               → alb_sg, subnets
aws_lb_target_group  → VPC
aws_lb_listener      → aws_lb, aws_lb_target_group

aws_db_subnet_group  → private subnets
aws_db_instance      → rds_sg, aws_db_subnet_group

aws_launch_template  → ec2_sg, user_data
aws_autoscaling_group → aws_launch_template, subnets, aws_lb_target_group
```

---

## Module Structure

For maintainability, split resources into modules. Each module is a folder with its own `main.tf`, `variables.tf`, and `outputs.tf`.

```
root/
├── main.tf          (calls modules, wires outputs to inputs)
├── variables.tf     (top-level inputs: region, db_password, etc.)
├── outputs.tf       (ALB DNS name, RDS endpoint)
├── providers.tf     (AWS provider + backend config)
└── modules/
    ├── networking/
    │   ├── main.tf      (VPC, subnets, IGW, NAT, route tables)
    │   ├── variables.tf (cidr_block, az_count, etc.)
    │   └── outputs.tf   (vpc_id, public_subnet_ids, private_subnet_ids)
    ├── compute/
    │   ├── main.tf      (launch template, ASG, ALB, target group)
    │   ├── variables.tf (vpc_id, subnet_ids, instance_type, etc.)
    │   └── outputs.tf   (alb_dns_name, asg_name)
    └── database/
        ├── main.tf      (RDS instance, subnet group, parameter group)
        ├── variables.tf (vpc_id, subnet_ids, db_password, etc.)
        └── outputs.tf   (rds_endpoint, rds_port)
```

---

## Security Group Rules

Each layer only accepts traffic from the layer above it. Nothing has open-to-internet access except the ALB.

```
Internet
  |
  | :80, :443 (0.0.0.0/0)
  v
[ ALB Security Group ]
  |
  | :8000 (from ALB SG only — not the internet)
  v
[ EC2 Security Group ]
  |
  | :5432 (from EC2 SG only — not the internet, not the ALB)
  v
[ RDS Security Group ]
```

This is **least-privilege networking**: even if an attacker compromises the ALB, they can't reach RDS directly. They'd also need to compromise an EC2 instance.

---

## Variable to Output Flow

```
terraform.tfvars
    │
    ├─ aws_region        → provider "aws" { region }
    ├─ db_password       → aws_db_instance.password
    ├─ instance_type     → aws_launch_template.instance_type
    └─ project_name      → Name tags on all resources
                                    │
                                    ▼
                            outputs.tf
                                    │
                            ├─ alb_dns_name   (from aws_lb.dns_name)
                            ├─ rds_endpoint   (from aws_db_instance.address)
                            └─ vpc_id         (from aws_vpc.id)
```

---

## Approximate Monthly Cost

| Resource | Size | ~$/month |
|---|---|---|
| EC2 (2x t3.micro) | 2 instances | $15 |
| Application Load Balancer | 1 ALB | $18 |
| NAT Gateway | 1 NAT GW | $32 |
| RDS Postgres | db.t3.micro, 20GB gp2 | $25 |
| Data transfer | minimal | $1 |
| **Total** | | **~$91/month** |

Note: NAT Gateway is the expensive part. For dev/test, you can skip NAT and put EC2 in public subnets instead. For production, private EC2 with NAT is the correct pattern.

---

## 📂 Navigation

**Prev:** [01 — JWT Auth API on EC2](../01_JWT_Auth_API_EC2/01_MISSION.md) &nbsp;&nbsp; **Next:** [03 — ECS Fargate Production](../03_ECS_Fargate_Production/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
