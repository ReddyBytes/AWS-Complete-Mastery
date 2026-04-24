# AWS Organizations and Multi-Account Strategy

Imagine a large office building. If every department — engineering, finance, legal, and the intern pool — shared a single floor with no walls, no access cards, and one shared petty cash drawer, chaos would follow. A junior intern could accidentally walk into the server room. A contractor could see the payroll spreadsheet. One accidental sprinkler test would soak everyone.

AWS Organizations is the building management system. It lets you create separate floors (accounts), each with its own access card rules, its own budget, and its own guardrails — all managed from a single control desk (the management account).

---

## 1. Why Multiple AWS Accounts

One AWS account for everything means:
- A junior developer's `aws ec2 terminate-instances` in a test script could reach production
- A misconfigured security group in staging exposes production subnets
- One compromised IAM key means access to everything
- No blast radius containment — every mistake is a company-wide event

Multiple accounts enforce **blast radius isolation** by default. A mistake in the dev account cannot touch the prod account. An IAM breach in a sandbox account cannot read prod secrets. Even AWS root users are scoped to their own account.

Secondary benefits:
- Independent billing visibility per team or environment
- Clean regulatory boundaries (PCI data in its own account)
- Independent service limits that do not compete across environments

---

## 2. AWS Organizations Overview

**AWS Organizations** is the service that groups AWS accounts into a managed hierarchy.

Core concepts:

- **Management account** (formerly "master account"): the account that creates and owns the organization. Billing flows here.
- **Organizational Units (OUs)**: folders in the tree. Accounts live inside OUs. OUs can nest.
- **Member accounts**: ordinary AWS accounts that belong to the org.
- **Root**: the top of the tree. Policies applied here affect every account.

```
Management Account
└── Root
    ├── OU: Security
    │   ├── Security Account
    │   └── Log Archive Account
    ├── OU: Infrastructure
    │   └── Shared Services Account
    ├── OU: Workloads
    │   ├── OU: Dev
    │   │   └── Dev Account
    │   ├── OU: Staging
    │   │   └── Staging Account
    │   └── OU: Prod
    │       └── Prod Account
    └── OU: Sandbox
        └── Developer Sandbox Accounts
```

**Consolidated billing**: all member account charges roll up to the management account. You see one bill. You also get volume discounts that apply across the whole org's combined usage (EC2 Reserved Instances, S3 storage tiers, etc.).

---

## 3. Standard Multi-Account Structure

The structure above is not arbitrary — it reflects how access, blast radius, and cost should be partitioned.

```
+-------------------+     Billing only. No workloads.
| Management        |     Root user locked down. MFA enforced.
+-------------------+

+-------------------+     GuardDuty master, Security Hub, CloudTrail
| Security          |     aggregation. Only security team has access.
+-------------------+

+-------------------+     Write-once log archive. CloudTrail logs from
| Log Archive       |     all accounts. Bucket policy: no delete.
+-------------------+

+-------------------+     Shared VPC, Active Directory, ECR registry,
| Shared Services   |     Route 53 private hosted zones. Accessed via
+-------------------+     RAM (Resource Access Manager) or VPC sharing.

+-------------------+     Feature development. Permissive SCPs.
| Dev               |     Developers have broad access.
+-------------------+

+-------------------+     Pre-production validation. Mirrors prod config.
| Staging           |     CI/CD deploys here automatically.
+-------------------+

+-------------------+     Strict SCPs. Production workloads.
| Prod              |     Minimal human access. All changes via pipeline.
+-------------------+
```

The rule: the management account never runs application workloads. It exists solely to manage the org and receive billing. Treat it like the building's master key: stored in a safe, only used for building management.

---

## 4. Service Control Policies (SCPs)

**Service Control Policies (SCPs)** are the guardrails of Organizations. They look like IAM policies but work differently: an SCP does not grant permissions — it sets the maximum permissions that any identity in that account (including root) can have.

Think of SCPs as the ceiling. IAM policies grant permissions up to that ceiling. You cannot punch through the ceiling with an IAM policy.

### Deny-list vs allow-list mode

- **Deny-list** (default): everything is allowed unless explicitly denied. An SCP that says `Deny: LeaveOrganization` blocks that one action.
- **Allow-list**: attach a policy that allows only specific actions. Everything else is implicitly denied. Useful for strict sandbox accounts.

### SCP: deny leaving the organization

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeaveOrg",
      "Effect": "Deny",
      "Action": "organizations:LeaveOrganization",
      "Resource": "*"
    }
  ]
}
```

### SCP: restrict to specific regions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNonApprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "support:*",
        "sts:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-east-1", "us-west-2"]
        }
      }
    }
  ]
}
```

