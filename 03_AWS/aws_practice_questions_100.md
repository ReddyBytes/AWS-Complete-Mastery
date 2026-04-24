# AWS Practice Questions — 100 Questions from Basics to Mastery

> Test yourself across the full AWS curriculum. Answers hidden until clicked.

---

## How to Use This File

1. **Read the question** — attempt your answer before opening the hint
2. **Use the framework** — run through the 5-step thinking process first
3. **Check your answer** — click "Show Answer" only after you've tried

---

## How to Think: 5-Step Framework

1. **Restate** — what is this question actually asking?
2. **Identify the concept** — which AWS feature/concept is being tested?
3. **Recall the rule** — what is the exact behaviour or rule?
4. **Apply to the case** — trace through the scenario step by step
5. **Sanity check** — does the result make sense? What edge cases exist?

---

## Progress Tracker

- [ ] **Tier 1 — Basics** (Q1–Q33): Fundamentals and core commands
- [ ] **Tier 2 — Intermediate** (Q34–Q66): Advanced features and real patterns
- [ ] **Tier 3 — Advanced** (Q67–Q75): Deep internals and edge cases
- [ ] **Tier 4 — Interview / Scenario** (Q76–Q90): Explain-it, compare-it, real-world problems
- [ ] **Tier 5 — Critical Thinking** (Q91–Q100): Predict output, debug, design decisions

---

## Question Type Legend

| Tag | Meaning |
|---|---|
| `[Normal]` | Recall + apply — straightforward concept check |
| `[Thinking]` | Requires reasoning about internals |
| `[Logical]` | Predict output or trace execution |
| `[Critical]` | Tricky gotcha or edge case |
| `[Interview]` | Explain or compare in interview style |
| `[Debug]` | Find and fix the broken code/config |
| `[Design]` | Architecture or approach decision |

---

## 🟢 Tier 1 — Basics

---

### Q1 · [Normal] · `cloud-fundamentals`

> **What are the 3 cloud service models (IaaS, PaaS, SaaS)? Give an AWS example of each.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- **IaaS** (Infrastructure as a Service): You manage the OS and above; the cloud manages hardware. Example: **EC2** — you get a virtual machine and configure everything on it.
- **PaaS** (Platform as a Service): You manage the application and data; the cloud manages the runtime, OS, and infrastructure. Example: **Elastic Beanstalk** — deploy code and AWS handles scaling, patching, and load balancing.
- **SaaS** (Software as a Service): You just use the software; everything else is managed. Example: **Amazon WorkMail** — a ready-to-use email service.

**How to think through this:**
1. Ask how much you manage vs. how much the cloud manages.
2. IaaS = most control (VMs), PaaS = middle ground (platforms), SaaS = least control (finished apps).
3. Match the model to how much operational responsibility you want to keep.

**Key takeaway:** The more you move from IaaS to SaaS, the less you manage — and the less you can customize.

</details>

