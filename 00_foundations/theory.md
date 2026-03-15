# AWS Foundations — Cloud Computing & Global Infrastructure

## 1. Core Intuition

Imagine you need to run a web application. You have two choices:

**Option A — Buy your own server:**
Buy expensive hardware. Set it up in your office. Pay for electricity. Hire someone to maintain it. When traffic spikes, you're stuck. When it's quiet, the hardware sits idle.

**Option B — Rent from AWS:**
Log in, click a button, and you have a server running in seconds. Pay only when it's on. Scale to 100 servers in minutes. When you don't need it — turn it off, stop paying.

AWS is a **global cloud computing platform** that lets you rent computing resources instead of owning them. You focus on building your application. AWS handles the hardware, electricity, cooling, and physical security.

## 2. The Problem Cloud Solves

### The Old World (On-Premise)

```
Traditional Data Center Problems:
┌─────────────────────────────────────────────────┐
│  💸 Huge upfront cost   → Buy servers before    │
│                           you have any users    │
│                                                  │
│  ⏳ Slow provisioning   → 6-8 weeks to get       │
│                           new hardware          │
│                                                  │
│  📦 Over-provisioning   → Buy for peak load,     │
│                           idle 90% of time      │
│                                                  │
│  🔧 Maintenance burden  → Updates, failures,     │
│                           hardware replacements │
│                                                  │
│  🌍 Limited geography   → Single location,       │
│                           no global scale       │
└─────────────────────────────────────────────────┘
```

### The Cloud World

```
Cloud Benefits:
┌─────────────────────────────────────────────────┐
│  💰 Pay-as-you-go      → Only pay for what       │
│                           you actually use      │
│                                                  │
│  ⚡ Instant scale      → Launch 1,000 servers   │
│                           in 5 minutes          │
│                                                  │
│  🌍 Global reach       → Deploy in 30 regions   │
│                           worldwide instantly   │
│                                                  │
│  🛡️ Managed security   → AWS secures the         │
│                           physical layer        │
│                                                  │
│  🔄 No hardware waste  → Scale down when idle    │
└─────────────────────────────────────────────────┘
```

## 3. Story-Based Analogy — The City of AWS

Think of AWS like a **modern city** built for digital businesses:

```
🏙️ AWS = A City

🌍 Regions        = Different cities worldwide (New York, London, Tokyo)
                    Each city is independent — a power outage in NY
                    doesn't affect London

🏢 Availability   = Neighborhoods in a city
   Zones            Each neighborhood has its own power grid
                    If one neighborhood floods, others still work

🏭 Data Centers   = The actual buildings in each neighborhood

🛣️ AWS Network    = The highways connecting everything
                    Fiber-optic, low-latency, private roads

🏪 AWS Services   = Specialized shops in the city
                    S3 = warehouse,  EC2 = factory,  RDS = bank vault

⚡ Your App       = A business renting space in the city
                    You focus on your business, the city handles
                    electricity, water, roads, and security
```

## 4. Cloud Service Models

```
┌──────────────────────────────────────────────────────┐
│                                                       │
│  SaaS (Software as a Service)                        │
│  ┌──────────────────────────────────────┐            │
│  │ Gmail, Salesforce, Slack             │            │
│  │ You use the software — that's it     │            │
│  └──────────────────────────────────────┘            │
│                 ↓ more control                        │
│  PaaS (Platform as a Service)                        │
│  ┌──────────────────────────────────────┐            │
│  │ Elastic Beanstalk, Heroku, RDS        │            │
│  │ You write code + data — AWS runs it  │            │
│  └──────────────────────────────────────┘            │
│                 ↓ more control                        │
│  IaaS (Infrastructure as a Service)                  │
│  ┌──────────────────────────────────────┐            │
│  │ EC2, VPC, EBS                        │            │
│  │ You manage OS, runtime, app, data   │            │
│  └──────────────────────────────────────┘            │
│                                                       │
└──────────────────────────────────────────────────────┘

      SaaS ←──── Most Managed ────── IaaS ──→ Least Managed
                         ↕
                    More Control
```

| You Manage | SaaS | PaaS | IaaS | On-Prem |
|------------|------|------|------|---------|
| Application | ❌ | ✅ | ✅ | ✅ |
| Runtime | ❌ | ❌ | ✅ | ✅ |
| OS | ❌ | ❌ | ✅ | ✅ |
| Virtualization | ❌ | ❌ | ❌ | ✅ |
| Hardware | ❌ | ❌ | ❌ | ✅ |