Note: IAM, STS, Organizations, and Support are global services — they must be excluded from region restrictions.

### SCP: deny creating long-lived access keys

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyCreateAccessKey",
      "Effect": "Deny",
      "Action": "iam:CreateAccessKey",
      "Resource": "*"
    }
  ]
}
```

Apply to prod OUs where all access should be via roles, not static keys.

### SCP vs IAM policy

| | SCP | IAM Policy |
|---|---|---|
| Scope | Entire account (ceiling) | Specific principal (grant) |
| Applies to root user | Yes | No |
| Can grant permissions | No | Yes |
| Where attached | OU or account in Org | IAM user, role, or group |
| Evaluated | Before IAM policies | After SCP check passes |

---

## 5. Cross-Account IAM Roles

Accounts are isolated by default. The only way to operate across them is **role assumption**: Account A's principal asks Account B to create a temporary session via `sts:AssumeRole`.

The hotel analogy: you have a key to your room (your account). The maintenance crew from headquarters (another account) needs a way in. You grant them a passkey that works only between 9am and 5pm and only opens the closet, not the safe. That passkey is the cross-account role.

### Trust policy (in Account B)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::111122223333:role/DeployRole"   
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
```

The trust policy says who is allowed to assume the role. The permission policy (attached separately) says what they can do once they have assumed it.

### AWS CLI: assume a cross-account role

```bash
# Method 1: named profile in ~/.aws/config
[profile prod-deploy]
role_arn = arn:aws:iam::999988887777:role/DeployRole
source_profile = default
region = us-east-1

aws s3 ls --profile prod-deploy

# Method 2: inline with sts assume-role
CREDS=$(aws sts assume-role \
  --role-arn arn:aws:iam::999988887777:role/DeployRole \
  --role-session-name deploy-session \
  --query 'Credentials' --output json)

export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.SessionToken')
```

### Terraform: assume_role in provider block

```hcl
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = "arn:aws:iam::999988887777:role/TerraformRole"
    session_name = "terraform-session"
  }
}
```

---

## 6. AWS Control Tower

**AWS Control Tower** automates the manual setup described above. It builds a **Landing Zone**: a pre-configured OU structure, mandatory guardrails (SCPs), and baseline infrastructure — all from a single setup wizard.

What Control Tower does automatically:
- Creates Management, Security, and Log Archive accounts
- Applies pre-built SCPs ("guardrails") categorized as mandatory or elective
- Enables CloudTrail and AWS Config across all accounts
- Sets up cross-account logging to the Log Archive account

**Account Factory**: a self-service portal where teams request new AWS accounts. The account is provisioned with all baseline guardrails, CloudTrail, Config, and budget alerts already applied.

When to use Control Tower vs manual Organizations:

| Scenario | Use |
|---|---|
| New org, starting from scratch | Control Tower — get best practices by default |
| Existing org with custom structure | Manual Organizations — CT may conflict with existing setup |
| Need custom OU hierarchy | Manual — CT has an opinionated structure |
| 10+ accounts and want automated Account Factory | Control Tower |

---

## 7. Account Vending (New Account Creation)

Creating a new account should be automated and baseline-enforced, not a manual process that produces a bare empty account.

### Manual creation

AWS Organizations console → "Add an AWS account" → fill in account name and email. The account is created but has no guardrails, no CloudTrail, no Config.

### Automated: Account Factory for Terraform (AFT)

**AFT** is an open-source Terraform module (maintained by AWS) that wraps Control Tower's Account Factory API and automates the full provisioning pipeline.

```hcl
# Request a new account via AFT
module "new_account" {
  source = "github.com/aws-ia/terraform-aws-control_tower_account_factory"

  account_name                = "team-payments"
  account_email               = "aws-payments@company.com"
  ou_name                     = "Workloads/Prod"
  sso_user_email              = "owner@company.com"
}
```

Every new account automatically gets:
- CloudTrail enabled, logs sent to Log Archive account
- AWS Config enabled with recorder
- Budget alert at $500/month
- Mandatory SCPs from the parent OU

---

## 8. Networking Across Accounts

Account isolation extends to networking. VPCs in different accounts cannot talk to each other by default. Four patterns exist, each with different trade-offs.

```
Pattern           | Topology         | Transitive? | Use case
------------------|------------------|-------------|---------------------------
Shared VPC        | One VPC, N accts | Yes (shared)| Team isolation, shared net
VPC Peering       | Point-to-point   | No          | Two specific VPCs
Transit Gateway   | Hub-and-spoke    | Yes         | Hundreds of VPCs
PrivateLink       | Service endpoint | N/A         | Expose API, not network
```