📖 **Theory:** [cloud-fundamentals](./01_cloud_foundations/theory.md#stage-01--cloud-computing-foundations)


---

### Q2 · [Thinking] · `cloud-deployment-models`

> **What is the difference between public, private, hybrid, and multi-cloud? When would you choose each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- **Public cloud**: All resources run on a shared cloud provider (AWS, Azure, GCP). You own nothing physically. Choose when you want low upfront cost, global scale, and minimal ops burden.
- **Private cloud**: Infrastructure is dedicated to one organization — on-premises or hosted. Choose when you have strict data residency, compliance, or security requirements (e.g., government, finance).
- **Hybrid cloud**: A mix of on-premises (or private cloud) + public cloud, connected via a network (e.g., AWS Direct Connect). Choose when you're migrating gradually or need to keep sensitive workloads on-prem.
- **Multi-cloud**: Using two or more public cloud providers (e.g., AWS + GCP). Choose to avoid vendor lock-in, use best-in-class services, or meet geographic compliance needs.

**How to think through this:**
1. Start with your compliance and data sovereignty requirements.
2. If everything can go cloud-native, public cloud wins on cost and agility.
3. If you can't move everything, hybrid bridges the gap.
4. Multi-cloud adds resilience but multiplies operational complexity.

**Key takeaway:** Hybrid solves migration and compliance; multi-cloud solves vendor lock-in — both come with added complexity.

</details>

📖 **Theory:** [cloud-deployment-models](./01_cloud_foundations/theory.md#7-cloud-deployment-models)


---

### Q3 · [Normal] · `aws-global-infrastructure`

> **What is the difference between an AWS Region, Availability Zone (AZ), and Edge Location? Why does multi-AZ matter?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- **Region**: A geographic area containing multiple, isolated AZs (e.g., `us-east-1` — N. Virginia). Regions are completely independent. You choose a region based on latency, compliance, and service availability.
- **Availability Zone (AZ)**: One or more discrete data centers within a Region, each with redundant power, networking, and cooling. AZs in a region are connected by high-speed, low-latency private links. Example: `us-east-1a`, `us-east-1b`.
- **Edge Location**: A data center used by AWS CloudFront (CDN) and Route53 to cache and serve content closer to end users. There are many more edge locations than Regions.

**Why multi-AZ matters:** If one AZ goes down (power failure, network issue), your application keeps running in the other AZ. It is the foundation of high availability in AWS.

**How to think through this:**
1. Region = country/city-scale isolation.
2. AZ = data-center-scale isolation within a city.
3. Edge Location = CDN cache point for low-latency reads.

**Key takeaway:** Regions protect against geographic disasters; AZs protect against data center failures — always deploy across at least 2 AZs for production workloads.

</details>

📖 **Theory:** [aws-global-infrastructure](./02_global_infrastructure/theory.md#stage-02--aws-global-infrastructure)


---

### Q4 · [Normal] · `ec2-basics`

> **What is EC2? What are the 4 main instance purchasing options (On-Demand, Reserved, Spot, Dedicated)?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**EC2** (Elastic Compute Cloud) is AWS's virtual machine service. You rent compute capacity by the second or hour and control the OS, software, and configuration.

The 4 purchasing options:
- **On-Demand**: Pay by the second/hour with no commitment. Most flexible, most expensive. Use for unpredictable workloads or testing.
- **Reserved Instances (RI)**: Commit to 1 or 3 years for up to 72% discount. Use for steady, predictable workloads (e.g., web servers running 24/7).
- **Spot Instances**: Bid on unused AWS capacity — up to 90% cheaper, but AWS can terminate with 2-minute notice. Use for fault-tolerant, interruptible workloads (batch processing, ML training).
- **Dedicated Hosts/Instances**: Physical servers dedicated to you. Use for compliance requirements or software licenses tied to physical cores.

**How to think through this:**
1. Predictable + long-running → Reserved.
2. Bursty or unknown → On-Demand.
3. Fault-tolerant + cost-sensitive → Spot.
4. Regulatory or licensing requirement → Dedicated.

**Key takeaway:** Matching the purchasing model to your workload pattern is one of the biggest levers for reducing AWS costs.

</details>

📖 **Theory:** [ec2-basics](./03_compute/ec2.md#stage-03a--ec2-elastic-compute-cloud)


---

### Q5 · [Thinking] · `ec2-instance-types`

> **What do the EC2 instance family prefixes mean: `t`, `m`, `c`, `r`, `p`, `i`? When would you choose a `c` instance over an `m`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
| Prefix | Family | Optimized for |
|--------|--------|---------------|
| `t` | Burstable | Low baseline CPU with burst credits (e.g., `t3.micro`). Dev/test, low-traffic apps. |
| `m` | General purpose | Balanced CPU, memory, network. The default choice. |
| `c` | Compute optimized | High CPU-to-memory ratio. CPU-intensive workloads. |
| `r` | Memory optimized | High memory-to-CPU ratio. In-memory databases, caches. |
| `p` | Accelerated (GPU) | Machine learning training and inference. |
| `i` | Storage optimized | High IOPS local NVMe SSDs. Databases, data warehousing. |

**When to choose `c` over `m`:** Choose `c` when your workload is CPU-bound — e.g., video encoding, scientific simulations, high-performance web servers, or game servers. If your application saturates CPU but barely touches memory, `c` gives you more CPU per dollar than `m`.

**How to think through this:**
1. Start with `m` as the default.
2. Profile your app: is it CPU-bound, memory-bound, or I/O-bound?
3. Switch family based on the bottleneck.

**Key takeaway:** Instance families exist to match hardware ratios to workload profiles — don't pay for memory you don't need when `c` gives you more CPU for the same price.

</details>

📖 **Theory:** [ec2-instance-types](./03_compute/ec2.md#5-instance-types--choosing-the-right-size)


---

### Q6 · [Normal] · `ec2-lifecycle`

> **What are the EC2 instance states: pending, running, stopping, stopped, terminated? What is the difference between stopping and terminating?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
| State | Meaning |
|-------|---------|
| **Pending** | Instance is booting. Not yet billed for compute. |
| **Running** | Instance is live. Billed for compute by the second. |
| **Stopping** | Transitioning to stopped state. |
| **Stopped** | Instance is off. No compute charge, but EBS storage is still billed. |
| **Terminated** | Instance is permanently deleted. Cannot be recovered. |

**Stop vs. Terminate:**
- **Stop**: Like powering off a laptop. The instance and its EBS root volume persist. You can restart it later. The instance keeps its private IP (within the VPC) but gets a new public IP on restart (unless using Elastic IP).
- **Terminate**: Like throwing the laptop away. The instance is destroyed. By default, the root EBS volume is also deleted (DeleteOnTermination = true). This action is irreversible.

**How to think through this:**
1. Stop when you need to pause but plan to resume.
2. Terminate when you are done permanently.
3. Protect critical instances with termination protection to prevent accidental deletion.

**Key takeaway:** Stop is reversible; terminate is permanent — always double-check before terminating a production instance.

</details>

📖 **Theory:** [ec2-lifecycle](./03_compute/ec2.md#13-ec2-states--lifecycle)


---

### Q7 · [Normal] · `ec2-user-data`

> **What is EC2 User Data? When does it run? Give a use case for it.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**EC2 User Data** is a script (bash or PowerShell) you attach to an instance at launch. It runs automatically as **root** on the instance's **first boot only** — before the instance is available for use.

It is passed to the instance via the instance metadata service and executed by `cloud-init`.

**Use cases:**
- Install software packages on a fresh AMI (e.g., `yum install -y nginx`)
- Pull application code from S3 or a Git repo
- Write configuration files before the app starts
- Register the instance with a service discovery system

**Example:**
```
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
```

**How to think through this:**
1. User data runs once at first boot — use it for bootstrap automation.
2. It runs as root, so you have full access.
3. For recurring logic, use a configuration management tool (Ansible, SSM) instead.

**Key takeaway:** User data automates the first-boot setup of an instance so you never have to SSH in just to install software.

</details>

📖 **Theory:** [ec2-user-data](./03_compute/ec2.md#10-user-data--bootstrap-scripts)


---

### Q8 · [Normal] · `security-groups`

> **What is a security group? What is the difference between inbound and outbound rules? Are security groups stateful or stateless?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **security group** is a virtual firewall attached to an EC2 instance (or other AWS resource). It controls which traffic is allowed in and out at the instance level.

- **Inbound rules**: Control traffic coming INTO the instance. By default, all inbound traffic is denied.
- **Outbound rules**: Control traffic going OUT of the instance. By default, all outbound traffic is allowed.

**Stateful:** Security groups are stateful. If you allow an inbound request, the response traffic is automatically allowed out — you do not need a separate outbound rule for it. The connection state is tracked.

**How to think through this:**
1. Think of a security group as a bouncer — it checks the guest list for incoming traffic.
2. Stateful means the bouncer remembers who came in and lets them leave without re-checking.
3. You only define what is allowed; everything else is implicitly denied.

**Key takeaway:** Security groups are stateful allow-lists — you only write rules for what you want to permit, and return traffic is automatically handled.

</details>

📖 **Theory:** [security-groups](./05_networking/vpc.md#8-security-groups-vs-nacls)


---

### Q9 · [Thinking] · `nacl-vs-sg`

> **What is a Network ACL? How does it differ from a security group? Which one do you use for IP-level blocking?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **Network ACL (NACL)** is a firewall at the **subnet level** in a VPC. It evaluates traffic entering and leaving the subnet — before it ever reaches an instance.

| Feature | Security Group | Network ACL |
|---------|---------------|-------------|
| Applies to | Instance (ENI) | Subnet |
| Stateful? | Yes | No (stateless) |
| Rules | Allow only | Allow and Deny |
| Rule evaluation | All rules evaluated | Rules evaluated in order (lowest number first) |
| Default | Deny all inbound | Allow all (default NACL) |

**Stateless** means NACLs do not track connection state. If you allow inbound port 80, you must also explicitly allow outbound ephemeral ports (1024–65535) for the response to return.

**For IP-level blocking:** Use a **NACL**. Security groups cannot explicitly deny traffic — they only allow. NACLs support explicit DENY rules, making them the right tool to block a specific IP address or CIDR range.

**How to think through this:**
1. Security group = instance-level allow-list.
2. NACL = subnet-level allow/deny list with ordered rules.
3. Need to block a bad IP? NACL is your tool.

**Key takeaway:** Use NACLs to block specific IPs or CIDRs at the subnet boundary; use security groups to define what your instance accepts.

</details>

📖 **Theory:** [nacl-vs-sg](./05_networking/vpc.md#8-security-groups-vs-nacls)


---

### Q10 · [Normal] · `s3-basics`

> **What is Amazon S3? What is a bucket? What types of data can you store?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Amazon S3** (Simple Storage Service) is AWS's object storage service. It stores data as objects (files + metadata) rather than as a file system hierarchy or database rows. It is designed for 99.999999999% (11 nines) durability.

A **bucket** is a top-level container for objects in S3. Bucket names are globally unique across all AWS accounts. Objects inside a bucket are identified by a **key** (the full path-like name, e.g., `images/2024/photo.jpg`).

**Types of data you can store:**
- Static website assets (HTML, CSS, JS, images)
- Backups and archives
- Data lake raw files (CSV, Parquet, JSON)
- Application logs
- ML training datasets
- Software artifacts and deployment packages
- Any binary or text file up to 5 TB per object

**How to think through this:**
1. S3 is not a file system — it is a flat key-value store where keys can look like paths.
2. No compute is attached — it just stores and retrieves objects.
3. It scales infinitely; you never provision capacity.

**Key takeaway:** S3 is the universal storage layer of AWS — if you need to store any file durably and cheaply at scale, S3 is the default answer.

</details>

📖 **Theory:** [s3-basics](./04_storage/s3.md#stage-04a--s3-simple-storage-service)


---

### Q11 · [Normal] · `s3-storage-classes`

> **Name the S3 storage classes and when you'd use each (Standard, IA, Glacier, Intelligent-Tiering, One Zone-IA).**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
| Storage Class | Use Case | Retrieval |
|---------------|----------|-----------|
| **S3 Standard** | Frequently accessed data (web assets, active datasets) | Milliseconds |
| **S3 Standard-IA** (Infrequent Access) | Data accessed less than once a month but must be retrieved quickly when needed (backups, disaster recovery) | Milliseconds |
| **S3 One Zone-IA** | Infrequent access, but you can tolerate data loss if an AZ fails. Cheaper than Standard-IA. (Re-creatable data, secondary backups) | Milliseconds |
| **S3 Intelligent-Tiering** | Data with unknown or changing access patterns. AWS automatically moves objects between tiers. | Milliseconds |
| **S3 Glacier Instant Retrieval** | Archive data accessed ~once a quarter. Lowest cost for millisecond retrieval. | Milliseconds |
| **S3 Glacier Flexible Retrieval** | Archive data rarely accessed. Retrieval in minutes to hours. | Minutes–hours |
| **S3 Glacier Deep Archive** | Long-term archive, accessed once a year or less (compliance, legal holds). Cheapest storage. | 12 hours |

**How to think through this:**
1. Frequent access → Standard.
2. Infrequent but fast retrieval needed → Standard-IA.
3. Unknown patterns → Intelligent-Tiering.
4. Archival → Glacier family (pick based on how fast you need retrieval).

**Key takeaway:** The colder the storage class, the cheaper the storage cost — but the higher the retrieval cost and latency.

</details>

📖 **Theory:** [s3-storage-classes](./04_storage/s3.md#5-s3-storage-classes--the-cost-optimizer)


---

### Q12 · [Thinking] · `s3-versioning`

> **What does S3 versioning do? What happens when you delete an object from a versioned bucket?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**S3 versioning** keeps every version of every object in a bucket. When you upload a new version of an object, the old one is preserved with its version ID. This protects against accidental overwrites and deletions.

**When you delete an object from a versioned bucket:**
- S3 does NOT permanently delete the object.
- Instead, S3 adds a **delete marker** — a special, invisible placeholder that makes the object appear deleted when accessed without specifying a version.
- All previous versions still exist in the bucket and are still billed for storage.
- To permanently delete: you must explicitly delete each version by specifying its version ID.
- To restore: delete the delete marker, and the most recent real version becomes visible again.

**How to think through this:**
1. Versioning = a time machine for your objects.
2. Deleting without a version ID just adds a marker — the data lives on.
3. Permanent deletion requires targeting a specific version ID.

**Key takeaway:** Versioning turns deletes into recoverable events — you can always restore an object unless you explicitly delete all its versions.

</details>

📖 **Theory:** [s3-versioning](./04_storage/s3.md#stage-04a--s3-simple-storage-service)


---

### Q13 · [Normal] · `iam-basics`

> **What are the 4 IAM entity types: User, Group, Role, Policy? How do they relate to each other?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- **User**: A permanent identity representing a person or application. Has long-term credentials (username/password, access keys). Example: a developer who logs into the AWS console.
- **Group**: A collection of IAM users. You attach policies to groups and all users in the group inherit those permissions. Example: a "Developers" group with read access to S3.
- **Role**: A temporary identity assumed by a user, service, or application. Has no long-term credentials — it issues short-lived tokens via STS. Example: an EC2 instance assuming a role to write to S3.
- **Policy**: A JSON document defining permissions (Allow/Deny actions on resources). Policies are attached to users, groups, or roles — they do nothing on their own.

**Relationship:**
```
Policy --> attached to --> User / Group / Role
User --> can belong to --> Group (inherits group policies)
Role --> assumed by --> User, EC2, Lambda, other AWS services
```

**How to think through this:**
1. Policies = the rules. Entities = who the rules apply to.
2. Prefer groups over individual user policies for scale.
3. Prefer roles over users for AWS services and cross-account access.

**Key takeaway:** Policies define what; users, groups, and roles define who — always attach policies to roles or groups, never hardcode permissions per individual user.

</details>

📖 **Theory:** [iam-basics](./06_security/iam.md#stage-06a--iam-identity--access-management)


---

### Q14 · [Thinking] · `iam-policies`

> **What is the difference between an identity-based policy and a resource-based policy? What is a trust policy?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
- **Identity-based policy**: Attached to an IAM identity (user, group, role). Defines what actions that identity is allowed to perform on which resources. Example: attach a policy to a role that says "allow S3:GetObject on bucket X."
- **Resource-based policy**: Attached directly to an AWS resource (e.g., an S3 bucket policy, an SQS queue policy, a Lambda resource policy). Defines who is allowed to access that resource and what they can do. It specifies a `Principal` (the caller). Example: an S3 bucket policy that allows a specific AWS account to read objects.
- **Trust policy**: A special resource-based policy attached to an **IAM role** that defines who (which principal) is allowed to **assume** that role. Without a trust policy, no one can use the role. Example: a trust policy that lets EC2 (`ec2.amazonaws.com`) assume the role.

**How to think through this:**
1. Identity-based: "What can this identity do?"
2. Resource-based: "Who can access this resource?"
3. Trust policy: "Who can put on this role?"

**Key takeaway:** For a cross-account or service access to work, you often need both an identity-based policy on the caller AND a resource-based policy (or trust policy) on the target.

</details>

📖 **Theory:** [iam-policies](./06_security/iam.md#3-iam-policies--the-permission-blueprint)


---

### Q15 · [Interview] · `iam-least-privilege`

> **What is the principle of least privilege? Give 3 examples of applying it in AWS IAM.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The **principle of least privilege** means granting an identity only the minimum permissions it needs to perform its specific function — nothing more, nothing less. This limits the blast radius if credentials are compromised or a bug causes unintended behavior.

**3 examples in AWS IAM:**

1. **Scoped S3 access**: Instead of `s3:*` on `*`, give a Lambda function only `s3:GetObject` on a specific bucket ARN: `arn:aws:s3:::my-app-bucket/*`. The function can only read from that one bucket.

2. **Read-only role for a developer**: A junior developer reviewing logs gets a role with `logs:DescribeLogGroups`, `logs:GetLogEvents` — not `iam:*` or `ec2:TerminateInstances`.

3. **Condition-based restrictions**: Add `Condition` blocks to policies, e.g., allow EC2 `RunInstances` only if the instance type is `t3.micro` — preventing someone from accidentally launching expensive instances.

**How to think through this:**
1. Start with zero permissions and add only what is needed.
2. Scope by action, resource ARN, and conditions.
3. Audit with IAM Access Analyzer and AWS Access Advisor to remove unused permissions.

**Key takeaway:** Least privilege is not a one-time setup — it requires periodic review and tightening as application requirements evolve.

</details>

📖 **Theory:** [iam-least-privilege](./06_security/iam.md#stage-06a--iam-identity--access-management)


---

### Q16 · [Normal] · `vpc-basics`

> **What is a VPC? What is the difference between a public subnet and a private subnet?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **VPC** (Virtual Private Cloud) is your own logically isolated network within AWS. You define the IP address range (CIDR block, e.g., `10.0.0.0/16`), create subnets, configure routing, and control traffic flow. Think of it as your private data center network hosted in AWS.

**Public subnet vs. private subnet:**
| | Public Subnet | Private Subnet |
|--|--------------|----------------|
| Route to internet | Has a route to an **Internet Gateway** | No direct route to internet |
| Resources | Web servers, load balancers, bastion hosts | App servers, databases, internal services |
| Direct inbound traffic | Possible (with security group rules) | Not possible from internet |
| Outbound internet | Yes (directly via IGW) | Requires a NAT Gateway in a public subnet |

The distinction is entirely about routing — a subnet is "public" because its route table has a `0.0.0.0/0` route pointing to an Internet Gateway.

**How to think through this:**
1. Public = internet-facing tier (load balancers, NAT gateways).
2. Private = internal tier (application servers, databases).
3. Defense-in-depth: keep databases in private subnets so they are never directly reachable from the internet.

**Key takeaway:** "Public" and "private" in AWS subnets is about route tables, not just labels — a subnet is public only if it has a route to an Internet Gateway.

</details>

📖 **Theory:** [vpc-basics](./05_networking/vpc.md#stage-05--vpc-virtual-private-cloud)


---

### Q17 · [Normal] · `internet-gateway`

> **What is an Internet Gateway? What are the 3 things needed for a public subnet EC2 instance to reach the internet?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
An **Internet Gateway (IGW)** is a horizontally scaled, redundant, highly available VPC component that allows communication between your VPC and the internet. It performs NAT for instances with public IPs. You attach one IGW per VPC.

**3 things needed for a public subnet EC2 instance to reach the internet:**

1. **Internet Gateway attached to the VPC**: The VPC must have an IGW attached.
2. **Route table entry**: The subnet's route table must have a route `0.0.0.0/0 → igw-xxxxxxxx` pointing to the IGW.
3. **Public IP on the instance**: The EC2 instance must have a public IPv4 address (auto-assigned at launch) or an Elastic IP. Without a public IP, the IGW has no address to route traffic to.

(A security group allowing the relevant outbound traffic is also required, though the default security group allows all outbound.)

**How to think through this:**
1. IGW = the door out of the VPC.
2. Route table = the sign pointing to the door.
3. Public IP = the address on the envelope so responses can find you.

**Key takeaway:** All 3 must be in place simultaneously — missing any one of them breaks internet connectivity for a public subnet instance.

</details>

📖 **Theory:** [internet-gateway](./05_networking/vpc.md#6-internet-gateway-igw)


---

### Q18 · [Thinking] · `nat-gateway`

> **What is a NAT Gateway and why do private subnet instances need it? What is the difference between NAT Gateway and NAT Instance?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **NAT Gateway** (Network Address Translation Gateway) allows instances in a **private subnet** to initiate outbound connections to the internet (e.g., to download software updates, call external APIs) while preventing the internet from initiating inbound connections to those instances.

It lives in a **public subnet** and has a public IP. Private subnet instances route outbound internet traffic to the NAT Gateway, which forwards it to the IGW.

**NAT Gateway vs. NAT Instance:**
| Feature | NAT Gateway | NAT Instance |
|---------|-------------|--------------|
| Type | Managed AWS service | EC2 instance you manage |
| Availability | Highly available within an AZ | Single point of failure (unless you add HA manually) |
| Bandwidth | Scales automatically up to 100 Gbps | Limited by instance type |
| Maintenance | No patching needed | You patch the OS |
| Cost | Higher per-hour cost | Cheaper instance cost, but more ops work |
| Security groups | Not applicable | Can apply security groups |

**How to think through this:**
1. Private instances need outbound internet without being reachable inbound → NAT Gateway.
2. NAT Gateway is managed, scales, and is the production default.
3. NAT Instance is legacy — only used in cost-sensitive dev environments.

**Key takeaway:** Use NAT Gateway for production private subnet outbound internet access — it is managed, scalable, and eliminates a single point of failure.

</details>

📖 **Theory:** [nat-gateway](./05_networking/vpc.md#7-nat-gateway)


---

### Q19 · [Normal] · `rds-basics`

> **What is Amazon RDS? What is the difference between a DB instance and a DB cluster? What engines does RDS support?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Amazon RDS** (Relational Database Service) is a managed relational database service. AWS handles provisioning, patching, backups, monitoring, and failover — you manage the schema and queries.

- **DB Instance**: A single database server environment running one database engine. It has its own storage (EBS). Used by standard RDS deployments (MySQL, PostgreSQL, Oracle, SQL Server, MariaDB).
- **DB Cluster**: Used by **Amazon Aurora**. A cluster has one primary instance (read/write) and up to 15 Aurora Replicas (read). The cluster shares a single distributed storage layer (Aurora storage) across all instances — storage is not tied to individual instances.

**Supported engines:**
- MySQL
- PostgreSQL
- MariaDB
- Oracle
- Microsoft SQL Server
- Amazon Aurora (MySQL-compatible and PostgreSQL-compatible — AWS's proprietary engine)

**How to think through this:**
1. RDS standard engines = familiar databases, managed by AWS.
2. Aurora = AWS-built engine with cluster architecture, faster replication, and higher durability.
3. If you need open-source MySQL/PostgreSQL with cloud-native scale, Aurora is the upgrade path.

**Key takeaway:** RDS removes database administration toil; Aurora extends that with a distributed architecture that is faster and more resilient than standard RDS engines.

</details>

📖 **Theory:** [rds-basics](./07_databases/rds_aurora.md#stage-07a--rds--aurora-managed-relational-databases)


---

### Q20 · [Normal] · `rds-multi-az`

> **What is RDS Multi-AZ? What does it protect against? Is it used for read scaling?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**RDS Multi-AZ** is a high availability feature where AWS automatically provisions a **synchronous standby replica** of your DB instance in a different Availability Zone. All writes to the primary are synchronously replicated to the standby.

**What it protects against:**
- AZ-level failures (power outage, network disruption)
- Hardware failures on the primary instance
- Planned maintenance (OS patching, DB minor version upgrades) — failover happens automatically with minimal downtime (~60–120 seconds)

**Is it used for read scaling? No.**
The standby instance in Multi-AZ is not accessible for reads or writes. It is purely a passive failover target. Applications connect to a single DNS endpoint, and AWS handles routing to the primary (or promoting the standby on failure) — transparently.

**How to think through this:**
1. Multi-AZ = disaster recovery and HA, not performance.
2. The standby is invisible to your application.
3. For read scaling, use Read Replicas instead.

**Key takeaway:** Multi-AZ is for availability and durability, not performance — if you need to offload reads, add Read Replicas on top.

</details>

📖 **Theory:** [rds-multi-az](./07_databases/rds_aurora.md#4-rds-multi-az--high-availability)


---

### Q21 · [Thinking] · `rds-read-replicas`

> **What are RDS Read Replicas? How do they differ from Multi-AZ? Can you promote a read replica?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Read Replicas** are copies of your RDS database that use **asynchronous replication** from the primary. They are read-only and can be used to offload SELECT queries, reporting, and analytics workloads from the primary instance.

**Read Replicas vs. Multi-AZ:**
| Feature | Read Replica | Multi-AZ |
|---------|-------------|----------|
| Purpose | Read scaling / offload reads | High availability / failover |
| Replication | Asynchronous | Synchronous |
| Accessible? | Yes — for reads | No — passive standby only |
| Failover target? | Not automatic | Yes — automatic promotion |
| Cross-region? | Yes | No (same-region only for standard RDS) |
| Lag? | Possible replication lag | Minimal (synchronous) |

**Can you promote a read replica?**
Yes. You can manually promote a Read Replica to a standalone, independent DB instance (read-write). After promotion, it is no longer a replica and receives no further updates from the original primary. This is commonly used for disaster recovery or splitting off a separate database for a new application.

**How to think through this:**
1. Read-heavy app? Add Read Replicas and point your app's read connection to them.
2. Need automatic failover? Add Multi-AZ.
3. Promote a Read Replica when you need a fresh standalone DB from a point-in-time snapshot of production.

**Key takeaway:** Read Replicas scale reads; Multi-AZ scales availability — a production database often needs both.

</details>

📖 **Theory:** [rds-read-replicas](./07_databases/rds_aurora.md#5-read-replicas--read-scaling)


---

### Q22 · [Normal] · `lambda-basics`

> **What is AWS Lambda? What is the execution model (trigger → execute → return)?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**AWS Lambda** is a serverless compute service. You upload code (a function), and AWS runs it on-demand in response to events — no servers to provision, patch, or manage. You pay only for the compute time consumed (measured in milliseconds).

**Execution model:**

1. **Trigger**: An event source invokes the Lambda function. Triggers include: API Gateway (HTTP request), S3 (file uploaded), SQS (message in queue), EventBridge (scheduled event), DynamoDB Streams, SNS notification, and many more.
2. **Execute**: Lambda spins up a runtime environment (or reuses a warm one), loads your code, and calls your handler function with the event payload and a context object.
3. **Return**: Your handler returns a response (or void). Lambda captures the return value, sends it to the invoker if synchronous (e.g., API Gateway), and the execution environment idles or is recycled.

```
[Event Source] → Trigger → [Lambda Runtime] → Handler(event, context) → Return value → [Invoker]
```

**How to think through this:**
1. Lambda is event-driven — it does nothing until called.
2. You write a handler function; AWS handles the rest.
3. Stateless by design — each invocation should be independent.

**Key takeaway:** Lambda's model is "someone calls, you run, you return" — it eliminates server management entirely in exchange for stateless, event-driven execution.

</details>

📖 **Theory:** [lambda-basics](./11_serverless/lambda.md#stage-11a--lambda-serverless-compute)


---

### Q23 · [Normal] · `lambda-limits`

> **What are the key Lambda limits: max memory, max timeout, max package size, and max concurrent executions?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
| Limit | Value |
|-------|-------|
| **Max memory** | 128 MB to **10,240 MB** (10 GB) in 1 MB increments |
| **Max timeout** | **15 minutes** (900 seconds) |
| **Max deployment package size** | 50 MB (zipped, direct upload) / **250 MB** (unzipped, including layers) / **10 GB** (container image) |
| **Max concurrent executions** | **1,000 per region** (default, soft limit — can be increased via AWS Support) |
| **Max /tmp storage** | 10,240 MB (10 GB) |
| **Max environment variables** | 4 KB total |

**How to think through this:**
1. 15-minute timeout means Lambda is not for long-running jobs — use ECS/Batch/Glue for those.
2. Memory also controls CPU allocation — more memory = more CPU.
3. Concurrency limit is account-wide per region — a burst of traffic can exhaust it across all functions.
4. Package size limits matter for ML inference functions with large model weights — use container images (10 GB) in that case.

**Key takeaway:** Lambda's 15-minute timeout and 10 GB memory cap define its sweet spot — short-to-medium duration, event-driven tasks, not long-running processes.

</details>

📖 **Theory:** [lambda-limits](./11_serverless/lambda.md#stage-11a--lambda-serverless-compute)


---

### Q24 · [Thinking] · `lambda-cold-start`

> **What is a Lambda cold start? Why does it happen and how do you mitigate it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **cold start** is the latency added to a Lambda invocation when AWS must provision a new execution environment from scratch — downloading the code package, starting the runtime, and running any initialization code outside your handler. This happens when no warm (pre-existing) execution environment is available.

**Why it happens:**
- The function has not been invoked recently (environment was recycled).
- Traffic spikes require new environments to be provisioned in parallel.
- The function was just deployed or updated.

**Cold start duration varies by:**
- Runtime: JVM-based runtimes (Java, .NET) have longer cold starts than Python/Node.js/Go.
- Package size: Larger packages take longer to load.
- VPC attachment: VPC-attached Lambdas historically had slower cold starts (now improved with hyperplane ENIs, but still slightly slower).

**How to mitigate:**
1. **Provisioned Concurrency**: Pre-warm a specified number of execution environments. They are always initialized and ready. Eliminates cold starts for those instances (costs more).
2. **Choose a faster runtime**: Python and Node.js have much lower cold starts than Java.
3. **Keep the package small**: Minimize dependencies — only include what the function needs.
4. **Scheduled warmers** (legacy approach): Ping the function every few minutes with a dummy event — not recommended now that Provisioned Concurrency exists.

**How to think through this:**
1. Cold start = paying the initialization tax on the first request after idle.
2. For latency-sensitive production (API endpoints), use Provisioned Concurrency.
3. For async/batch functions, cold starts often don't matter.

**Key takeaway:** Cold starts are a Lambda trade-off for not managing servers — Provisioned Concurrency eliminates them at the cost of paying for idle warm instances.

</details>

📖 **Theory:** [lambda-cold-start](./11_serverless/lambda.md#7-cold-starts--the-main-trade-off)


---

### Q25 · [Normal] · `cloudwatch-basics`

> **What is CloudWatch? What is the difference between a Metric, Alarm, Log Group, and Log Stream?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Amazon CloudWatch** is AWS's monitoring and observability service. It collects metrics, logs, and events from AWS services and your applications, and lets you set alarms and create dashboards.

| Concept | Definition |
|---------|-----------|
| **Metric** | A time-series data point — a measurement over time. Example: EC2 `CPUUtilization` at 5-minute intervals. Metrics have a namespace, name, and optional dimensions (e.g., `InstanceId`). |
| **Alarm** | A rule that watches a metric and transitions between states: OK, ALARM, INSUFFICIENT_DATA. When in ALARM state, it can trigger an action — send an SNS notification, scale an Auto Scaling Group, or stop an EC2 instance. |
| **Log Group** | A container for log streams that share the same retention settings and access controls. Typically one log group per application or service. Example: `/aws/lambda/my-function`. |
| **Log Stream** | A sequence of log events from a single source within a log group. For Lambda, each function instance creates its own log stream. For EC2, each instance has its own stream within the group. |

**How to think through this:**
1. Metric → numerical time-series data (CPU%, request count, latency).
2. Alarm → "notify me when this metric crosses a threshold."
3. Log Group → the folder for logs from a service.
4. Log Stream → the individual log file from one instance/execution.

**Key takeaway:** CloudWatch ties together metrics (numbers over time), alarms (triggered reactions), and logs (raw event text) into a single observability platform.

</details>

📖 **Theory:** [cloudwatch-basics](./08_monitoring/cloudwatch.md#stage-08--cloudwatch--observability)


---

### Q26 · [Normal] · `route53-basics`

> **What is Route53? What are A, CNAME, ALIAS, and MX record types? What is the difference between A and ALIAS?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Amazon Route53** is AWS's managed DNS (Domain Name System) service. It routes end-user requests to AWS infrastructure (or external endpoints) by resolving domain names to IP addresses. It also supports health checks and DNS-based routing policies (latency, geolocation, failover, weighted).

**Record types:**
| Record | Purpose |
|--------|---------|
| **A** | Maps a hostname to an IPv4 address. Example: `app.example.com → 1.2.3.4` |
| **CNAME** | Maps a hostname to another hostname. Example: `www.example.com → app.example.com`. Cannot be used at the zone apex (root domain). |
| **ALIAS** | AWS-specific extension. Maps a hostname to an AWS resource DNS name (ALB, CloudFront, S3 website, etc.). Works at the zone apex. Free of charge for queries. |
| **MX** | Mail Exchange — specifies the mail server for a domain. Used for email routing. |

**A vs. ALIAS:**
- **A record**: Points to a static IPv4 address. If the IP changes, you must update the record.
- **ALIAS record**: Points to an AWS resource's DNS name. Route53 resolves the alias target's current IPs dynamically — if an ALB's IPs change, ALIAS keeps working automatically. It also works at the zone apex (e.g., `example.com` itself, not just subdomains) — something CNAME cannot do.

**How to think through this:**
1. Use A for static IPs.
2. Use ALIAS for AWS resources (ALB, CloudFront, S3) — especially at the root domain.
3. Use CNAME for subdomains pointing to external hostnames.

**Key takeaway:** ALIAS is Route53's smarter alternative to CNAME — it works at the zone apex and automatically tracks AWS resource IPs without extra cost.

</details>

📖 **Theory:** [route53-basics](./05_networking/route53_cloudfront.md#stage-05b--route-53--cloudfront)


---

### Q27 · [Normal] · `elb-basics`

> **What are the 3 types of AWS load balancers (ALB, NLB, CLB)? What layer does each operate at?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
| Load Balancer | Full Name | OSI Layer | Protocol |
|--------------|-----------|-----------|----------|
| **ALB** | Application Load Balancer | Layer 7 (Application) | HTTP, HTTPS, WebSocket, gRPC |
| **NLB** | Network Load Balancer | Layer 4 (Transport) | TCP, UDP, TLS |
| **CLB** | Classic Load Balancer | Layer 4 and 7 (legacy) | HTTP, HTTPS, TCP, SSL |

**ALB** understands HTTP — it can route based on URL path (`/api` vs `/web`), hostname, headers, query strings, and HTTP methods. Best for microservices and web applications.

**NLB** operates at the TCP/UDP level with no understanding of HTTP. It is extremely fast (handles millions of requests/second with ultra-low latency) and preserves the client source IP. Best for real-time gaming, IoT, financial trading, or any non-HTTP protocol.

**CLB** is the original load balancer — now legacy. AWS recommends migrating to ALB or NLB. It lacks the advanced routing features of ALB and the performance of NLB.

**How to think through this:**
1. HTTP/HTTPS web app → ALB (path-based routing, SSL termination, host-based routing).
2. Non-HTTP or extreme performance → NLB.
3. CLB → migrate away from it.

**Key takeaway:** ALB is the default for web applications; NLB is for performance-critical non-HTTP workloads — CLB is legacy and should be avoided for new architectures.

</details>

📖 **Theory:** [elb-basics](./03_compute/ec2.md#stage-03a--ec2-elastic-compute-cloud)


---

### Q28 · [Critical] · `alb-vs-nlb`

> **When would you choose an ALB over an NLB? What are the key differences in behavior?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Choose ALB when:**
- You need content-based routing (different URL paths to different target groups, e.g., `/api` → API servers, `/static` → S3)
- You need host-based routing (multiple domains on one load balancer)
- You need to inspect and route based on HTTP headers, cookies, or query parameters
- You are running microservices or container-based apps (ECS/EKS) where each service has its own path
- You need native HTTP/2, gRPC, or WebSocket support
- You need WAF (Web Application Firewall) integration

**Choose NLB when:**
- You need sub-millisecond latency and maximum throughput
- You are routing non-HTTP protocols (TCP, UDP, custom protocols)
- You need to preserve the original client IP address on the server (NLB does this natively; ALB uses `X-Forwarded-For`)
- You need static IP addresses for the load balancer (NLB supports Elastic IPs per AZ)
- You are handling extreme traffic volumes (millions of requests/second)

**Key behavioral differences:**
| | ALB | NLB |
|--|-----|-----|
| Routing logic | Content-aware (L7) | Connection-based (L4) |
| Latency | ~milliseconds | ~microseconds |
| Static IP | No (DNS-based) | Yes (Elastic IP per AZ) |
| Source IP preservation | X-Forwarded-For header | Native (no header needed) |
| SSL termination | Yes | Yes (TLS passthrough also available) |

**How to think through this:**
1. Ask: does the load balancer need to read the HTTP content to make routing decisions? → ALB.
2. Ask: does performance, protocol, or static IP matter more than routing logic? → NLB.

**Key takeaway:** ALB is smarter about HTTP traffic; NLB is faster and protocol-agnostic — pick based on whether your routing decisions live at the application layer or the network layer.

</details>

📖 **Theory:** [alb-vs-nlb](./03_compute/ec2.md#stage-03a--ec2-elastic-compute-cloud)


---

### Q29 · [Normal] · `auto-scaling`

> **What is an Auto Scaling Group? What are the 3 scaling policies: target tracking, step scaling, simple scaling?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
An **Auto Scaling Group (ASG)** is a collection of EC2 instances managed as a logical unit. It automatically launches or terminates instances to maintain a desired capacity, respond to load changes, or replace unhealthy instances. You define a minimum, maximum, and desired number of instances.

**3 scaling policies:**

1. **Simple Scaling**: Trigger a single scaling action when a CloudWatch alarm fires. After the action, there is a cooldown period before another action can occur. Example: "When CPU > 70%, add 1 instance. Wait 300 seconds." Oldest and least flexible.

2. **Step Scaling**: Like simple scaling, but defines multiple scaling steps based on the alarm breach magnitude. No cooldown — scaling continues as metrics change. Example: "CPU 70–80%: add 1. CPU 80–90%: add 2. CPU > 90%: add 4." More responsive than simple scaling.

3. **Target Tracking Scaling**: You set a target metric value (e.g., "keep average CPU at 50%") and AWS automatically calculates and applies the scaling actions needed to maintain that target. Similar to a thermostat — the most hands-off and recommended for most workloads.

**How to think through this:**
1. Target tracking = set-it-and-forget-it; AWS does the math.
2. Step scaling = more control over scaling increments based on severity.
3. Simple scaling = legacy, basic; avoid for new designs.

**Key takeaway:** Target tracking is the modern default for ASGs — it automatically scales to maintain a metric target without you writing alarm logic.

</details>

📖 **Theory:** [auto-scaling](./03_compute/auto_scaling.md#stage-03b--auto-scaling--load-balancing)


---

### Q30 · [Normal] · `sqs-basics`

> **What is SQS? What is the difference between Standard and FIFO queues?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Amazon SQS** (Simple Queue Service) is a fully managed message queuing service. It decouples producers (components that send messages) from consumers (components that process messages). Producers put messages in the queue; consumers poll and process them at their own pace. This prevents a slow consumer from blocking or crashing a fast producer.

**Standard vs. FIFO queues:**
| Feature | Standard Queue | FIFO Queue |
|---------|---------------|------------|
| **Throughput** | Nearly unlimited (high throughput) | Up to 3,000 msg/sec with batching, 300 msg/sec without |
| **Ordering** | Best-effort ordering (not guaranteed) | Strict FIFO — messages processed in exact order sent |
| **Delivery** | At-least-once (occasional duplicates possible) | Exactly-once processing (deduplication built in) |
| **Use case** | High-volume async tasks where order and duplicates are tolerable (image processing, log ingestion) | Order-sensitive workflows (financial transactions, inventory updates, e-commerce order processing) |
| **Naming** | Any name | Must end in `.fifo` |

**How to think through this:**
1. Don't care about order, need max throughput → Standard.
2. Order matters or duplicates cause problems → FIFO.
3. FIFO has a throughput ceiling — design around it for high-volume FIFO needs.

**Key takeaway:** SQS decouples services; Standard maximizes throughput while FIFO maximizes correctness — choose based on whether ordering and exactly-once delivery matter for your workload.

</details>

📖 **Theory:** [sqs-basics](./11_serverless/sqs_sns_eventbridge.md#stage-11c--sqs-sns--eventbridge)


---

### Q31 · [Thinking] · `sns-basics`

> **What is SNS? How does it differ from SQS? What is the fan-out pattern?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Amazon SNS** (Simple Notification Service) is a fully managed pub/sub messaging service. A **publisher** sends a message to an SNS **topic**, and SNS instantly delivers it to all **subscribers** of that topic. Subscribers can be SQS queues, Lambda functions, HTTP endpoints, email addresses, SMS, or mobile push notifications.

**SNS vs. SQS:**
| | SNS | SQS |
|--|-----|-----|
| Model | Pub/Sub (push) | Queue (poll) |
| Delivery | Pushed immediately to all subscribers | Consumer polls and pulls messages |
| Persistence | No — message is gone if delivery fails (no retry storage) | Yes — messages persist until processed or expire |
| Consumers | Many simultaneously | Typically one consumer group |
| Direction | One-to-many | Point-to-point (or competing consumers) |

**Fan-out pattern:**
The fan-out pattern combines SNS and SQS. A single SNS topic has multiple SQS queues as subscribers. When a message is published to the topic, it is simultaneously delivered to all subscribed queues. Each queue is processed independently by a different consumer/service.

```
Publisher → SNS Topic → SQS Queue A → Service A
                     → SQS Queue B → Service B
                     → SQS Queue C → Service C
```

**Use case:** An e-commerce order event fans out to an inventory service, a fulfillment service, and a notifications service — all in parallel and independently.

**How to think through this:**
1. SNS = broadcast ("tell everyone at once").
2. SQS = buffer ("hold the message until someone picks it up").
3. Fan-out = SNS + SQS together for parallel async processing.

**Key takeaway:** SNS pushes to many; SQS buffers for one — combining them in the fan-out pattern gives you parallel, decoupled, durable processing of the same event.

</details>

📖 **Theory:** [sns-basics](./11_serverless/sqs_sns_eventbridge.md#stage-11c--sqs-sns--eventbridge)


---

### Q32 · [Normal] · `cloudformation-basics`

> **What is CloudFormation? What is a stack? What is the difference between a template and a stack?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**AWS CloudFormation** is AWS's Infrastructure as Code (IaC) service. You define AWS resources (EC2, S3, RDS, VPC, etc.) in a declarative template file, and CloudFormation provisions, updates, and deletes those resources automatically — ensuring your infrastructure matches what the template describes.

- **Template**: A JSON or YAML file that describes the desired AWS resources and their configurations. It is the blueprint. Templates are not infrastructure themselves — they are instructions. You can reuse the same template to create infrastructure in multiple accounts or regions.

- **Stack**: The actual set of AWS resources created and managed by CloudFormation when you deploy a template. A stack is the running instance of a template. CloudFormation tracks all resources in the stack and manages them as a unit — create, update, and delete together.

**Analogy:** Template = recipe. Stack = the meal you cooked from that recipe. The same recipe (template) can produce many meals (stacks) in different environments.

**How to think through this:**
1. Write a template once, deploy it as many stacks as needed (dev, staging, prod).
2. Updates to the stack come from updating the template and running a stack update — CloudFormation calculates the diff and applies only the changes needed.
3. Deleting a stack deletes all resources it created (unless you set deletion policies).

**Key takeaway:** Templates are reusable blueprints; stacks are living infrastructure — CloudFormation bridges the two by treating infrastructure changes like code deployments.

</details>

📖 **Theory:** [cloudformation-basics](./09_iac/cloudformation.md#stage-09a--cloudformation-infrastructure-as-code)


---

### Q33 · [Interview] · `iam-roles-ec2`

> **What is an instance profile? How does an EC2 instance assume an IAM role without storing credentials?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
An **instance profile** is a container for an IAM role that is attached to an EC2 instance. When you associate a role with an EC2 instance in the console, AWS automatically creates an instance profile with the same name. The instance profile is the mechanism that passes the role to the EC2 instance.

**How it works without storing credentials:**

1. You attach an IAM role (via an instance profile) to the EC2 instance at launch or afterward.
2. The **EC2 Instance Metadata Service (IMDS)** exposes temporary credentials at a well-known local address: `http://169.254.169.254/latest/meta-data/iam/security-credentials/<role-name>`
3. The AWS SDKs and CLI automatically query this endpoint — no configuration needed.
4. The credentials returned are **temporary STS tokens** (Access Key ID, Secret Access Key, Session Token) that expire every few hours and are automatically rotated by AWS.
5. Your code calls AWS APIs using these temporary credentials — no secrets are ever stored in environment variables, config files, or code.

**Why this is secure:**
- Credentials are short-lived and auto-rotate.
- Credentials never touch disk or leave the instance in a persistent form.
- No human ever handles or copies the secret.

**How to think through this:**
1. Instance profile = the hook that attaches the role to the EC2 instance.
2. IMDS = the vending machine that hands out temporary credentials on demand.
3. SDKs handle the polling and rotation automatically — you just write code that calls AWS APIs.

**Key takeaway:** Instance profiles eliminate the need to store AWS credentials on EC2 — the instance fetches short-lived tokens from the metadata service automatically, making credential rotation invisible and secure.

</details>

📖 **Theory:** [iam-roles-ec2](./06_security/iam.md#4-iam-roles--the-right-way-for-applications)


---

## 🟡 Tier 2 — Intermediate

### Q34 · [Normal] · `vpc-peering`

> **What is VPC Peering? What is transitive peering and why doesn't AWS support it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
VPC Peering is a direct, private network connection between two VPCs that lets instances in each VPC communicate as if they were on the same network. It works within the same AWS account, across accounts, and across regions (inter-region peering).

**How to think through this:**
1. When you peer VPC-A with VPC-B, and VPC-B with VPC-C, you get A↔B and B↔C connections.
2. Transitive peering would mean traffic from A can route *through* B to reach C — but AWS does not allow this.
3. AWS VPC routing is non-transitive by design: each peering connection is its own isolated route. If A needs to talk to C, you must create a direct A↔C peering connection.
4. The reason: AWS's hypervisor-level networking does not forward packets across peering boundaries. Each peering connection is a point-to-point construct, not a router.

**Key takeaway:** VPC Peering is point-to-point only — if you need hub-and-spoke or transitive routing across many VPCs, use Transit Gateway instead.

</details>

📖 **Theory:** [vpc-peering](./05_networking/vpc.md#9-vpc-peering)


---

### Q35 · [Normal] · `vpc-endpoints`

> **What are VPC Endpoints (Interface and Gateway)? Why would you use one instead of a NAT Gateway for S3 access?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A VPC Endpoint lets resources inside a VPC communicate with AWS services privately, without traffic leaving the AWS network or requiring an internet gateway, NAT gateway, or VPN.

**How to think through this:**
1. **Gateway Endpoint** — supports only S3 and DynamoDB. It works by adding an entry to your route table that directs traffic for those services to the endpoint. Free to use.
2. **Interface Endpoint (PrivateLink)** — supports most other AWS services (SQS, SNS, KMS, ECR, etc.). It creates an Elastic Network Interface (ENI) with a private IP inside your subnet. Costs per hour + per GB.
3. Without an endpoint, an EC2 instance in a private subnet must route S3 traffic through a NAT Gateway. NAT Gateway charges $0.045/hr + $0.045/GB processed — expensive for high-volume S3 workloads.
4. A Gateway Endpoint for S3 is free and keeps traffic entirely within AWS's backbone network, improving both cost and security posture.

**Key takeaway:** Use a Gateway Endpoint for S3/DynamoDB access from private subnets — it's free, keeps traffic off the public internet, and eliminates NAT Gateway data-processing charges.

</details>

📖 **Theory:** [vpc-endpoints](./05_networking/vpc.md#10-vpc-endpoints-private-connectivity-to-aws-services)


---

### Q36 · [Normal] · `transit-gateway`

> **What is AWS Transit Gateway? How does it simplify multi-VPC connectivity compared to VPC peering?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Transit Gateway (TGW) is a regional network hub that acts as a central router connecting multiple VPCs, on-premises networks (via VPN or Direct Connect), and even other Transit Gateways across regions.

**How to think through this:**
1. With VPC peering, connecting N VPCs requires up to N×(N-1)/2 individual peering connections (full mesh). With 10 VPCs that's 45 connections — each needing its own route table entries and management.
2. Transit Gateway collapses this to N attachments, one per VPC, all connecting to the central hub. The TGW handles routing between all attached networks.
3. TGW supports transitive routing (which VPC peering does not), route table segmentation (to isolate environments), and multicast.
4. TGW charges per attachment-hour and per GB of data processed, so it adds cost — but at scale it's far simpler operationally.

**Key takeaway:** Transit Gateway replaces a full-mesh of VPC peering connections with a hub-and-spoke model, enabling transitive routing and centralizing network management.

</details>

📖 **Theory:** [transit-gateway](./05_networking/vpc.md#12-transit-gateway)


---

### Q37 · [Normal] · `security-kms`

> **What is AWS KMS? What is the difference between a CMK and an AWS-managed key? What is envelope encryption?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
AWS Key Management Service (KMS) is a managed service for creating and controlling cryptographic keys used to encrypt data across AWS services and your own applications.

**How to think through this:**
1. **AWS-managed key** — automatically created by an AWS service (e.g., `aws/s3`, `aws/ebs`) when you enable encryption. You cannot manage, rotate, or use these keys directly in your own API calls. Free.
2. **Customer-managed key (CMK)** — a key you create and control in KMS. You define the key policy, can enable automatic rotation (annually), audit usage in CloudTrail, and use it directly with `Encrypt`/`Decrypt` API calls. Costs $1/month per key.
3. **Envelope encryption** — KMS never encrypts your raw data directly (KMS has a 4KB payload limit). Instead: KMS generates a **data encryption key (DEK)**, you encrypt your data locally with the DEK, then KMS encrypts the DEK itself using your CMK. You store the encrypted DEK alongside the encrypted data. To decrypt: call KMS to decrypt the DEK, then use the plaintext DEK locally.
4. This pattern keeps large data off the KMS API, reduces latency, and means the plaintext DEK lives in memory only as long as needed.

**Key takeaway:** Envelope encryption separates the key used to encrypt data (DEK) from the master key (CMK) — only the small DEK travels to KMS, keeping large data encryption fast and local.

</details>

📖 **Theory:** [security-kms](./06_security/kms.md#stage-06b--kms--encryption-protect-your-data)


---

### Q38 · [Normal] · `security-iam-advanced`

> **What is an IAM permission boundary? What is a Service Control Policy (SCP) in AWS Organizations?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Both are mechanisms to set maximum permission ceilings — but they operate at different scopes.

**How to think through this:**
1. **Permission Boundary** — an IAM policy attached to a user or role that defines the *maximum* permissions that entity can ever have, regardless of identity-based policies. Effective permissions = identity policy ∩ permission boundary. Used to safely delegate IAM creation to developers (they can create roles, but only within the boundary you set).
2. **SCP (Service Control Policy)** — a policy attached at the AWS Organizations level (root, OU, or account). It defines the maximum permissions for *all* IAM principals in that account or OU — including the root user. SCPs do not grant permissions; they restrict what can be granted.
3. Effective permissions for an IAM principal in an Organizations account = SCP ∩ permission boundary ∩ identity policy.
4. Example SCP: deny all actions outside `us-east-1` to enforce data residency. No individual IAM policy can override this.

**Key takeaway:** Permission boundaries constrain individual IAM entities; SCPs constrain entire AWS accounts — both define ceilings, neither grants permissions.

</details>

📖 **Theory:** [security-iam-advanced](./06_security/iam.md#stage-06a--iam-identity--access-management)


---

### Q39 · [Normal] · `security-cognito`

> **What is Amazon Cognito? What is the difference between a User Pool and an Identity Pool?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Amazon Cognito is a managed service for authentication, authorization, and user management for web and mobile applications.

**How to think through this:**
1. **User Pool** — a user directory. It handles sign-up, sign-in, password policies, MFA, and OAuth 2.0 / OIDC flows. After a successful login, it issues JWT tokens (ID token, access token, refresh token). Think of it as your identity provider.
2. **Identity Pool (Federated Identities)** — exchanges tokens (from a User Pool, Google, Facebook, SAML, etc.) for temporary AWS credentials via STS. These credentials allow the user to call AWS services directly (e.g., upload to S3, query DynamoDB). Think of it as your AWS access broker.
3. Common pattern: User Pool authenticates the user → returns JWT → Identity Pool receives JWT → calls STS `AssumeRoleWithWebIdentity` → returns short-lived IAM credentials → app calls AWS directly.
4. You can use them independently: a User Pool alone for app authentication without AWS service access; an Identity Pool alone if you already have an external IdP.

**Key takeaway:** User Pools handle who you are (authentication + JWTs); Identity Pools handle what AWS resources you can access (temporary IAM credentials).

</details>

📖 **Theory:** [security-cognito](./06_security/cognito.md#stage-06d--cognito-user-authentication--authorization)


---

### Q40 · [Normal] · `dynamodb-basics`

> **What is DynamoDB? What is the difference between a partition key and a sort key? What are the read/write capacity modes?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
DynamoDB is a fully managed, serverless NoSQL key-value and document database designed for single-digit millisecond performance at any scale.

**How to think through this:**
1. **Partition key (PK)** — the primary key attribute. DynamoDB hashes it to determine which physical partition stores the item. Must be unique if used alone as the primary key.
2. **Sort key (SK)** — an optional second attribute that, combined with the partition key, forms a composite primary key. Items with the same PK but different SK values are stored together, sorted by SK. This enables range queries (e.g., `WHERE pk = 'user#123' AND sk BETWEEN '2024-01-01' AND '2024-12-31'`).
3. **Provisioned capacity** — you specify Read Capacity Units (RCUs) and Write Capacity Units (WCUs) in advance. Predictable cost, but requires capacity planning. Can enable Auto Scaling.
4. **On-demand capacity** — DynamoDB scales automatically with no capacity planning. You pay per request. Better for unpredictable or spiky workloads; more expensive per request at sustained high throughput.

**Key takeaway:** The partition key determines where data lives; the sort key enables efficient range queries within a partition — choosing them well is the most important DynamoDB design decision.

</details>

📖 **Theory:** [dynamodb-basics](./07_databases/dynamodb.md#stage-07b--dynamodb-serverless-nosql-at-any-scale)


---

### Q41 · [Normal] · `dynamodb-gsi-lsi`

> **What is a Global Secondary Index (GSI) vs a Local Secondary Index (LSI)? When would you add a GSI?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Both GSIs and LSIs let you query DynamoDB using attributes other than the table's primary key — but they differ in scope, flexibility, and cost.

**How to think through this:**
1. **LSI (Local Secondary Index)** — same partition key as the base table, different sort key. Must be created at table creation time. Shares the base table's partition capacity. Limited to 10GB per partition key value.
2. **GSI (Global Secondary Index)** — can use any attribute as partition key and sort key, completely independent of the base table's primary key. Can be added or deleted at any time. Has its own provisioned (or on-demand) capacity separate from the base table.
3. A GSI essentially creates a second projected copy of your table, sorted differently. Writes to the base table asynchronously propagate to the GSI — so GSI reads are eventually consistent (no strongly consistent option).
4. **When to add a GSI:** when you need to query by an attribute that is not the primary key. Example: a table keyed by `userId` that also needs to support queries like "find all orders with status = PENDING" — add a GSI on `status`.

**Key takeaway:** Use a GSI to support access patterns that don't fit the base table's primary key — it's DynamoDB's primary way to handle multiple query patterns on the same data.

</details>

📖 **Theory:** [dynamodb-gsi-lsi](./07_databases/dynamodb.md#stage-07b--dynamodb-serverless-nosql-at-any-scale)


---

### Q42 · [Normal] · `dynamodb-consistency`

> **What is the difference between eventually consistent and strongly consistent reads in DynamoDB?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
DynamoDB replicates data across three Availability Zones. The consistency model determines which replica you read from and how fresh the data is.

**How to think through this:**
1. **Eventually consistent read** — DynamoDB routes the read to any replica. The data might be up to a fraction of a second stale (the replication lag). Consumes 0.5 RCU per 4KB. The default for most operations and for all GSI reads.
2. **Strongly consistent read** — DynamoDB always reads from the primary (leader) replica, guaranteeing you get the most recent committed write. Consumes 1 full RCU per 4KB — twice the cost. Only available on the base table, not on GSIs.
3. For most applications (user profiles, product catalogs, dashboards), eventual consistency is fine — the lag is imperceptible. For financial operations, inventory counters, or anything where a stale read causes a correctness bug, use strongly consistent reads.
4. If you need strong consistency on a GSI access pattern, you must restructure the table or use a different solution (e.g., transactions).

**Key takeaway:** Eventually consistent reads are cheaper and faster; strongly consistent reads guarantee the latest data but cost twice as much in RCUs and are unavailable on GSIs.

</details>

📖 **Theory:** [dynamodb-consistency](./07_databases/dynamodb.md#stage-07b--dynamodb-serverless-nosql-at-any-scale)


---

### Q43 · [Normal] · `elasticache-basics`

> **What is ElastiCache? When would you use Redis vs Memcached?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Amazon ElastiCache is a fully managed in-memory caching service that supports two engines: Redis and Memcached. It sits in front of your database to serve frequently read data at microsecond latency.

**How to think through this:**
1. **Memcached** — pure, simple key-value caching. Multi-threaded, horizontally scalable by adding nodes. No persistence, no replication, no complex data types. Best when you need a straightforward, high-throughput cache and nothing else.
2. **Redis** — much richer feature set. Supports data structures (strings, hashes, lists, sets, sorted sets, bitmaps, HyperLogLog, streams). Supports persistence (RDB snapshots + AOF logs), replication (primary + replicas), automatic failover (Redis Sentinel / Redis Cluster), Pub/Sub, Lua scripting, and transactions.
3. Choose **Memcached** when: simple object caching, need multi-threading, don't care about persistence or failover.
4. Choose **Redis** when: you need persistence, replication, pub/sub, leaderboards (sorted sets), session stores that survive a restart, or complex data structures.
5. In practice, Redis is chosen the vast majority of the time due to its flexibility.

**Key takeaway:** Memcached is simple and fast for pure caching; Redis is more powerful and supports persistence, replication, and advanced data structures — use Redis unless you have a specific reason not to.

</details>

📖 **Theory:** [elasticache-basics](./07_databases/elasticache.md#stage-07c--elasticache-in-memory-caching)


---

### Q44 · [Normal] · `ecs-basics`

> **What is Amazon ECS? What is the difference between a Task Definition, Task, Service, and Cluster?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Amazon ECS (Elastic Container Service) is a fully managed container orchestration service that runs Docker containers on AWS without needing to manage Kubernetes control planes.

**How to think through this:**
1. **Task Definition** — a blueprint (JSON document) describing one or more containers: which Docker image to use, CPU/memory limits, port mappings, environment variables, IAM role, logging config. Think of it as a `docker-compose.yml` for ECS. It is versioned — each update creates a new revision.
2. **Task** — a running instance of a Task Definition. A task is the actual running container(s). It can be run once (batch job) or kept running by a Service.
3. **Service** — a long-running controller that ensures a desired number of tasks are always running. If a task dies, the Service replaces it. Services integrate with load balancers and support rolling deployments.
4. **Cluster** — the logical boundary grouping resources. A cluster can contain EC2 instances (ECS on EC2) or use Fargate. Services and tasks run inside a cluster.

**Key takeaway:** Task Definition is the blueprint, Task is the running instance, Service maintains desired task count, and Cluster is the logical container for all of them.

</details>

📖 **Theory:** [ecs-basics](./10_containers/ecs.md#stage-10b--ecs-elastic-container-service)


---

### Q45 · [Normal] · `ecs-fargate`

> **What is AWS Fargate? How does it differ from ECS on EC2?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Fargate is a serverless compute engine for containers. You run ECS tasks (or EKS pods) without provisioning or managing any EC2 instances — AWS handles the underlying infrastructure entirely.

**How to think through this:**
1. **ECS on EC2** — you launch and manage EC2 instances that form your ECS cluster. You're responsible for instance sizing, patching the OS, the ECS container agent, scaling the instance fleet, and paying for idle capacity.
2. **ECS on Fargate** — you specify CPU and memory at the task level. AWS provisions isolated microVM infrastructure for each task, runs it, and tears it down. No cluster instance management.
3. **Cost model difference:** EC2 launch type you pay for the instance (whether containers are running or not). Fargate you pay per vCPU and GB of memory per second a task actually runs — more granular, but higher unit cost.
4. **When to prefer Fargate:** variable workloads, batch jobs, teams without ops capacity to manage EC2 fleets. When to prefer EC2: steady high-density workloads where you want to pack many containers onto instances for cost efficiency, or when you need GPU instances or specific instance types.

**Key takeaway:** Fargate removes all infrastructure management from ECS — you pay for task runtime only, trading lower ops burden for higher per-unit cost compared to well-utilized EC2 clusters.

</details>

📖 **Theory:** [ecs-fargate](./10_containers/ecs.md#stage-10b--ecs-elastic-container-service)


---

### Q46 · [Normal] · `eks-basics`

> **What is Amazon EKS? How does it differ from ECS? When would you choose EKS over ECS?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Amazon EKS (Elastic Kubernetes Service) is a managed Kubernetes service — AWS runs and maintains the Kubernetes control plane (API server, etcd, scheduler) and you manage worker nodes (or use Fargate).

**How to think through this:**
1. **ECS** is AWS-proprietary. Its concepts (Task Definitions, Services, Clusters) are unique to AWS. Simpler to learn and operate, deeply integrated with AWS services, lower operational overhead.
2. **EKS** runs standard Kubernetes. Your workload definitions are portable — the same YAML manifests can run on any Kubernetes cluster (GKE, AKS, self-hosted). Much larger ecosystem (Helm, operators, service meshes, CNCF tooling).
3. **Choose EKS when:** your team already knows Kubernetes, you need portability across clouds or to on-premises, you rely on Kubernetes-native tooling (Helm, Argo CD, Istio, Prometheus operator), or you're running complex microservices that benefit from Kubernetes primitives (custom controllers, CRDs, namespaces).
4. **Choose ECS when:** you're AWS-only, want simplicity, have smaller teams, or are migrating from a Docker Compose workflow.

**Key takeaway:** EKS is standard Kubernetes on AWS — choose it for portability, ecosystem breadth, and Kubernetes expertise; choose ECS for AWS-native simplicity with less operational overhead.

</details>

📖 **Theory:** [eks-basics](./10_containers/eks.md#stage-10b--eks-managed-kubernetes-on-aws)


---

### Q47 · [Normal] · `api-gateway`

> **What is API Gateway? What is the difference between REST API and HTTP API in API Gateway?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
API Gateway is a fully managed service for creating, publishing, securing, and monitoring APIs at any scale. It acts as the front door for backend services (Lambda, HTTP endpoints, AWS services).

**How to think through this:**
1. **REST API** — the original, feature-rich API Gateway offering. Supports usage plans, API keys, per-client throttling, request/response transformation, caching, X-Ray tracing, WAF integration, private APIs via VPC endpoints, and all HTTP methods. More expensive ($3.50/million requests).
2. **HTTP API** — launched in 2020 as a simpler, faster, cheaper alternative. Supports Lambda, HTTP backends, and JWT authorizers (Cognito, Auth0). Missing some REST API features: no usage plans, no built-in caching, no request/response transformation. Up to 71% cheaper ($1.00/million requests) and ~60% lower latency.
3. **WebSocket API** — a third type for maintaining persistent connections (chat apps, real-time dashboards).
4. Decision rule: if you need advanced features (API keys, per-stage caching, request transforms, WAF), use REST API. For straightforward Lambda or HTTP proxy integrations, HTTP API is cheaper and faster.

**Key takeaway:** HTTP API is the modern default — cheaper and lower latency; upgrade to REST API only when you need its advanced features like caching, API keys, or request transformation.

</details>

📖 **Theory:** [api-gateway](./11_serverless/api_gateway.md#stage-11b--api-gateway)


---

### Q48 · [Normal] · `api-gateway-lambda`

> **Describe the request flow when an HTTP call hits API Gateway and triggers a Lambda function. What does the event payload look like?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
API Gateway acts as a proxy: it receives the HTTP request, transforms it into a structured JSON event, invokes Lambda synchronously, and converts Lambda's JSON response back into an HTTP response.

**How to think through this:**
1. Client sends `GET /users/42?include=email` with headers and (optionally) a body.
2. API Gateway matches the request to a configured route and integration.
3. API Gateway invokes the Lambda function synchronously, passing a JSON event object containing: `httpMethod`, `path`, `pathParameters`, `queryStringParameters`, `headers`, `body` (base64-encoded if binary), `requestContext` (account, stage, request ID, authorizer context).
4. Lambda processes the event and returns a JSON response with `statusCode` (integer), `headers` (object), and `body` (string — must be serialized JSON if returning JSON).
5. API Gateway translates that response object back into the HTTP response sent to the client.

```json
{
  "httpMethod": "GET",
  "path": "/users/42",
  "pathParameters": { "id": "42" },
  "queryStringParameters": { "include": "email" },
  "headers": { "Authorization": "Bearer ..." },
  "body": null,
  "requestContext": { "stage": "prod", "requestId": "abc-123" }
}
```

**Key takeaway:** API Gateway converts HTTP into a Lambda event JSON object and converts Lambda's `{ statusCode, headers, body }` response back into HTTP — Lambda never sees raw HTTP.

</details>

📖 **Theory:** [api-gateway-lambda](./11_serverless/api_gateway.md#stage-11b--api-gateway)


---

### Q49 · [Normal] · `sqs-advanced`

> **What is SQS visibility timeout? What is a dead-letter queue (DLQ)? What is long polling vs short polling?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These three concepts govern how SQS handles message delivery reliability, failure handling, and efficient polling.

**How to think through this:**
1. **Visibility timeout** — when a consumer receives a message, SQS hides it from other consumers for the visibility timeout duration (default 30s, max 12h). If the consumer processes and deletes it before the timeout, all is well. If the consumer crashes, the timeout expires, and the message becomes visible again for redelivery. This prevents duplicate processing under normal conditions but does not guarantee exactly-once delivery.
2. **Dead-letter queue (DLQ)** — a separate SQS queue where messages are moved after failing to be successfully processed N times (`maxReceiveCount`). Prevents poison-pill messages from looping forever. You monitor the DLQ separately and investigate failed messages.
3. **Short polling** — `ReceiveMessage` queries a subset of SQS servers immediately and returns (even with zero messages). Fast but wastes API calls and money.
4. **Long polling** — `ReceiveMessage` with `WaitTimeSeconds` (1–20s) waits for messages to arrive before returning. Reduces empty responses, lowers cost, reduces CPU usage in consumers. Recommended default.

**Key takeaway:** Visibility timeout enables at-least-once delivery by re-exposing unprocessed messages; DLQs quarantine repeatedly failing messages; long polling reduces wasted API calls.

</details>

📖 **Theory:** [sqs-advanced](./11_serverless/sqs_sns_eventbridge.md#stage-11c--sqs-sns--eventbridge)


---

### Q50 · [Normal] · `eventbridge`

> **What is EventBridge? How does it differ from SNS? What is an event bus and an event rule?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
EventBridge is a serverless event routing service that connects AWS services, SaaS applications, and your own applications using events. It's the evolution of CloudWatch Events.

**How to think through this:**
1. **Event bus** — the channel through which events flow. There's a default event bus (receives AWS service events like EC2 state changes), custom buses (for your own app events), and partner buses (for SaaS apps like Datadog, Zendesk, Shopify).
2. **Event rule** — a pattern-matching rule that listens on an event bus. When an event matches the pattern, the rule routes it to one or more targets (Lambda, SQS, SNS, Step Functions, HTTP endpoints, etc.). Rules can also be scheduled (cron).
3. **EventBridge vs SNS:**
   - SNS is a pub/sub push service — publishers push to topics, subscribers receive all messages. Simple fan-out. No content-based filtering beyond basic attribute filtering.
   - EventBridge has rich content-based routing (filter on any field in the event JSON), supports SaaS integrations, event replay/archiving, and schema registry. More powerful orchestration tool.
4. Rule of thumb: SNS for simple fan-out to multiple endpoints; EventBridge for event-driven architectures with complex routing logic, SaaS events, or audit/replay requirements.

**Key takeaway:** EventBridge routes events based on content patterns across AWS, SaaS, and custom sources — more powerful than SNS for event-driven architectures, but SNS remains simpler for straightforward pub/sub fan-out.

</details>

📖 **Theory:** [eventbridge](./11_serverless/sqs_sns_eventbridge.md#stage-11c--sqs-sns--eventbridge)


---

### Q51 · [Normal] · `step-functions`

> **What is AWS Step Functions? What is the difference between Standard and Express workflows?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Step Functions is a serverless orchestration service that sequences AWS service calls into visual workflows defined as state machines using Amazon States Language (ASL).

**How to think through this:**
1. You define states: Task (call Lambda, ECS, DynamoDB, etc.), Choice (branching), Wait, Parallel, Map (fan-out over array), Pass, Succeed, Fail. Each execution follows the state machine graph.
2. **Standard Workflows** — designed for long-running, durable orchestrations. Execution history is persisted for up to 90 days. Guarantees exactly-once execution of each state. Max duration: 1 year. Priced per state transition (~$0.025/1000 transitions). Use for order processing, ML pipelines, human approval flows.
3. **Express Workflows** — designed for high-volume, short-duration workloads. At-least-once execution (not exactly-once). Max duration: 5 minutes. Priced per execution duration + GB-second (like Lambda pricing). Much cheaper at high volume. History stored in CloudWatch Logs. Use for IoT event processing, streaming transformations, real-time data ingestion.
4. Key distinction: Standard = durability + exactly-once + long-running; Express = high throughput + low cost + short-lived.

**Key takeaway:** Standard Workflows guarantee exactly-once execution with full history for durable long-running processes; Express Workflows trade those guarantees for high throughput and low cost in short-duration, high-volume scenarios.

</details>

📖 **Theory:** [step-functions](./11_serverless/step_functions.md#stage-11d--step-functions-serverless-workflows)


---

### Q52 · [Normal] · `cloudwatch-advanced`

> **What are CloudWatch Container Insights, Lambda Insights, and Contributor Insights? When would you use each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These are three enhanced CloudWatch features that provide deeper, more structured observability beyond standard metrics and logs.

**How to think through this:**
1. **Container Insights** — collects, aggregates, and surfaces container-level metrics (CPU, memory, network, disk) from ECS, EKS, and Kubernetes. Uses a containerized CloudWatch agent (or Fluent Bit). Provides pre-built dashboards for cluster, service, task, and container level visibility. Use when debugging container resource issues or optimizing ECS/EKS deployments.
2. **Lambda Insights** — an enhanced monitoring extension for Lambda. Provides system-level metrics that the standard Lambda metrics miss: memory utilization, CPU time, init duration (cold start), network throughput. Deployed as a Lambda layer. Use when diagnosing Lambda cold starts, memory pressure, or performance regressions.
3. **Contributor Insights** — analyzes log data to identify the top-N contributors to a metric over time. Example: "which IPs are sending the most 5xx errors?" or "which DynamoDB partition keys are causing the most throttling?" Runs against CloudWatch Logs using rule-based patterns. Use for identifying noisy-neighbor problems, top talkers, or hot partitions.

**Key takeaway:** Container Insights = container fleet health; Lambda Insights = deep Lambda runtime metrics; Contributor Insights = who or what is causing the most impact on a metric.

</details>

📖 **Theory:** [cloudwatch-advanced](./08_monitoring/cloudwatch.md#stage-08--cloudwatch--observability)


---

### Q53 · [Normal] · `xray`

> **What is AWS X-Ray? How does it help with distributed tracing? What is a trace, segment, and subsegment?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
AWS X-Ray is a distributed tracing service that tracks requests as they travel through the components of a distributed application, giving you an end-to-end map of latency, errors, and bottlenecks.

**How to think through this:**
1. **Trace** — represents the entire journey of a single request from entry to completion. A trace ID is generated at the entry point and propagated in HTTP headers (`X-Amzn-Trace-Id`) to all downstream services. One trace = one user request, top to bottom.
2. **Segment** — each service or component that processes the request creates a segment. It contains timing data, metadata, and error information for that component's work. Example: API Gateway creates a segment, Lambda creates a segment.
3. **Subsegment** — granular breakdown within a segment. A Lambda segment might have subsegments for a DynamoDB call, an S3 read, and an external HTTP call — each with its own timing. This is where you pinpoint which downstream dependency is slow.
4. The X-Ray SDK instruments your code (or uses auto-instrumentation for supported services). The X-Ray daemon/agent batches and sends data to the X-Ray service where you see the service map and trace timeline.

**Key takeaway:** A trace follows one request end-to-end; segments represent each service's work; subsegments break down individual operations within a service — together they let you find exactly which hop is causing latency.

</details>

📖 **Theory:** [xray](./08_monitoring/otel.md#stage-08b--opentelemetry-on-aws)


---

### Q54 · [Normal] · `s3-advanced`

> **What is S3 Cross-Region Replication? What are S3 Lifecycle Policies used for? What is S3 Object Lock?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Three distinct S3 features for durability, cost management, and compliance.

**How to think through this:**
1. **Cross-Region Replication (CRR)** — automatically replicates objects from a source bucket in one region to a destination bucket in another region, asynchronously. Requires versioning enabled on both buckets. Use cases: disaster recovery, latency reduction for geographically distributed users, data sovereignty compliance. Same-Region Replication (SRR) exists for in-region copies.
2. **Lifecycle Policies** — rules that automatically transition objects between storage classes or expire (delete) them based on age or prefix. Example: move objects to S3-IA after 30 days → Glacier after 90 days → delete after 365 days. Reduces storage costs without manual intervention. Essential for log buckets, backup archives, and data lakes.
3. **Object Lock** — enforces a WORM (Write Once, Read Many) model. Objects cannot be deleted or overwritten for a retention period you define. Two modes: **Governance** (users with special IAM permissions can override) and **Compliance** (no one, including the root account, can override). Use for regulatory compliance (SEC Rule 17a-4, HIPAA), ransomware protection, or audit log integrity.

**Key takeaway:** CRR provides geographic redundancy; Lifecycle Policies automate cost optimization by tiering data; Object Lock enforces immutability for compliance and data protection.

</details>

📖 **Theory:** [s3-advanced](./04_storage/s3.md#stage-04a--s3-simple-storage-service)


---

### Q55 · [Normal] · `cloudfront`

> **What is CloudFront? What is the difference between an Origin, Distribution, and Cache Behavior?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
CloudFront is AWS's global Content Delivery Network (CDN) — a network of 400+ edge locations worldwide that caches content close to users to reduce latency and offload traffic from origins.

**How to think through this:**
1. **Origin** — the source of truth for your content. Can be an S3 bucket, an Application Load Balancer, an EC2 instance, an API Gateway, or any custom HTTP server. CloudFront fetches content from the origin on a cache miss and stores it at the edge.
2. **Distribution** — the CloudFront resource you create. It has a domain name (e.g., `d1234.cloudfront.net` or your custom domain via Route 53) and contains all the configuration: origins, cache behaviors, SSL certificates, geo-restrictions, WAF associations.
3. **Cache Behavior** — a rule within a distribution that maps a URL path pattern to an origin and defines caching settings. Example: `GET /api/*` → forward to ALB, never cache, pass all headers; `GET /static/*` → serve from S3, cache for 24h, compress. A distribution has a default cache behavior (catches all unmatched paths) plus optional ordered additional behaviors.

**Key takeaway:** An Origin is where content lives; a Distribution is the CloudFront resource serving it; Cache Behaviors are per-path rules controlling which origin to use and how to cache responses.

</details>

📖 **Theory:** [cloudfront](./05_networking/route53_cloudfront.md#stage-05b--route-53--cloudfront)


---

### Q56 · [Normal] · `cloudfront-cache`

> **What is CloudFront cache invalidation? What is a Cache Policy vs Origin Request Policy?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Cache invalidation, Cache Policies, and Origin Request Policies are three tools for controlling what CloudFront caches and what it passes to your origin.

**How to think through this:**
1. **Cache invalidation** — forces CloudFront to discard cached objects before their TTL expires, so the next request fetches fresh content from the origin. You specify paths (`/index.html`, `/static/*`, `/*`). First 1,000 invalidation paths per month are free; beyond that, $0.005/path. Best practice: use versioned file names (e.g., `app.v2.js`) instead of invalidations to avoid cost and propagation delay.
2. **Cache Policy** — defines what CloudFront includes in the cache key (the unique identifier for a cached object). By default, only the URL path is the cache key. You can add HTTP headers, query strings, or cookies to the cache key — but adding more dimensions reduces cache hit rate. Also sets min/max/default TTL.
3. **Origin Request Policy** — defines what CloudFront sends to the origin on a cache miss (headers, query strings, cookies). Crucially, you can forward values to the origin without including them in the cache key. Example: forward the `User-Agent` header to the origin for analytics, but don't vary the cache on it.

**Key takeaway:** Cache Policy controls what varies the cache key; Origin Request Policy controls what gets forwarded to the origin on a miss — separating these lets you pass context to your origin without fragmenting your cache.

</details>

📖 **Theory:** [cloudfront-cache](./05_networking/route53_cloudfront.md#stage-05b--route-53--cloudfront)


---

### Q57 · [Normal] · `disaster-recovery`

> **Describe the 4 AWS DR strategies: Backup/Restore, Pilot Light, Warm Standby, Multi-Site. What is the RPO/RTO trade-off?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
AWS defines four DR strategies on a spectrum from low cost/high recovery time to high cost/near-zero recovery time. RPO (Recovery Point Objective) is how much data you can afford to lose; RTO (Recovery Time Objective) is how long recovery can take.

**How to think through this:**
1. **Backup and Restore** — data is backed up to S3 or AWS Backup. Nothing runs in the DR region until disaster strikes; you restore from backup and rebuild infrastructure. Cheapest. RPO: hours to days (backup frequency). RTO: hours to days (time to restore and provision).
2. **Pilot Light** — a minimal version of critical infrastructure (databases replicated, core services running but scaled to zero or minimal capacity) always on in the DR region. On failover, you scale up and point DNS. RPO: minutes (replication lag). RTO: tens of minutes (scale-up time).
3. **Warm Standby** — a scaled-down but fully functional copy of production always running in DR. Handles minimal traffic. On failover, scale up to full capacity and shift traffic. RPO: seconds to minutes. RTO: minutes.
4. **Multi-Site (Active-Active)** — full production capacity runs in multiple regions simultaneously, serving live traffic. Failover is instant — just remove the failed region from DNS/load balancing. Near-zero RPO and RTO. Most expensive — you're paying for double (or more) capacity constantly.

**Key takeaway:** As you move from Backup/Restore to Multi-Site, cost increases dramatically but RPO/RTO drop toward zero — choose the strategy whose recovery guarantees justify the ongoing cost.

</details>

📖 **Theory:** [disaster-recovery](./14_architecture/disaster_recovery.md#stage-14c--disaster-recovery--business-continuity)


---

### Q58 · [Normal] · `high-availability-patterns`

> **What is the difference between High Availability and Fault Tolerance? Describe a 3-tier HA architecture on AWS.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
High Availability and Fault Tolerance both aim to keep systems running, but they differ in how much downtime they tolerate.

**How to think through this:**
1. **High Availability (HA)** — the system is designed to minimize downtime. If a component fails, another takes over quickly (usually within seconds to minutes). There may be a brief interruption. Example: RDS Multi-AZ failover takes ~60 seconds.
2. **Fault Tolerance** — the system continues operating with zero interruption even when components fail. Requires full redundancy with no failover delay. More expensive. Example: a RAID-1 disk array that keeps serving reads while one disk fails.
3. **3-tier HA architecture on AWS:**
   - **Presentation tier:** CloudFront in front of an Application Load Balancer (ALB) deployed across 2+ AZs.
   - **Application tier:** Auto Scaling Group of EC2 instances (or ECS Service) spanning 2+ AZs behind the ALB. Min healthy instance count ensures capacity during AZ failure.
   - **Data tier:** RDS in Multi-AZ mode (synchronous replication + automatic failover) or Aurora (6 copies across 3 AZs). ElastiCache with read replicas or Redis cluster mode for session/cache layer.
   - Route 53 with health checks handles DNS failover for the ALB endpoint if a region-level issue occurs.

**Key takeaway:** High Availability accepts brief interruptions during failover; Fault Tolerance requires zero interruption — HA is far more common and cost-effective, using multi-AZ redundancy at every tier.

</details>

📖 **Theory:** [high-availability-patterns](./14_architecture/high_availability.md#stage-14--high-availability-architecture-patterns)


---

### Q59 · [Normal] · `well-architected-pillars`

> **Name the 6 AWS Well-Architected Framework pillars. What is one key design principle for each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The AWS Well-Architected Framework provides a consistent set of best practices for evaluating cloud architectures across six pillars.

**How to think through this:**
1. **Operational Excellence** — run and monitor systems to deliver business value and continually improve processes. Key principle: perform operations as code (automate runbooks, use IaC, eliminate manual procedures).
2. **Security** — protect information, systems, and assets. Key principle: apply security at all layers (network, compute, data, application) and use least-privilege access everywhere.
3. **Reliability** — ensure workloads perform their intended function correctly and consistently. Key principle: automatically recover from failure — use health checks, Auto Scaling, and multi-AZ to recover without human intervention.
4. **Performance Efficiency** — use computing resources efficiently and maintain that efficiency as demand changes. Key principle: use serverless architectures to remove operational burden and scale automatically.
5. **Cost Optimization** — deliver business value at the lowest price point. Key principle: adopt a consumption model — pay only for what you use, and use managed services to reduce cost of ownership.
6. **Sustainability** — minimize environmental impacts of running cloud workloads. Key principle: maximize utilization — right-size resources and use managed services that share infrastructure across customers for higher efficiency.

**Key takeaway:** The 6 pillars — Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability — provide a complete lens for evaluating architectural trade-offs in any AWS workload.

</details>

📖 **Theory:** [well-architected-pillars](./14_architecture/well_architected.md#stage-14b--the-6-pillars-of-well-architected-framework)


---

### Q60 · [Normal] · `cost-optimization`

> **What is the difference between Reserved Instances, Savings Plans, and Spot Instances for cost optimization?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
All three reduce EC2 (and other service) costs compared to On-Demand pricing, but through different commitment and flexibility models.

**How to think through this:**
1. **Reserved Instances (RIs)** — commit to a specific instance type, region, OS, and tenancy for 1 or 3 years. Up to 72% off On-Demand. Standard RIs are tied to specific instance attributes; Convertible RIs allow attribute changes at a lower discount (~66%). Zonal RIs also reserve capacity. Best for predictable, steady-state workloads with known instance types.
2. **Savings Plans** — a more flexible commitment model (introduced 2019). You commit to a spend level ($/hr) for 1 or 3 years. Compute Savings Plans apply to any EC2 instance type, region, OS, or tenancy — even Fargate and Lambda. EC2 Instance Savings Plans are less flexible but offer higher discounts (up to 72%). No capacity reservation. Best for workloads where you know your total compute spend but want flexibility to change instance types.
3. **Spot Instances** — use AWS's spare EC2 capacity at up to 90% off On-Demand. AWS can reclaim with a 2-minute warning. Not suitable for stateful or time-sensitive work. Best for fault-tolerant batch jobs, big data processing, CI/CD workers, and stateless web tier overflow.

**Key takeaway:** Reserved Instances and Savings Plans reduce cost through commitment (1–3 years); Spot Instances reduce cost through tolerating interruption — use Savings Plans for flexibility, Spot for interruptible batch workloads.

</details>

📖 **Theory:** [cost-optimization](./15_cost_optimization/theory.md#stage-15--cost-optimization)


---

### Q61 · [Normal] · `iam-conditions`

> **What are IAM condition keys? Write an IAM policy condition that restricts access to a specific AWS region.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
IAM condition keys let you add conditional logic to policy statements — the policy only applies (or denies) when the specified conditions are true at request time.

**How to think through this:**
1. Condition keys come from three sources: AWS global condition keys (prefixed `aws:`), service-specific keys (e.g., `s3:prefix`, `ec2:Region`), and resource-based keys.
2. Common global keys: `aws:RequestedRegion`, `aws:SourceIp`, `aws:PrincipalTag`, `aws:CurrentTime`, `aws:MultiFactorAuthPresent`.
3. To restrict all actions to `us-east-1` only, use a `Deny` statement with a `StringNotEquals` condition on `aws:RequestedRegion`. Using `Deny` + `NotEquals` is more robust than `Allow` + `Equals` because it catches any new actions or services automatically.

```json
{
  "Effect": "Deny",
  "Action": "*",
  "Resource": "*",
  "Condition": {
    "StringNotEquals": {
      "aws:RequestedRegion": "us-east-1"
    }
  }
}
```

4. Note: some global services (IAM, STS, CloudFront, Route 53) are region-agnostic and always routed through `us-east-1` — you may need to add exceptions for them.

**Key takeaway:** IAM condition keys add context-aware logic to policies — use `Deny` + `StringNotEquals` on `aws:RequestedRegion` for enforceable region restriction, and pair it with an SCP for account-wide enforcement.

</details>

📖 **Theory:** [iam-conditions](./06_security/iam.md#stage-06a--iam-identity--access-management)


---

### Q62 · [Normal] · `waf-shield`

> **What is AWS WAF? What does AWS Shield (Standard vs Advanced) protect against?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
WAF and Shield are two complementary AWS security services operating at different layers of the threat model — WAF at Layer 7 (application), Shield at Layer 3/4 (network/transport).

**How to think through this:**
1. **AWS WAF (Web Application Firewall)** — inspects HTTP/HTTPS traffic at Layer 7. You create Web ACLs with rules that match on IP addresses, request headers, URI strings, SQL injection patterns, XSS patterns, geolocation, rate limits, and more. Attach Web ACLs to CloudFront, ALB, API Gateway, or AppSync. Blocks OWASP Top 10 attacks (SQL injection, XSS, etc.). You can use AWS Managed Rules or write custom rules.
2. **AWS Shield Standard** — automatically included at no cost for all AWS customers. Protects against common Layer 3/4 DDoS attacks: SYN/UDP floods, reflection attacks. Active on all AWS edge locations (CloudFront, Route 53, Global Accelerator) automatically.
3. **AWS Shield Advanced** — $3,000/month + data transfer fees. Adds: enhanced DDoS detection and mitigation for larger, more sophisticated attacks; protection for EC2, ELB, CloudFront, Route 53, Global Accelerator; 24/7 access to the AWS DDoS Response Team (DRT); cost protection (credits for AWS bill spikes caused by DDoS); real-time attack visibility in CloudWatch.

**Key takeaway:** WAF blocks malicious web requests at Layer 7; Shield Standard defends against network-layer DDoS automatically for free; Shield Advanced adds enterprise-grade DDoS response and cost protection.

</details>

📖 **Theory:** [waf-shield](./06_security/waf_shield_guardduty.md#stage-06c--waf-shield-guardduty--security-hub)


---

### Q63 · [Normal] · `guardduty`

> **What is Amazon GuardDuty? What data sources does it analyze? What does it detect?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Amazon GuardDuty is a managed threat detection service that continuously analyzes AWS account activity to identify malicious or unauthorized behavior using machine learning, anomaly detection, and threat intelligence feeds.

**How to think through this:**
1. **Data sources GuardDuty analyzes:**
   - AWS CloudTrail event logs (API call history — who did what, when)
   - VPC Flow Logs (network traffic metadata — IP, port, protocol, bytes)
   - DNS logs (DNS query logs from Route 53 resolver)
   - Optional additional sources: S3 data events, EKS audit logs, RDS login events, Lambda network activity, ECS runtime monitoring, EC2 malware scanning
2. **What it detects:**
   - Compromised EC2 instances communicating with known C2 (command-and-control) servers
   - Cryptocurrency mining activity
   - Unusual API calls (e.g., root account usage, calls from Tor exit nodes)
   - Reconnaissance activity (port scanning, failed login attempts)
   - Data exfiltration patterns (large S3 downloads to unknown IPs)
   - IAM credential theft and unusual cross-region activity
3. GuardDuty requires no agents, no infrastructure changes — enable it per account (or via Organizations for all accounts). Findings appear in the GuardDuty console and can be routed to EventBridge for automated response.

**Key takeaway:** GuardDuty is an agentless threat intelligence layer over CloudTrail, VPC Flow Logs, and DNS logs — it detects compromised credentials, malicious network activity, and unusual API behavior without requiring any infrastructure changes.

</details>

📖 **Theory:** [guardduty](./06_security/waf_shield_guardduty.md#stage-06c--waf-shield-guardduty--security-hub)


---

### Q64 · [Normal] · `secrets-manager`

> **What is Secrets Manager vs Parameter Store? When would you use Secrets Manager over plain environment variables in Lambda?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Both store configuration and secrets, but they differ in cost, features, and use cases. Environment variables in Lambda are a third, simpler option with significant security tradeoffs.

**How to think through this:**
1. **Parameter Store** — part of AWS Systems Manager. Stores strings, string lists, and SecureStrings (encrypted with KMS). Free for standard parameters (up to 10,000). Supports versioning, hierarchical naming (`/app/prod/db-password`), IAM-controlled access, no automatic rotation.
2. **Secrets Manager** — purpose-built for secrets. Costs $0.40/secret/month. Key differentiators: native automatic rotation (built-in support for RDS, Redshift, DocumentDB, custom Lambda rotation). Cross-account secret sharing. Secrets are always encrypted. Audit trail in CloudTrail.
3. **Environment variables in Lambda** — simplest option. Values are set at deploy time, encrypted at rest with KMS (if you enable it). But: visible in the AWS console to anyone with Lambda read access, included in deployment packages, require redeployment to rotate, and leaked if the function is misconfigured. Not suitable for high-sensitivity secrets.
4. **Use Secrets Manager over env vars when:** the secret needs automatic rotation (database passwords), you need fine-grained audit of every secret access, or the secret is shared across multiple services/accounts.

**Key takeaway:** Use Secrets Manager for secrets requiring automatic rotation and full audit trails; use Parameter Store for general config and non-rotating secrets; avoid plain Lambda environment variables for anything sensitive.

</details>

📖 **Theory:** [secrets-manager](./06_security/kms.md#6-aws-secrets-manager)


---

### Q65 · [Normal] · `glue-athena`

> **What is AWS Glue? What is Athena? How do they work together for serverless data processing?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
AWS Glue and Athena are complementary serverless services for building data pipelines and querying data at rest in S3 without managing any infrastructure.

**How to think through this:**
1. **AWS Glue** — a serverless ETL (Extract, Transform, Load) service. Core components: the **Glue Data Catalog** (a managed metadata repository — stores table schemas, partition info, data locations, like a Hive metastore), **Glue Crawlers** (automatically scan data sources like S3, RDS, or DynamoDB and infer schema into the Data Catalog), and **Glue ETL Jobs** (Spark or Python scripts that transform and move data, running on managed Spark clusters you don't provision).
2. **Athena** — a serverless interactive query service. You write standard SQL and Athena executes it against data in S3 using distributed query engines (originally Presto, now includes Apache Iceberg support). You pay per TB of data scanned ($5/TB). No infrastructure to manage.
3. **How they work together:** Glue Crawler scans raw S3 data (JSON, CSV, Parquet, ORC) → populates Glue Data Catalog with table definitions → Athena queries those catalog tables directly using SQL, reading data from S3. Glue ETL jobs can also transform raw data into optimized columnar formats (Parquet/ORC) and update the catalog — dramatically reducing Athena query costs and improving speed.

**Key takeaway:** Glue catalogs and transforms your data; Athena queries it with SQL — together they form a serverless data lake query layer on S3 with no databases or clusters to manage.

</details>

📖 **Theory:** [glue-athena](./12_data_analytics/athena_glue_redshift.md#stage-12b--athena-glue--redshift-the-data-lake-stack)


---

### Q66 · [Normal] · `kinesis-streams`

> **What is Kinesis Data Streams? What is a shard? How does Kinesis differ from SQS for streaming data?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Kinesis Data Streams is a real-time data streaming service designed for ingesting and processing large volumes of records at low latency, with ordered delivery and multiple consumer support.

**How to think through this:**
1. **Shard** — the unit of capacity in a Kinesis stream. Each shard provides 1 MB/s write throughput (up to 1,000 records/s) and 2 MB/s read throughput. Shards are partitioned by a partition key — records with the same partition key always go to the same shard, guaranteeing ordering per key. You scale a stream by adding or splitting shards. Pricing is per shard-hour.
2. **Retention** — records are retained in the stream from 24 hours (default) up to 365 days. Multiple consumers can independently read the same records at different positions (unlike SQS where each message is consumed once).
3. **Kinesis vs SQS:**
   - **Ordering:** Kinesis guarantees ordering per shard/partition key. SQS Standard has no ordering guarantee; SQS FIFO guarantees order within a message group but at lower throughput (3,000 msgs/s with batching).
   - **Multiple consumers:** Kinesis supports multiple independent consumers reading the same data stream simultaneously (fan-out). SQS delivers each message to only one consumer (competing consumers pattern).
   - **Retention and replay:** Kinesis retains records and allows replay. SQS deletes a message once it's consumed.
   - **Use case:** Kinesis for time-series analytics, real-time dashboards, event sourcing, log aggregation where you need ordering and replay. SQS for decoupled task queues where each task is processed once.

**Key takeaway:** Kinesis is built for ordered, replayable, multi-consumer real-time streams; SQS is built for decoupled message queuing where each message is processed by exactly one consumer — the choice hinges on whether you need ordering, replay, or fan-out.

</details>

📖 **Theory:** [kinesis-streams](./12_data_analytics/kinesis.md#3-kinesis-data-streams-deep-dive)


---

## 🟠 Tier 3 — Advanced

### Q67 · [Thinking] · `bedrock-basics`

> **What is Amazon Bedrock? How does it differ from using OpenAI's API directly? What is a Foundation Model in Bedrock's context?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Amazon Bedrock is a fully managed AWS service that provides API access to Foundation Models (FMs) from multiple providers — Anthropic, Meta, Mistral, Amazon (Titan), and others — without requiring you to manage any infrastructure. A **Foundation Model** is a large pre-trained model capable of a wide range of tasks (text, image, embeddings) that you use as-is or fine-tune on your own data.

**How to think through this:**
1. OpenAI's API is a single vendor — you call their endpoint and get a response. You have no control over where data goes or what infrastructure is used.
2. Bedrock is a multi-model marketplace hosted entirely within AWS. Data stays in your AWS account and VPC, which matters for compliance (HIPAA, SOC2, FedRAMP).
3. Bedrock also adds AWS-native integrations: IAM for access control, CloudWatch for logging, S3 for RAG data sources via Knowledge Bases, and no GPU management required.

**Key takeaway:** Bedrock trades vendor lock-in to OpenAI for AWS lock-in, but gains compliance, multi-model flexibility, and native IAM/VPC integration.

</details>

📖 **Theory:** [bedrock-basics](./16_ai_ml/bedrock.md#stage-16a--amazon-bedrock-foundation-models--generative-ai)


---

### Q68 · [Thinking] · `sagemaker-overview`

> **What is SageMaker? What is the difference between SageMaker Training Jobs, Endpoints, and Pipelines?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Amazon SageMaker is a fully managed ML platform covering the entire model lifecycle: data prep, training, evaluation, deployment, and monitoring. Think of it as the assembly line for custom ML models.

**How to think through this:**
1. **Training Jobs** — Spin up compute (CPUs/GPUs), run your training script against data in S3, save the model artifact back to S3, then terminate the compute. You pay only while training runs.
2. **Endpoints** — Deploy a trained model to a persistent HTTPS endpoint for real-time inference. SageMaker manages the compute fleet, auto-scaling, and A/B testing between model variants.
3. **Pipelines** — An MLOps orchestration layer. Chain steps (preprocessing → training → evaluation → conditional deployment) into a DAG that can be triggered on a schedule or event. Similar in concept to Airflow but ML-native.

**Key takeaway:** Training Jobs are ephemeral compute for building models, Endpoints are always-on serving infrastructure, and Pipelines automate the workflow between them.

</details>

📖 **Theory:** [sagemaker-overview](./16_ai_ml/sagemaker.md#2-sagemaker-architecture-overview)


---

### Q69 · [Thinking] · `lambda-layers`

> **What are Lambda Layers? How do they help manage shared dependencies? What is the limit on layers per function?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A **Lambda Layer** is a ZIP archive containing libraries, a custom runtime, or other dependencies that can be attached to multiple Lambda functions. Instead of bundling `pandas` or `numpy` into every deployment package, you publish it once as a layer and reference it across functions.

**How to think through this:**
1. Without layers, each function's deployment package must include all its dependencies. A data team with 20 functions all using `pandas` would deploy the same 50MB library 20 times.
2. With layers, `pandas` lives in one layer. Each function references the layer ARN. Updates to the library happen in one place.
3. Layers are extracted to `/opt` in the Lambda execution environment. Your code imports from there transparently.
4. The limit is **5 layers per function**. The total unzipped size of function + all layers must stay under **250 MB**.

**Key takeaway:** Layers decouple shared code from function code — one update propagates everywhere, and deployment packages stay small.

</details>

📖 **Theory:** [lambda-layers](./11_serverless/lambda.md#8-lambda-layers)


---

### Q70 · [Thinking] · `lambda-concurrency`

> **What is Lambda reserved concurrency vs provisioned concurrency? What is the difference and when do you use each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Reserved concurrency** is a hard cap on how many concurrent executions a function can have. **Provisioned concurrency** pre-warms a set number of execution environments so they are ready to respond with no cold start.

**How to think through this:**
1. By default, all functions in an account share a regional concurrency pool (default 1000). One runaway function can starve others.
2. **Reserved concurrency** solves that by guaranteeing a function gets up to N concurrent executions — and simultaneously prevents it from using more than N. Use it to protect critical functions from noisy neighbors, or to throttle low-priority functions.
3. **Provisioned concurrency** keeps execution environments initialized and warm. When a request arrives, no cold start occurs — the environment is already loaded. Use it for latency-sensitive APIs where a 1–2 second cold start is unacceptable.
4. They can be combined: reserve 100 concurrency for a function, provision 20 of those as always-warm.

**Key takeaway:** Reserved concurrency is about isolation and throttling; provisioned concurrency is about eliminating cold-start latency — they solve different problems.

</details>

📖 **Theory:** [lambda-concurrency](./11_serverless/lambda.md#9-lambda-concurrency--throttling)


---

### Q71 · [Thinking] · `ecs-networking`

> **What are the 3 ECS network modes: bridge, host, awsvpc? Which is required for Fargate and why?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
ECS supports three network modes that control how containers connect to the network stack of their host.

**How to think through this:**
1. **bridge** — Containers get their own virtual network interface inside a Docker bridge network on the host. Port mapping is required to expose container ports to the host. Multiple containers can share the host's IP but on different ports. This is the Docker default.
2. **host** — The container shares the host EC2 instance's network namespace directly. No port mapping needed; container port 80 is host port 80. Highest performance but containers compete for ports and can't run two containers on the same port.
3. **awsvpc** — Each task gets its own Elastic Network Interface (ENI) with a private VPC IP. The task looks like a first-class VPC citizen: security groups attach directly to the task, not the host. This is the only mode Fargate supports.
4. Fargate requires **awsvpc** because there is no underlying EC2 host to bridge to — each task IS the isolated unit, so it needs its own ENI.

**Key takeaway:** `awsvpc` is required for Fargate because tasks need a dedicated network identity; it also enables per-task security groups instead of per-host.

</details>

📖 **Theory:** [ecs-networking](./10_containers/ecs.md#stage-10b--ecs-elastic-container-service)


---

### Q72 · [Thinking] · `eks-node-groups`

> **What is the difference between EKS Managed Node Groups, Self-Managed Node Groups, and Fargate profiles?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These three options represent how much EC2 node lifecycle management you hand off to AWS.

**How to think through this:**
1. **Self-Managed Node Groups** — You provision EC2 instances, install the kubelet, and join them to the cluster yourself (often via an Auto Scaling Group and a bootstrap script). You own patching, AMI updates, and draining before termination.
2. **Managed Node Groups** — AWS provisions and manages the EC2 instances in an Auto Scaling Group for you. It handles node updates (rolling) and graceful draining. You still see and can SSH into the instances, but the lifecycle is automated. Use this as the default for most workloads.
3. **Fargate Profiles** — No EC2 nodes at all. Pods matching a namespace/label selector run in AWS-managed micro-VMs. No SSH, no node visibility, no DaemonSets. Fargate is ideal for bursty, stateless workloads where you want zero node management.

**Key takeaway:** Managed Node Groups hit the sweet spot — AWS handles lifecycle, you retain visibility; Fargate removes nodes entirely at the cost of flexibility.

</details>

📖 **Theory:** [eks-node-groups](./10_containers/eks.md#5-node-groups-ec2-vs-fargate)


---

### Q73 · [Thinking] · `rds-aurora`

> **What is Aurora? How does Aurora Serverless v2 differ from regular RDS? What is an Aurora Global Database?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Aurora** is AWS's cloud-native relational database engine, compatible with MySQL and PostgreSQL, built on a distributed storage layer that decouples compute from storage. It stores 6 copies of data across 3 AZs automatically.

**How to think through this:**
1. Regular RDS uses a single primary instance with storage attached to it (gp2/gp3 EBS). Aurora separates compute (the DB instance) from a shared distributed storage volume that auto-grows up to 128 TiB.
2. **Aurora Serverless v2** scales compute capacity in fine-grained increments (0.5 ACU steps) almost instantly based on load — within seconds, not minutes. Regular RDS scales by changing instance type, which requires a reboot. Serverless v2 is ideal for variable or unpredictable workloads.
3. **Aurora Global Database** replicates an Aurora cluster to up to 5 secondary AWS regions with typical replication lag under 1 second. In a disaster, a secondary region can be promoted to primary in under 1 minute. This is for DR and global read scalability, not just multi-AZ.

**Key takeaway:** Aurora trades RDS simplicity for distributed storage resilience and faster scaling; Global Database extends that to cross-region DR with sub-second replication.

</details>

📖 **Theory:** [rds-aurora](./07_databases/rds_aurora.md#stage-07a--rds--aurora-managed-relational-databases)


---

### Q74 · [Thinking] · `s3-performance`

> **What techniques improve S3 PUT/GET performance for high-throughput applications? What is S3 Transfer Acceleration?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
S3 can scale to very high request rates, but the way you structure your workload matters.

**How to think through this:**
1. **Prefix parallelism** — S3 scales to 3,500 PUT/COPY/DELETE and 5,500 GET requests per second per prefix. By spreading objects across multiple key prefixes (e.g., sharding by hash), you multiply throughput linearly.
2. **Multipart upload** — For objects over 100 MB, split the upload into parts and upload them in parallel. Each part is independent; failed parts can be retried. Required for objects over 5 GB.
3. **Byte-range fetches** — For large GET operations, request specific byte ranges in parallel (like BitTorrent). Reassemble client-side. This turns one serial download into N parallel ones.
4. **S3 Transfer Acceleration** — Routes uploads/downloads through AWS CloudFront edge locations using AWS's private backbone network instead of the public internet. Useful when clients are geographically distant from the bucket's region. Costs extra per GB but can dramatically improve latency for intercontinental transfers.

**Key takeaway:** Parallelism — across prefixes, upload parts, and byte ranges — is the core technique; Transfer Acceleration helps when the bottleneck is the public internet path to S3.

</details>

📖 **Theory:** [s3-performance](./04_storage/s3.md#stage-04a--s3-simple-storage-service)


---

### Q75 · [Thinking] · `cloudwatch-logs-insights`

> **What is CloudWatch Logs Insights? Write a query to find the top 10 error messages from the last hour.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**CloudWatch Logs Insights** is an interactive query engine for log data stored in CloudWatch Log Groups. It uses its own SQL-like query language and can scan billions of log events in seconds, returning results you can visualize or export.

**How to think through this:**
1. Logs Insights automatically parses JSON log events into fields you can filter and aggregate.
2. For plain-text logs, you use `parse` to extract fields via regex or glob patterns.
3. The query below filters for error-level entries, groups by message, counts occurrences, and returns the top 10.

```
fields @timestamp, @message
| filter @message like /(?i)error/
| stats count(*) as error_count by @message
| sort error_count desc
| limit 10
```

4. You run this scoped to a specific Log Group and time range (last 1 hour in the console or via `--start-time`/`--end-time` in the CLI).

**Key takeaway:** Logs Insights brings SQL-style aggregation to CloudWatch logs — no need to export to Athena for common operational queries.

</details>

📖 **Theory:** [cloudwatch-logs-insights](./08_monitoring/cloudwatch.md#cloudwatch-logs-insights--query-your-logs)


---

## 🔵 Tier 4 — Interview / Scenario

### Q76 · [Interview] · `explain-vpc-junior`

> **A junior engineer asks how a private EC2 instance reaches the internet. Walk them through the full network path.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Think of a VPC like a private office building. The private subnet is a room with no windows. Here's how someone in that room makes a phone call to the outside world.

**How to think through this:**
1. The EC2 instance has a private IP (e.g., `10.0.2.15`). It generates a packet destined for `8.8.8.8`.
2. The packet hits the **route table** for the private subnet. There's a rule: `0.0.0.0/0 → nat-xxxxxxxx` — all non-local traffic goes to the NAT Gateway.
3. The **NAT Gateway** lives in a *public* subnet. It receives the packet, replaces the source IP with its own **Elastic IP** (a real public IP), and records the translation in its connection table.
4. The NAT Gateway's subnet route table has `0.0.0.0/0 → igw-xxxxxxxx` — all traffic to the internet goes through the **Internet Gateway**.
5. The **Internet Gateway** is the actual border between the VPC and the public internet. It forwards the packet out with the NAT Gateway's Elastic IP as the source.
6. When the response comes back, the IGW receives it, passes it to the NAT Gateway, which looks up its translation table, swaps the destination IP back to `10.0.2.15`, and delivers it to the private instance.
7. At every hop, **Security Groups** and **NACLs** act as gatekeepers checking whether the traffic is allowed.

**Key takeaway:** Private instance → route table → NAT Gateway (translates private IP to public Elastic IP) → Internet Gateway → internet; the NAT Gateway hides all private instances behind one public IP.

</details>

📖 **Theory:** [explain-vpc-junior](./05_networking/vpc.md#stage-05--vpc-virtual-private-cloud)


---

### Q77 · [Interview] · `compare-sqs-sns-eventbridge`

> **Compare SQS, SNS, and EventBridge. When would you use each? Can you use them together?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These three services all move messages between systems but solve different problems.

**How to think through this:**
1. **SQS (Simple Queue Service)** — A durable queue between a producer and one consumer group. Messages sit in the queue until a consumer polls and processes them. Use it when you need load leveling, retry logic with DLQs, and exactly-once or at-least-once delivery. The producer doesn't know or care who consumes.
2. **SNS (Simple Notification Service)** — A pub/sub fan-out system. One message published to a topic is delivered to all subscribed endpoints (SQS queues, Lambda, HTTP, email) simultaneously. Use it when one event needs to trigger multiple independent reactions in parallel.
3. **EventBridge** — A serverless event bus with content-based routing. Events from AWS services, SaaS apps, or your own code are matched against rules using pattern matching on event fields. The right rule routes to the right target. Use it for event-driven architectures where routing logic depends on event content, and for cross-account/cross-region event delivery.
4. **Used together**: A classic pattern is SNS fan-out → multiple SQS queues (each queue is a different consumer with its own processing rate and DLQ). EventBridge → SQS is common for decoupling AWS service events from processing logic with buffering.

**Key takeaway:** SQS buffers work for one consumer, SNS fans out to many consumers at once, EventBridge routes by content — they compose naturally.

</details>

📖 **Theory:** [compare-sqs-sns-eventbridge](./11_serverless/sqs_sns_eventbridge.md#stage-11c--sqs-sns--eventbridge)


---

### Q78 · [Interview] · `explain-iam-roles`

> **Explain why an EC2 instance should use an IAM role instead of embedding access keys. How does STS work in this flow?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Embedding access keys in an EC2 instance is like taping your house key to the front door — it works, but anyone who touches the server now has permanent access.

**How to think through this:**
1. **Access keys are static and long-lived**. If an instance is compromised, the attacker has keys that work until someone manually rotates them. Keys in code or config files leak through git history, AMI snapshots, and debug logs.
2. **IAM roles use temporary credentials**. You attach a role to the EC2 instance. The AWS SDK running on the instance automatically calls the **Instance Metadata Service (IMDS)** at `http://169.254.169.254/latest/meta-data/iam/security-credentials/<role-name>`.
3. **STS (Security Token Service)** is what generates those temporary credentials. When the instance assumes its role, STS issues a time-limited Access Key ID, Secret Access Key, and Session Token (typically valid 1–6 hours). The SDK refreshes these automatically before expiry.
4. If the instance is compromised, the credentials expire on their own. There are no long-lived keys to rotate across every environment. You can also revoke the role's permissions immediately by editing the role policy.

**Key takeaway:** Roles eliminate the secret management problem by replacing static keys with STS-issued short-lived tokens that the SDK rotates automatically.

</details>

📖 **Theory:** [explain-iam-roles](./06_security/iam.md#4-iam-roles--the-right-way-for-applications)


---

### Q79 · [Interview] · `compare-rds-dynamodb`

> **Compare RDS and DynamoDB. What determines which one you should choose for a given workload?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
RDS and DynamoDB represent two fundamentally different data models, not just two database options.

**How to think through this:**
1. **RDS** is a relational database (PostgreSQL, MySQL, etc.). Data is structured in tables with schemas, relationships enforced by foreign keys, and queries written in SQL. It excels at complex queries, joins across tables, and workloads where data relationships and consistency are central. Scales vertically (bigger instance) with read replicas for horizontal read scaling.
2. **DynamoDB** is a key-value and document NoSQL database. Every item is accessed by a primary key (partition key + optional sort key). There are no joins. Schema is flexible per item. It scales horizontally and automatically to virtually unlimited throughput and storage. Single-digit millisecond latency at any scale.
3. **Choose RDS when:** your access patterns are complex and varied (ad-hoc SQL queries), you have relational data with many join patterns, you need ACID transactions across tables, or your team thinks in SQL.
4. **Choose DynamoDB when:** access patterns are known and simple (get by key, query by partition), you need infinite horizontal scale, latency must be consistently in single-digit milliseconds, or you're building serverless/event-driven architectures.

**Key takeaway:** The deciding factor is access patterns — if you know exactly how you'll query the data and it maps to key lookups, DynamoDB wins on scale; if you need flexibility and relational integrity, RDS wins.

</details>

📖 **Theory:** [compare-rds-dynamodb](./07_databases/rds_aurora.md#stage-07a--rds--aurora-managed-relational-databases)


---

### Q80 · [Interview] · `explain-lambda-cold-start`

> **Explain Lambda cold starts to a non-technical product manager and to a senior engineer. What are the mitigation options?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**To a product manager:** Imagine a chef who only comes to work when someone orders food. The first customer of the day waits 2 minutes while the chef puts on their uniform and preheats the stove. Subsequent customers get served fast because the chef is already ready. A Lambda cold start is that setup time — it happens on the first request after the function has been idle.

**To a senior engineer:** When Lambda has no warm execution environment for a function, it must provision a microVM (Firecracker), load the runtime (JVM, Python interpreter, Node.js), download and initialize your deployment package, and run your initialization code (outside the handler). This entire path can take 100ms for a small Python function to several seconds for a Java function with a heavy framework like Spring. It happens on first invocation, after scaling out to new concurrent instances, and after a period of inactivity (~15 minutes).

**How to think through this — mitigations:**
1. **Provisioned concurrency** — Pre-initializes N execution environments. They are always warm. Eliminates cold starts for up to N concurrent requests but costs money even when idle.
2. **Reduce package size** — Smaller deployment packages initialize faster. Avoid unnecessary dependencies.
3. **Choose a faster runtime** — Python and Node.js cold starts are significantly shorter than Java or .NET. Consider runtime if latency is critical.
4. **Warm-up pings** — Schedule EventBridge to invoke the function every few minutes to keep it warm. Fragile for concurrent scaling but free.
5. **Move heavy initialization outside the handler** — DB connections, SDK clients initialized at module level are reused across invocations in the same environment.

**Key takeaway:** Cold starts are the cost of serverless elasticity; provisioned concurrency eliminates them at a financial cost, so the tradeoff is latency sensitivity vs. idle cost.

</details>

📖 **Theory:** [explain-lambda-cold-start](./11_serverless/lambda.md#7-cold-starts--the-main-trade-off)


---

### Q81 · [Design] · `scenario-high-traffic-event`

> **Your e-commerce app expects 50x normal traffic during a Black Friday sale. Walk through how you'd architect AWS services to handle it without pre-provisioning everything.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The goal is elastic scale-out that triggers automatically, not a cluster you size manually the night before.

**How to think through this:**
1. **Edge layer** — Put CloudFront in front of everything. Static assets (product images, JS bundles) are cached at edge locations globally. This eliminates 60–80% of origin requests before they touch your infrastructure.
2. **API layer** — Use ALB + ECS Fargate or Lambda for the API. Fargate scales out task count based on ALB request count target tracking. Lambda scales automatically up to account concurrency limits — no config needed. Set reserved concurrency on critical functions to protect them.
3. **Database layer** — Aurora Serverless v2 scales compute in near-real-time. Add read replicas for read-heavy product browsing. For the shopping cart (hot key access), use ElastiCache (Redis) to absorb read traffic and session state.
4. **Queue as a shock absorber** — Order submission writes to an SQS queue, not directly to the database. The downstream processor reads at a controlled rate. This decouples the user-facing API (which must be fast) from the order processing (which can be slightly delayed). Add a DLQ for failed orders.
5. **Pre-warm where necessary** — Set provisioned concurrency on checkout Lambda functions if cold start latency during the first rush is unacceptable. Pre-warm ElastiCache by loading product catalog before the event.
6. **Load test beforehand** — Use AWS Distributed Load Testing or k6 to simulate 50x traffic and validate that Auto Scaling policies trigger fast enough.

**Key takeaway:** The pattern is: cache at the edge, auto-scale compute, use queues to decouple load spikes from databases, and let Aurora Serverless handle DB compute scaling.

</details>

📖 **Theory:** [scenario-high-traffic-event](./03_compute/auto_scaling.md#stage-03b--auto-scaling--load-balancing)


---

### Q82 · [Design] · `scenario-data-breach`

> **You get an alert that an S3 bucket with customer data is publicly accessible. Walk through your incident response steps.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Treat this as a two-track response: containment happens immediately in parallel with investigation.

**How to think through this:**
1. **Contain immediately** — Block public access on the bucket using S3 Block Public Access settings. This overrides any bucket policy or ACL allowing public access. Do this in under 2 minutes. Do not delete anything — preserve evidence.
2. **Assess scope** — Check S3 Server Access Logs and CloudTrail data events for the bucket. Answer: what objects were accessed, by whom (IP, user agent), and when? CloudTrail `GetObject` events show every successful read. If logging wasn't enabled, document that as a gap.
3. **Determine how it happened** — Was it a bucket policy misconfiguration? A public ACL on individual objects? Was Block Public Access disabled at the account level? Check AWS Config for the timeline of configuration changes.
4. **Notify** — Escalate internally per your incident response plan. Depending on what data was exposed and your jurisdiction, legal and compliance teams may need to initiate breach notification (GDPR 72-hour window, CCPA, HIPAA, etc.).
5. **Harden** — Enable S3 Block Public Access at the account level (not just bucket level). Enable AWS Config rule `s3-bucket-public-read-prohibited`. Set up Security Hub and GuardDuty to catch this class of misconfiguration going forward. Audit all other buckets.
6. **Document and remediate** — Write a post-mortem. Add the detection gap to your runbooks. If data was confirmed exfiltrated, rotate any secrets or tokens that may have been in the exposed objects.

**Key takeaway:** Contain first (block public access), then investigate (CloudTrail + access logs), then notify legal, then harden the class of misconfiguration — never skip the evidence-preservation step.

</details>

📖 **Theory:** [scenario-data-breach](./06_security/iam.md#stage-06a--iam-identity--access-management)


---

### Q83 · [Design] · `scenario-lambda-timeout`

> **A Lambda function that processes SQS messages starts timing out under load. What are your options?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A Lambda timing out on SQS messages is a compound problem: the function is too slow AND messages keep reappearing because the visibility timeout may be shorter than the processing time.

**How to think through this:**
1. **Fix the visibility timeout mismatch first** — The SQS visibility timeout must be at least 6x the Lambda timeout (AWS recommendation). If Lambda times out at 30s but visibility timeout is 20s, the message becomes visible again before Lambda finishes, causing duplicate processing. Set visibility timeout to at least 6 × Lambda timeout.
2. **Increase the Lambda timeout** — Maximum is 15 minutes. If your processing genuinely needs more time, raise it. But don't just raise it blindly — understand why it's slow first.
3. **Optimize the function** — Profile where time is spent. Common culprits: synchronous HTTP calls to slow APIs, large payloads, inefficient DB queries, missing connection pooling. Fix the root cause.
4. **Reduce batch size** — The SQS event source mapping delivers messages in batches. A large batch means more work per invocation. Reduce batch size so each invocation finishes well within the timeout.
5. **Move to async/parallel processing** — If individual messages are independent, use `Promise.all` (Node.js) or `asyncio.gather` (Python) to process batch items in parallel within one invocation rather than serially.
6. **Offload to Step Functions** — For truly long-running workflows (>15 minutes), Lambda is the wrong tool. Trigger a Step Functions Express Workflow from Lambda to orchestrate multi-step processing with no timeout constraint.

**Key takeaway:** Fix the visibility timeout / Lambda timeout mismatch to stop message redelivery loops, then address root cause — either optimize the function or change the processing architecture.

</details>

📖 **Theory:** [scenario-lambda-timeout](./11_serverless/lambda.md#stage-11a--lambda-serverless-compute)


---

### Q84 · [Design] · `scenario-multi-region`

> **Design a multi-region active-active architecture for a critical API. What services do you use and what are the main challenges?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Active-active means both regions serve live traffic simultaneously and can handle full load if the other fails — not just warm standby.

**How to think through this:**
1. **DNS routing** — Route 53 with latency-based or geolocation routing directs users to the nearest region. Health checks automatically remove a region from DNS if it fails. Failover happens in seconds (TTL-dependent).
2. **Compute** — Deploy identical ECS/Fargate or Lambda stacks in both regions behind regional ALBs. Use Infrastructure as Code (CloudFormation/Terraform) to keep them identical.
3. **Database — the hardest part** — Reads are easy; writes are the challenge. Options:
   - **Aurora Global Database**: one primary write region, secondary read replica regions. Writes still go to primary — this is active-passive for writes, active-active for reads.
   - **DynamoDB Global Tables**: true active-active writes in all regions with eventual consistency replication. Best for high-scale, key-value access patterns.
4. **Conflict resolution** — With DynamoDB Global Tables, concurrent writes to the same item in different regions use last-writer-wins. Design your data model to minimize conflicts (e.g., user-partitioned data, append-only events).
5. **Data consistency** — Accept that active-active = eventual consistency between regions. Design the application to tolerate reading slightly stale data. Use idempotency keys to handle duplicate writes.
6. **Session/cache layer** — Each region needs its own ElastiCache cluster. Don't share cache across regions — latency would negate the benefit.
7. **Operational challenges** — Deployment pipelines must deploy to all regions, test must cover cross-region scenarios, observability must aggregate metrics from both regions (CloudWatch cross-account/region dashboards).

**Key takeaway:** Active-active is achievable with Route 53 + DynamoDB Global Tables for writes; the main challenge is conflict resolution and accepting eventual consistency as a design constraint.

</details>

📖 **Theory:** [scenario-multi-region](./14_architecture/high_availability.md#active-active-multi-region)


---

### Q85 · [Design] · `scenario-cost-spike`

> **Your AWS bill unexpectedly doubled this month. Walk through how you'd diagnose which service and usage pattern caused the increase.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Cost investigation is a structured narrowing process: account → service → resource → usage pattern.

**How to think through this:**
1. **Start with Cost Explorer** — Open the AWS Cost Explorer, set the time range to the last 2 months, group by Service. Immediately identify which service's cost increased. Sort by month-over-month delta.
2. **Drill into the service** — Click into the offending service. Group by Usage Type to see what specific usage dimension increased (e.g., for EC2: instance hours, data transfer out, EBS volume-months). For S3: storage, PUT requests, data transfer.
3. **Check Cost Allocation Tags** — If your team tags resources by environment, team, or application, filter by tag to narrow to a specific workload or team.
4. **Look at usage metrics in CloudWatch** — Match the cost spike timing to CloudWatch metrics. Did EC2 instance count go up? Did an Auto Scaling Group fail to scale down? Did a Lambda function run 100x more than usual?
5. **Common culprits:**
   - **Data transfer** — Cross-AZ, cross-region, or internet-egress traffic is a frequent surprise. Check VPC Flow Logs and Cost Explorer's data transfer breakdown.
   - **NAT Gateway** — Charged per GB processed. A misconfigured service routing all S3 traffic through NAT Gateway instead of a VPC Endpoint is a classic expensive mistake.
   - **EC2/RDS not scaling down** — Auto Scaling scale-in not triggering due to a misconfigured policy.
   - **S3 request costs** — Millions of small GET/PUT operations add up if a new feature polls S3 frequently.
6. **Set up AWS Budgets alerts** — After resolving, set budget thresholds with email/SNS alerts at 80% and 100% of expected spend so you catch it next time before it doubles.

**Key takeaway:** Cost Explorer by service then by usage type narrows the culprit in minutes; NAT Gateway data transfer and EC2 scale-in failures are the most common surprise doublers.

</details>

📖 **Theory:** [scenario-cost-spike](./15_cost_optimization/theory.md#stage-15--cost-optimization)


---

### Q86 · [Interview] · `compare-fargate-ec2`

> **Compare running containers on ECS with EC2 launch type vs Fargate. When would you choose each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The core tradeoff is control vs. operational overhead.

**How to think through this:**
1. **EC2 launch type** — You manage EC2 instances that form the cluster capacity. You choose instance types, manage patching, configure the ECS agent, and handle capacity planning. You can SSH into nodes for debugging, run DaemonSets-equivalent (ECS daemon scheduling), and use GPU instances. You pay for instances whether or not tasks are running on them.
2. **Fargate** — AWS manages all underlying compute. You define task CPU and memory, and AWS runs the task in an isolated microVM. No instances to patch, no capacity planning, no idle instance cost. You pay only for the vCPU and memory consumed while the task runs.
3. **Choose EC2 when:**
   - You need GPU instances for ML inference workloads
   - You have large, stable workloads where Reserved Instance pricing makes EC2 cheaper
   - You need to run host-level monitoring agents (ECS daemon tasks)
   - You need privileged container access or specific kernel configurations
4. **Choose Fargate when:**
   - You want zero node management
   - Workloads are bursty or unpredictable — pay-per-task pricing avoids idle costs
   - You're building serverless-style microservices
   - Security isolation per task matters (each Fargate task gets its own kernel)

**Key takeaway:** Fargate for simplicity and bursty workloads; EC2 for control, GPU requirements, or high-volume steady workloads where Reserved Instances reduce cost.

</details>

📖 **Theory:** [compare-fargate-ec2](./10_containers/ecs.md#5-fargate-vs-ec2-launch-type)


---

### Q87 · [Interview] · `explain-cloudformation-drift`

> **What is CloudFormation stack drift? How do you detect and remediate it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
**Drift** occurs when the actual state of an AWS resource differs from the state CloudFormation expects based on the last deployed template. Think of it as your infrastructure going off-script.

**How to think through this:**
1. Drift happens when someone modifies a resource outside CloudFormation — manually changing an EC2 security group in the console, updating an RDS parameter via the CLI, or another automation tool modifying a resource CloudFormation manages.
2. **Detecting drift** — Run a drift detection operation on the stack via the console or CLI (`aws cloudformation detect-stack-drift`). CloudFormation compares actual resource configuration to the expected template configuration and reports each resource as `IN_SYNC` or `DRIFTED`. For drifted resources, it shows the specific property differences.
3. **Remediating drift** — You have two options:
   - **Bring reality back to the template**: manually revert the out-of-band changes, then re-run drift detection to confirm.
   - **Bring the template in line with reality**: update the CloudFormation template to reflect the intended current state, then run a stack update. This is appropriate when the manual change was intentional and correct.
4. **Preventing future drift** — Use IAM policies to restrict direct resource modification for resources managed by CloudFormation. Require all changes to go through the CI/CD pipeline that deploys CloudFormation changes. AWS Config rules can alert on changes to specific resource types.

**Key takeaway:** Drift is the gap between declared and actual infrastructure state; detect it with CloudFormation's built-in detection, then decide whether to revert reality or update the template.

</details>

📖 **Theory:** [explain-cloudformation-drift](./09_iac/cloudformation.md#stage-09a--cloudformation-infrastructure-as-code)


---

### Q88 · [Design] · `scenario-microservices-comm`

> **Design communication between 3 microservices on AWS: Service A calls B synchronously, B publishes events for C to process asynchronously. Which services do you use?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
This is a hybrid pattern combining synchronous RPC and event-driven async processing.

**How to think through this:**
1. **A → B (synchronous)** — A needs an immediate response from B. Options:
   - If A and B are within the same VPC: direct HTTP/gRPC call via internal ALB or AWS Cloud Map (service discovery). Simple, low latency.
   - If they're decoupled microservices where A shouldn't know B's IP: API Gateway (HTTP API) in front of B with a VPC Link, or App Mesh for service mesh-level routing, retries, and circuit breaking.
2. **B → C (asynchronous event publishing)** — B fires an event after completing its work and doesn't wait for C. Options:
   - **SNS → SQS**: B publishes to an SNS topic. C subscribes via an SQS queue. This decouples B from C, buffers messages if C is slow, and provides retry logic with a DLQ.
   - **EventBridge**: if the event needs content-based routing to multiple consumers or integrates with other AWS services, EventBridge is more flexible.
   - **Direct SQS**: if there's only ever one consumer (C), B can write directly to the SQS queue, skipping the SNS fan-out layer.
3. **Error handling** — Add a DLQ to the SQS queue. If C fails to process a message after N retries, the message moves to the DLQ for alerting and manual investigation.
4. **Observability** — Use AWS X-Ray to trace the full request chain A→B→event→C. Distributed tracing requires passing the trace context header through all hops.

**Key takeaway:** Synchronous path uses ALB or API Gateway for A→B; asynchronous path uses SNS+SQS or direct SQS for B→C, with a DLQ for failure handling.

</details>

📖 **Theory:** [scenario-microservices-comm](./11_serverless/sqs_sns_eventbridge.md#stage-11c--sqs-sns--eventbridge)


---

### Q89 · [Design] · `scenario-database-migration`

> **You need to migrate a 2TB on-premise PostgreSQL database to RDS with less than 1 hour downtime. What is your migration strategy?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The key insight is that you can't migrate 2TB in under an hour by copying it at cutover — the data must already be in RDS before the maintenance window begins.

**How to think through this:**
1. **Phase 1 — Bulk load (days before, no downtime)** — Use **AWS Database Migration Service (DMS)** full-load task or `pg_dump | pg_restore` over Direct Connect/VPN to copy the existing 2TB to RDS. This runs alongside the live on-premise database. At this point, RDS is slightly behind.
2. **Phase 2 — Enable CDC replication** — Switch the DMS task to **Change Data Capture (CDC)** mode, which reads from the PostgreSQL WAL (write-ahead log) and continuously replicates inserts, updates, and deletes to RDS. The source DB must have `wal_level = logical` enabled. DMS keeps RDS within seconds of the source.
3. **Phase 3 — Verify** — Run data validation queries on both databases to confirm row counts, checksums on critical tables, and referential integrity. Fix any DMS replication errors before scheduling the cutover.
4. **Phase 4 — Cutover window (<1 hour)** — Stop writes to the on-premise database (maintenance mode or DNS flip to a holding page). Wait for CDC lag to reach zero (confirm with DMS task metrics). Run final validation. Update application connection strings to point to the RDS endpoint. Resume traffic. Total window: 15–30 minutes if validation is pre-done.
5. **Rollback plan** — Keep DMS running in reverse (RDS → on-premise) for a few hours post-cutover so you can flip back if critical issues arise.

**Key takeaway:** The migration is mostly invisible — CDC keeps RDS in sync continuously; the cutover window is just the time to drain replication lag to zero and flip the connection string.

</details>

📖 **Theory:** [scenario-database-migration](./07_databases/rds_aurora.md#stage-07a--rds--aurora-managed-relational-databases)


---

### Q90 · [Design] · `scenario-secrets-rotation`

> **Design a secret rotation strategy for a Lambda function that connects to RDS. How do you rotate the password without downtime?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The challenge is that at the moment of rotation, old connections are using the old password while new connections need the new one. The solution is to overlap valid credentials during the transition.

**How to think through this:**
1. **Store the secret in AWS Secrets Manager** — The RDS password (and connection string) lives in Secrets Manager, not in Lambda environment variables. Lambda retrieves it at runtime via the Secrets Manager API (with SDK caching to avoid per-invocation API calls).
2. **Enable automatic rotation in Secrets Manager** — Secrets Manager supports RDS-native rotation using a built-in Lambda rotation function. You set a rotation schedule (e.g., every 30 days) and Secrets Manager calls the rotation Lambda automatically.
3. **The rotation Lambda follows a 4-step process:**
   - **createSecret** — Generate a new password and store it as the `AWSPENDING` version in Secrets Manager.
   - **setSecret** — Set the new password on the RDS instance using the current credentials. At this point, both old and new passwords are valid on the DB (for supported engines, RDS supports two active passwords during rotation).
   - **testSecret** — Verify the new password actually works by making a test connection using the `AWSPENDING` version.
   - **finishSecret** — Promote `AWSPENDING` to `AWSCURRENT`. The old version becomes `AWSPREVIOUS` and remains valid for a short grace period.
4. **Lambda caching** — Lambda functions should cache the secret value with a short TTL (e.g., 5 minutes). When a connection error occurs (auth failure), the function should immediately refresh the secret from Secrets Manager and retry. This handles the race condition where a warm Lambda has the old secret after rotation.
5. **Connection pool awareness** — Existing DB connections made with the old password remain open until they close naturally. RDS doesn't terminate active connections on password change. New connections use the new password retrieved from Secrets Manager.

**Key takeaway:** Zero-downtime rotation works because RDS supports two valid passwords during rotation, and the rotation Lambda promotes the new one only after verifying it works — the overlap period is the safety net.

</details>

📖 **Theory:** [scenario-secrets-rotation](./06_security/kms.md#6-aws-secrets-manager)


---

## 🔴 Tier 5 — Critical Thinking

### Q91 · [Logical] · `predict-sg-traffic`

> **An EC2 instance has a security group that allows inbound 443 but no outbound rules. Can it send HTTPS responses back? Explain the stateful rule behavior.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Yes — the instance can send HTTPS responses even with no outbound rules configured.

**How to think through this:**
1. Security groups are **stateful**. This is the critical distinction from NACLs (which are stateless).
2. When an inbound connection is allowed (the client's SYN packet matches the inbound rule for port 443), the security group automatically tracks that connection in its state table.
3. All return traffic for that tracked connection — the SYN-ACK, ACK, and all subsequent response packets — is automatically allowed outbound, regardless of outbound rules.
4. The outbound rules only apply to **new connections initiated from the instance** (e.g., the instance making an outbound API call to `api.github.com:443`). Those would be blocked if no outbound rule exists.
5. By contrast, NACLs are **stateless**: they evaluate every packet independently. A NACL with inbound 443 allowed and no outbound rules would block the response packets, breaking the connection.

**Key takeaway:** Security groups track connection state, so return traffic for allowed inbound connections is automatically permitted — no outbound rule needed for responses, only for new outbound-initiated connections.

</details>

📖 **Theory:** [predict-sg-traffic](./05_networking/vpc.md#stage-05--vpc-virtual-private-cloud)


---

### Q92 · [Logical] · `predict-s3-delete`

> **A versioned S3 bucket has 3 versions of `file.txt`. You run `aws s3 rm s3://bucket/file.txt`. How many versions remain and what happened?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
All 3 original versions remain. A 4th entry — a **delete marker** — is added. The total object count (versions + markers) is now 4.

**How to think through this:**
1. In a versioning-enabled bucket, `aws s3 rm` (and the equivalent `DeleteObject` API call without a `--version-id`) does not permanently delete any version. It inserts a delete marker with a new version ID.
2. A delete marker is a zero-byte placeholder that makes the object appear deleted to standard `GET` requests. If you try `aws s3 cp s3://bucket/file.txt .` after this, you'll get a 404.
3. The 3 original versions are untouched and still exist. You can list them with `aws s3api list-object-versions --bucket bucket --prefix file.txt`.
4. To permanently delete a specific version, you must use `aws s3api delete-object --bucket bucket --key file.txt --version-id <id>` — explicitly targeting a version ID.
5. To fully purge the object and all versions, you must delete each version ID individually (or use a lifecycle policy with `NoncurrentVersionExpiration`).

**Key takeaway:** `s3 rm` on a versioned bucket adds a delete marker — it hides the object, it does not delete it. All 3 versions survive; permanent deletion requires targeting specific version IDs.

</details>

📖 **Theory:** [predict-s3-delete](./04_storage/s3.md#stage-04a--s3-simple-storage-service)


---

### Q93 · [Logical] · `predict-lambda-timeout`

> **A Lambda function has a 30-second timeout. An SQS trigger has a visibility timeout of 20 seconds. What happens when the function takes 25 seconds to run?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The message becomes visible again in the queue while Lambda is still processing it. This causes duplicate processing.

**How to think through this:**
1. Lambda picks up the message and starts processing. The SQS visibility timeout clock starts.
2. At T=20 seconds, the SQS visibility timeout expires. From SQS's perspective, the consumer failed (it never received a delete confirmation), so the message becomes visible again.
3. Lambda (or another concurrent Lambda instance) may now pick up the same message and start processing it again — even though the first invocation is still running and will complete at T=25 seconds.
4. The first invocation finishes at T=25 seconds and calls `DeleteMessage`. The second invocation also eventually calls `DeleteMessage`. Depending on timing, you get the message processed twice.
5. The AWS recommendation is: **SQS visibility timeout = at least 6 × Lambda timeout**. For a 30-second Lambda, set visibility timeout to at least 180 seconds. This ensures SQS doesn't release the message until Lambda has had ample time to succeed or fail.
6. This also highlights why Lambda SQS processors must be **idempotent** — at-least-once delivery means duplicates can happen even with correct settings (e.g., Lambda succeeds but delete fails due to a transient error).

**Key takeaway:** Visibility timeout shorter than Lambda execution time causes the message to reappear mid-processing, leading to duplicate delivery — always set visibility timeout to 6× the Lambda timeout.

</details>

📖 **Theory:** [predict-lambda-timeout](./11_serverless/lambda.md#stage-11a--lambda-serverless-compute)


---

### Q94 · [Debug] · `debug-iam-access-denied`

> **An EC2 instance with an IAM role gets `AccessDenied` when calling `s3:GetObject` on a specific bucket. The role policy allows `s3:GetObject` on `*`. What other factors could cause this?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
IAM is a multi-layer system. An `Allow` in one layer can be overridden by a `Deny` in another.

**How to think through this:**
1. **S3 bucket policy with an explicit Deny** — The bucket has a resource-based policy that explicitly denies `s3:GetObject` from this role or this VPC. Explicit `Deny` always wins over any `Allow`, regardless of the identity policy. Check the bucket policy first.
2. **S3 bucket policy requires a condition that isn't met** — For example, the bucket policy only allows access from a specific VPC endpoint (`aws:SourceVpce`), and the instance is accessing S3 via the internet or NAT Gateway instead.
3. **S3 Block Public Access + bucket policy conflict** — If the bucket is set to block public access and the bucket policy attempts to grant public access, S3 enforces the block even if the IAM side is fine.
4. **Permission boundary on the role** — The EC2 role may have a permission boundary attached that does not include `s3:GetObject`. Permission boundaries act as a ceiling — the effective permissions are the intersection of the identity policy and the boundary.
5. **AWS Organizations Service Control Policy (SCP)** — If the account is in an AWS Organization, an SCP may deny S3 access for workloads without a specific condition (e.g., requiring S3 access only through VPC endpoints).
6. **Server-Side Encryption with KMS (SSE-KMS)** — The objects are encrypted with a KMS key, and the role does not have `kms:Decrypt` permission on that key. The error message is `AccessDenied` but the root cause is the KMS key policy.
7. **Wrong region or account** — The bucket is in a different account and the cross-account permissions chain is incomplete.

**Key takeaway:** `AccessDenied` despite an `Allow` means check for explicit Denies in bucket policies, SCPs, permission boundaries, and KMS key policies — any one of these can override the `Allow`.

</details>

📖 **Theory:** [debug-iam-access-denied](./06_security/iam.md#stage-06a--iam-identity--access-management)


---

### Q95 · [Debug] · `debug-vpc-connectivity`

> **Two EC2 instances in the same VPC but different subnets can't communicate. Both have inbound rules allowing all traffic. What are 3 things to check?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Same VPC means they're logically connected — the issue is a configuration layer blocking the path.

**How to think through this:**

1. **Route tables** — Each subnet has a route table. By default, a VPC has a local route (`10.0.0.0/16 → local`) that covers all subnets. Check that neither subnet's route table has had the local route removed or overridden, and that there's no more-specific route pointing traffic elsewhere (e.g., to a NAT Gateway or transit gateway for a prefix that includes the destination IP).

2. **Network ACLs (NACLs)** — Unlike security groups, NACLs are stateless and apply at the subnet boundary. A NACL rule on either subnet could be blocking the traffic. Check both the inbound NACL of the destination subnet and the outbound NACL of the source subnet. Remember NACLs are evaluated in rule number order and the first match wins — an explicit `DENY` at rule 100 overrides an `ALLOW` at rule 200.

3. **Security group outbound rules** — The question says both instances have inbound rules allowing all traffic, but says nothing about outbound rules. Security groups are stateful for responses, but for a new connection from Instance A to Instance B, the *outbound* security group on Instance A must allow the traffic. If outbound is set to allow only port 443 and the communication is on port 5432 (PostgreSQL), the connection is blocked before it even reaches Instance B's inbound rule.

**Key takeaway:** Same-VPC connectivity failures trace to route tables (routing the packet wrong), NACLs (stateless subnet-boundary filters), or outbound security group rules on the source instance.

</details>

📖 **Theory:** [debug-vpc-connectivity](./05_networking/vpc.md#10-vpc-endpoints-private-connectivity-to-aws-services)


---

### Q96 · [Debug] · `debug-lambda-environment`

> **A Lambda function works perfectly in `us-east-1` but fails in `eu-west-1` with the same code. What are the likely causes?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Same code, different behavior — the code isn't the variable. The environment and its dependencies are.

**How to think through this:**
1. **Missing or different environment variables** — Lambda environment variables are set per function per region. If the `eu-west-1` deployment was done separately, it may be missing a variable (database endpoint, API key, feature flag) that exists in `us-east-1`. Check both function configurations side-by-side.
2. **Downstream services not deployed to the region** — The Lambda calls an RDS endpoint, an internal API, or a DynamoDB table that only exists in `us-east-1`. The `eu-west-1` function reaches a non-existent endpoint and times out or gets a connection error.
3. **Secrets Manager or Parameter Store values missing** — If the function retrieves secrets at runtime from a regional service, those secrets must be replicated to `eu-west-1`. They're not automatically global.
4. **IAM permissions difference** — The Lambda execution role in `eu-west-1` may not have the same policies as the `us-east-1` role, especially if roles are managed separately per region.
5. **S3 bucket or resource is us-east-1 only** — The function accesses a specific S3 bucket by name. S3 bucket names are global but buckets are regional. A `eu-west-1` Lambda making a request to a `us-east-1` bucket incurs cross-region latency and potential VPC routing issues if accessing via VPC endpoints.
6. **VPC and subnet configuration difference** — If the function runs in a VPC, the `eu-west-1` VPC may lack the necessary subnet routes or security group rules that exist in `us-east-1`.

**Key takeaway:** Region-specific failures almost always trace to missing environment variables, missing downstream resources not deployed to that region, or absent secrets/IAM policies — infrastructure gaps, not code bugs.

</details>

📖 **Theory:** [debug-lambda-environment](./11_serverless/lambda.md#stage-11a--lambda-serverless-compute)


---

### Q97 · [Design] · `design-serverless-pipeline`

> **Design a serverless data pipeline that ingests CSV files dropped into S3, processes each row, validates it, and stores results in DynamoDB, with failures going to a DLQ.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
This is a classic serverless event-driven pipeline — every component scales to zero and charges only for what it uses.

**How to think through this:**

```
S3 (CSV drop) → S3 Event Notification → SQS (ingest queue)
                                              ↓
                                     Lambda (file processor)
                                     - reads CSV from S3
                                     - sends each row to row queue
                                              ↓
                               SQS (row queue) → Lambda (row processor)
                                     - validates row schema
                                     - writes valid rows to DynamoDB
                                     - invalid rows → SQS DLQ
```

**Step-by-step:**
1. **S3 trigger** — Configure an S3 Event Notification (`s3:ObjectCreated`) on the target prefix (e.g., `incoming/`). Send the notification to an SQS queue (not directly to Lambda — SQS provides buffering and retry).
2. **File processor Lambda** — Triggered by the ingest SQS queue. Downloads the CSV from S3 using the key in the event, parses it row by row, and sends each row as a JSON message to a second SQS queue (the row queue). Batch size 1 per file recommended.
3. **Row processor Lambda** — Triggered by the row queue. Validates each row against a schema (required fields, data types, value ranges). Valid rows go to `DynamoDB PutItem`. Invalid rows are not retried — they're sent to a **DLQ** via SQS's redrive policy after N failures, or explicitly by the function.
4. **DLQ** — An SQS queue that receives failed row messages. Subscribe an SNS topic to alert on-call when the DLQ receives messages. Failed rows can be replayed manually after investigation.
5. **Error handling on the file processor** — If the CSV can't be parsed (corrupt file), the file processor Lambda fails. The ingest SQS queue retries it N times, then sends the S3 event to a second DLQ for file-level failures.
6. **Observability** — Lambda Destinations or CloudWatch metrics on DLQ depth provide visibility. Use structured logging (JSON) with row identifiers for traceability.

**Key takeaway:** Two-stage SQS fan-out (file → rows) decouples file ingestion from row processing; DLQs at both stages capture failures without losing data.

</details>

📖 **Theory:** [design-serverless-pipeline](./11_serverless/step_functions.md#stage-11d--step-functions-serverless-workflows)


---

### Q98 · [Design] · `design-blue-green-deployment`

> **Design a blue-green deployment for an ECS service using ALB. Walk through the rollout and rollback process.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Blue-green deployment keeps two identical production environments — blue (live) and green (new version) — and flips traffic between them atomically.

**How to think through this:**

**Setup:**
1. The ALB has two target groups: `blue-tg` (current production tasks) and `green-tg` (new version tasks). The ALB listener's production rule forwards 100% of traffic to `blue-tg`.
2. A test listener (e.g., port 8080) points to `green-tg` for pre-cutover validation.

**Rollout process:**
1. **Deploy new version to green** — Update the ECS task definition with the new container image tag. Register new tasks in the green ECS service. They start and register with `green-tg`. Health checks pass.
2. **Validate green** — Run smoke tests, integration tests, or manual checks against the ALB test listener (port 8080 → green-tg). Confirm the new version behaves correctly with no traffic.
3. **Shift traffic** — Modify the ALB production listener rule to forward traffic to `green-tg`. This is an atomic API call — traffic shifts instantly. Blue tasks are still running but receive no traffic.
4. **Monitor** — Watch error rates, latency, and business metrics for 10–30 minutes. CloudWatch alarms on 5xx rates can trigger automatic rollback if configured with CodeDeploy.

**Rollback process:**
1. If issues are detected, modify the ALB production listener rule to point back to `blue-tg`. Traffic shifts back instantly.
2. Blue tasks are still running and warmed up — zero cold start on rollback.
3. Investigate and fix the green version. Repeat the process.

**Cleanup:**
After a successful deployment with sufficient bake time, terminate the old blue tasks to stop paying for idle compute. The new version is now blue for the next deployment cycle.

**AWS CodeDeploy integration** — ECS has native integration with CodeDeploy for blue-green. CodeDeploy manages the traffic shifting (including canary or linear options), monitors CloudWatch alarms, and auto-rolls back on alarm breach.

**Key takeaway:** Blue-green on ECS+ALB is a target group swap — green is validated before any production traffic touches it, and rollback is a single ALB rule change with pre-warmed blue tasks still running.

</details>

📖 **Theory:** [design-blue-green-deployment](./14_architecture/high_availability.md#stage-14--high-availability-architecture-patterns)


---

### Q99 · [Critical] · `edge-case-sqs-deduplication`

> **An SQS FIFO queue is configured for content-based deduplication. Two identical messages are sent 3 minutes apart. Which ones get delivered?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Both messages get delivered. The second message is treated as a new, unique message.

**How to think through this:**
1. Content-based deduplication in SQS FIFO works by hashing the message body (SHA-256) to generate a **deduplication ID**. If two messages with the same deduplication ID are sent within the **5-minute deduplication interval**, the second is considered a duplicate and discarded.
2. The deduplication window is exactly **5 minutes**. After 5 minutes, the deduplication ID expires from the seen-IDs tracking table.
3. In this scenario, the messages are sent **3 minutes apart** — well within the 5-minute window. If this were 3 minutes apart, the second message would be deduplicated and discarded. Only the first would be delivered.
4. Wait — the question says **3 minutes apart**. So the second message arrives at T=3 minutes, which is within the 5-minute window. The deduplication ID (hash of the identical content) is still active. The second message is **discarded** as a duplicate.
5. Correction: only **1 message is delivered** — the first one. The second is silently dropped.

**Clarifying the edge:**
- 3 minutes apart → within 5-minute window → deduplicated → 1 delivery
- 6 minutes apart → outside 5-minute window → both delivered → 2 deliveries

**Key takeaway:** SQS FIFO content-based deduplication silently drops duplicate messages within a 5-minute rolling window — messages 3 minutes apart result in only 1 delivery; messages 6+ minutes apart are both delivered.

</details>

📖 **Theory:** [edge-case-sqs-deduplication](./11_serverless/sqs_sns_eventbridge.md#stage-11c--sqs-sns--eventbridge)


---

### Q100 · [Critical] · `edge-case-lambda-concurrency`

> **Your Lambda has reserved concurrency set to 10. Suddenly 50 requests arrive simultaneously. What happens to the extra 40 requests? How does this interact with an SQS trigger differently than an API Gateway trigger?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Reserved concurrency of 10 means at most 10 executions run simultaneously. The behavior of the extra 40 requests depends entirely on the trigger source.

**How to think through this:**

**With API Gateway trigger:**
1. API Gateway sends each HTTP request directly to Lambda as a synchronous invocation.
2. When Lambda is at the 10-concurrency limit, the 11th through 50th requests get a **throttle error** — HTTP 429 (Too Many Requests) returned immediately to the caller.
3. API Gateway does not retry throttled Lambda invocations. The client receives the 429 and must handle it (retry logic, exponential backoff).
4. From the user's perspective: 10 users get responses, 40 users see errors. This is loud and visible.

**With SQS trigger:**
1. Lambda's Event Source Mapping (ESM) polls the SQS queue and manages concurrency against the reserved limit.
2. When Lambda is at the 10-concurrency limit, the ESM **stops polling**. Messages stay in the SQS queue — they are not lost and do not error.
3. As Lambda executions complete and concurrency frees up, the ESM resumes polling and processes the next batch.
4. The 40 "extra" messages simply wait in the queue. They are eventually processed. No data loss, no errors to the original producer.
5. The tradeoff: messages experience latency (queuing delay), not errors. If the queue grows very large, messages may approach the message retention period (default 4 days) before processing.

**The fundamental difference:**
- API Gateway is push-based and synchronous — Lambda can't buffer, so excess requests fail.
- SQS is pull-based and asynchronous — the queue is the buffer. Lambda's ESM naturally rate-limits itself and processes the backlog as capacity frees up.

**Key takeaway:** Reserved concurrency throttles API Gateway callers with 429 errors (client-visible), but throttles SQS processing by pausing polling — messages queue safely and drain as capacity returns, making SQS naturally resilient to concurrency limits.

</details>

📖 **Theory:** [edge-case-lambda-concurrency](./11_serverless/lambda.md#9-lambda-concurrency--throttling)