## 5. AWS Global Infrastructure

### Regions

A **Region** is a physical location in the world where AWS has clustered data centers.

```
🌍 AWS Regions (selected):

United States:
  us-east-1     (N. Virginia)  ← Oldest, cheapest, most services
  us-east-2     (Ohio)
  us-west-1     (N. California)
  us-west-2     (Oregon)

Europe:
  eu-west-1     (Ireland)
  eu-central-1  (Frankfurt)
  eu-west-3     (Paris)

Asia Pacific:
  ap-southeast-1 (Singapore)
  ap-northeast-1 (Tokyo)
  ap-south-1     (Mumbai)

Others:
  sa-east-1     (São Paulo)
  me-south-1    (Bahrain)
  af-south-1    (Cape Town)
```

**How to choose a region:**

```
1. Latency       → Where are your users? Pick closest.
2. Data Laws      → GDPR? Use eu-west-1. India data? Use ap-south-1.
3. Services       → Not all services in all regions. Check availability.
4. Cost           → us-east-1 is typically cheapest.
```

### Availability Zones (AZs)

Each Region has **3–6 Availability Zones**. Each AZ is one or more data centers with:
- Separate power supply
- Separate cooling
- Separate network
- Connected to other AZs via private, high-speed fiber

```
Region: us-east-1 (N. Virginia)
┌─────────────────────────────────────────────┐
│                                             │
│  AZ: us-east-1a        AZ: us-east-1b       │
│  ┌─────────────────┐   ┌─────────────────┐  │
│  │ Data Centers A  │   │ Data Centers B  │  │
│  │  • Power Grid 1 │   │  • Power Grid 2 │  │
│  │  • Network 1    │   │  • Network 2    │  │
│  └────────┬────────┘   └────────┬────────┘  │
│           │  Low-latency fiber  │            │
│           └────────┬────────────┘            │
│                    │                         │
│           AZ: us-east-1c                    │
│           ┌─────────────────┐               │
│           │ Data Centers C  │               │
│           │  • Power Grid 3 │               │
│           └─────────────────┘               │
└─────────────────────────────────────────────┘

Why multiple AZs?
→ If AZ-1a has a power failure, AZ-1b and AZ-1c still serve traffic
→ High Availability requires spreading across AZs
```

### Edge Locations

```
Edge Locations = AWS outposts in 400+ cities globally

Purpose: Cache content CLOSE to users (CDN)

Without Edge Location:
  User in Chennai → Requests image → Server in us-east-1 (Virginia)
  Latency: ~200ms (ocean cables)

With CloudFront + Edge Location:
  User in Chennai → Requests image → Edge Location in Chennai
  Latency: ~5ms (same city)
```

## 6. High Availability vs Fault Tolerance vs Disaster Recovery

```
High Availability (HA):
  System is UP and accessible even when components fail.
  Achieved by: Multi-AZ deployment, load balancing, auto scaling
  Example: ALB routes to 3 instances across 3 AZs.
            One AZ fails → traffic goes to other 2. Brief disruption only.

Fault Tolerance:
  System continues operating with ZERO disruption even when components fail.
  More expensive than HA — requires redundant active systems.
  Example: Active-Active Multi-AZ RDS, where both nodes serve traffic.

Disaster Recovery (DR):
  Recovering from a catastrophic event (entire region failure).
  Strategies:
    Backup & Restore     → Cheapest, slowest (RTO hours)
    Pilot Light          → Minimal replica running, scale when needed (RTO 10 min)
    Warm Standby         → Scaled-down version running (RTO minutes)
    Multi-Site Active    → Full capacity in 2 regions (RTO seconds, most expensive)
```

## 7. Shared Responsibility Model

AWS and you split security responsibilities. Understanding this is critical.

```
┌─────────────────────────────────────────────────────────────┐
│                   WHAT YOU SECURE                           │
│                                                             │
│   • Your application code                                  │
│   • Your data (encrypted? backed up?)                      │
│   • IAM users, roles, and permissions                      │
│   • OS patches (on EC2)                                    │
│   • Network config (security groups, NACLs)                │
│   • Client-side data encryption                            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                   WHAT AWS SECURES                          │
│                                                             │
│   • Physical data center access                            │
│   • Hardware (servers, networking, storage)                 │
│   • Hypervisor (virtualization layer)                      │
│   • Global infrastructure                                  │
│   • Managed service software (RDS database engine, etc.)  │
│   • AWS network infrastructure                             │
└─────────────────────────────────────────────────────────────┘
```