**Shared VPC**: the networking account owns the VPC. It shares subnets to member accounts via AWS RAM. Workload accounts deploy EC2, ECS, etc. into those subnets but cannot modify them. One set of CIDR ranges, one routing table to manage.

**VPC Peering**: create a peering connection between exactly two VPCs. Traffic flows directly. Non-transitive: if A peers with B and B peers with C, A cannot reach C through B. Breaks down at scale.

**Transit Gateway**: a regional router that every VPC attaches to. All traffic flows through TGW. Transitive routing works. Attach VPCs from multiple accounts, on-prem connections (via Direct Connect or VPN), and other TGWs in other regions.

```
Account A VPC ──┐
Account B VPC ──┤── Transit Gateway ──── On-prem (Direct Connect)
Account C VPC ──┤
Account D VPC ──┘
```

**PrivateLink**: expose a specific service (NLB endpoint) to other accounts without giving them VPC access. The consumer account creates an interface endpoint and accesses the service via DNS — no VPC peering, no route table changes.

---

## 9. Cost Management Across Accounts

Consolidated billing gives you one bill but not automatic visibility per account. You add that through tagging and tooling.

**AWS Cost Explorer** with linked accounts: toggle the "Linked Account" dimension to see costs broken down by member account. Requires no setup — it works by default once accounts are in the org.

**Tagging strategy**: enforce a `CostCenter` or `Team` tag on every resource via Config rules or SCP conditions. Untagged resources become orphaned cost.

```bash
# Find untagged EC2 instances across all accounts (run from management account)
aws resourcegroupstaggingapi get-resources \
  --resource-type-filters ec2:instance \
  --tag-filters Key=CostCenter \
  --include-compliance-details \
  --query 'ResourceTagMappingList[?ComplianceDetails.ComplianceStatus==`false`]'
```

**Budget alerts per account**: set a monthly budget in every member account. Alert at 80% and 100% actual spend, and at 100% forecasted. Email the account owner.

**Reserved Instance (RI) sharing**: RIs purchased in any account in the org apply to matching usage across all accounts by default. This means your platform team can buy RIs centrally and all accounts benefit from the discount.

---

## 10. Terraform for Multi-Account

### Multiple provider blocks with assume_role

```hcl
# providers.tf

provider "aws" {
  alias  = "dev"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::111122223333:role/TerraformRole"
  }
}

provider "aws" {
  alias  = "prod"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::999988887777:role/TerraformRole"
  }
}

# Use the provider alias on each resource
resource "aws_s3_bucket" "app_dev" {
  provider = aws.dev
  bucket   = "myapp-dev-data"
}

resource "aws_s3_bucket" "app_prod" {
  provider = aws.prod
  bucket   = "myapp-prod-data"
}
```

### Separate state files per account

```hcl
# backend.tf for dev
terraform {
  backend "s3" {
    bucket = "tfstate-111122223333"     # ← dev account's state bucket
    key    = "app/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Store state in the account it describes. Cross-account state access is a security risk — it means your Terraform runner needs read access to every account's sensitive outputs.

### Module reuse across environments

```hcl
# Call the same module twice with different provider and variable sets
module "app_dev" {
  source   = "./modules/app"
  providers = { aws = aws.dev }
  env      = "dev"
  instance_type = "t3.small"
}

module "app_prod" {
  source   = "./modules/app"
  providers = { aws = aws.prod }
  env      = "prod"
  instance_type = "c5.2xlarge"
}
```

---

## 11. Common Mistakes

| Mistake | What goes wrong | Fix |
|---|---|---|
| Running workloads in management account | Blast radius includes billing and org management | Management account: billing only, no EC2/ECS/Lambda |
| No MFA on account root users | Root has unlimited access, no MFA = free access for attackers | Enable MFA on root in every account on day one |
| SCPs too permissive at OU level | Guardrails have gaps, prod accounts can create anything | Apply Deny-list SCPs explicitly; review regularly |
| Missing cost allocation tags | Cannot trace cost to team or service | Enforce tags via Config rules or SCP conditions at launch time |
| Stale cross-account roles | Old roles from decommissioned projects persist | Audit IAM roles with `last-used` date; remove unused ones |
| Flat OU structure | Cannot apply different SCPs to dev vs prod | Design OU hierarchy before creating accounts; hard to restructure later |
| Manual account creation with no baseline | Bare accounts have no CloudTrail, no Config, no alerts | Use AFT or Control Tower Account Factory for all account creation |

---

## Navigation

- Previous: [iam.md](../iam.md)
- Next: [kms.md](kms.md)
- Related: [vpc.md](../vpc.md) | [cloudtrail_config.md](cloudtrail_config.md)