**The rule of thumb:** As you move from IaaS → PaaS → SaaS, you own less and AWS owns more.

| | EC2 (IaaS) | RDS (PaaS) | Lambda (FaaS) | S3 |
|--|------------|------------|---------------|-----|
| OS patches | You | AWS | AWS | AWS |
| Runtime | You | AWS | AWS | AWS |
| App code | You | You | You | N/A |
| Data | You | You | You | You |
| Access control | You | You | You | You |

## 8. AWS Pricing Models

```
🏪 Analogy: Renting vs Buying a Car

On-Demand  = Taxi (pay per ride)
             Most expensive per hour, no commitment
             Best: dev/test, unpredictable load

Reserved   = Annual lease (commit 1–3 years, pay upfront)
             Up to 72% cheaper than On-Demand
             Best: steady-state production workloads

Spot       = Standby car (70–90% off, can be taken away anytime)
             AWS gives you 2-min warning before interruption
             Best: batch jobs, ML training, stateless workers

Savings Plans = Flexible subscription ($X/hour commitment)
             Works across instance families and regions
             Best: mix of instance types with cost commitment
```

### AWS Free Tier

```
Always Free:
  Lambda    → 1M invocations + 400K GB-seconds/month
  DynamoDB  → 25 GB storage + 25 WCU + 25 RCU
  CloudWatch → 10 custom metrics, 10 alarms

12-Month Free (new accounts):
  EC2    → 750 hrs/month t2.micro
  S3     → 5 GB storage + 20K GET + 2K PUT
  RDS    → 750 hrs/month db.t2.micro
  CloudFront → 1 TB data transfer + 10M requests
```

## 9. Trade-offs and Limitations

| Advantage | Trade-off |
|-----------|-----------|
| Instant scalability | Vendor lock-in risk |
| Global reach | Data sovereignty concerns in some regions |
| Managed services reduce ops burden | Less control over underlying infrastructure |
| Pay-as-you-go | Costs can explode without monitoring/alerts |
| Hundreds of services | Complexity — easy to over-architect |

## 10. Common Mistakes Engineers Make

```
❌ Deploying everything in ONE AZ
   → Single point of failure. Use Multi-AZ for all production workloads.

❌ Using the root account for daily operations
   → Root has unlimited power. Lock it down. Create IAM users/roles.

❌ Choosing a region without checking latency or data residency laws
   → Test latency from your users' location. GDPR requires EU data stay in EU.

❌ Ignoring the free tier limits
   → Free tier expires after 12 months for most services. Set billing alerts.

❌ Building without understanding the shared responsibility model
   → "AWS is secure" ≠ "My application is secure". You own your data and access.
```

## 11. Interview Perspective

**Q: What is the difference between a Region and an Availability Zone?**
A Region is a geographic area (e.g., us-east-1 = N. Virginia). An AZ is a physically isolated data center cluster within a region (e.g., us-east-1a). Each region has 3–6 AZs. AZs are connected with low-latency private fiber. You use multiple AZs for high availability within a region.

**Q: What is the Shared Responsibility Model?**
AWS secures the infrastructure (hardware, global network, hypervisor, physical access). You secure what runs on the infrastructure: your code, data, OS patches, IAM permissions, security group rules, and encryption. The boundary shifts based on service type — more managed services = AWS owns more.

**Q: What happens to your app if an entire AWS Region goes down?**
Single-region apps go down. Multi-region architectures (Route 53 health checks + failover, or active-active with latency routing) continue serving traffic. This is disaster recovery — requires a separate strategy from High Availability (which is AZ-level only).

## 12. Mini Exercise

```
1. Go to https://cloudpingtest.com and find the AWS region
   with lowest latency to your location.

2. Log into the AWS console. Go to:
   EC2 → Select different regions from the top-right dropdown.
   Notice which services are available in each region.

3. Use the AWS Pricing Calculator:
   https://calculator.aws/
   Estimate the cost of: 1x t3.small EC2 running 24/7 for 1 month.
   Compare On-Demand vs Reserved 1-year pricing.
```

**Back to root** → [../README.md](../README.md)
