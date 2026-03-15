# Stage 99 — Scenario & Architecture Interview Questions

> Real interview questions asked at Amazon, Google, Stripe, Airbnb, and top-tier startups. These are not trivia — they test whether you can *think* like a senior AWS architect.

---

## How to Use This Guide

Each question follows the format a senior interviewer actually uses:
1. **The Scenario** — a real business situation
2. **What They're Testing** — the hidden skill being evaluated
3. **Strong Answer** — the answer that gets you hired

> Tip: In real interviews, always clarify requirements before designing. "What is the expected RPS? What are the RTO/RPO requirements? Is cost a constraint?"

---

## Section 1 — System Design Scenarios

---

### Scenario 1: Design a URL Shortener (bit.ly)

**The question:** Design a URL shortening service like bit.ly. It should handle 100 million URLs shortened per day and 10 billion redirects per day. Redirects must be under 10ms.

**What they're testing:** S3 vs DynamoDB decisions, CDN thinking, caching strategy, global scale.

```
Strong Answer:

Requirements clarification:
  - 100M writes/day ≈ 1,150 writes/sec
  - 10B reads/day ≈ 115,000 reads/sec
  - Read:Write ratio = 100:1 → optimize for reads
  - 10ms redirect → cache everything possible

Architecture:

  User → Route 53 → CloudFront (edge cache)
                  → ALB → Lambda (redirect handler)
                         → DynamoDB (short_code → long_url)

Short code generation:
  - NanoID or base62 encoding of a counter
  - DynamoDB: partition_key=short_code, long_url, created_at, ttl
  - Lambda creates record + returns short URL

Redirect path (hot path, must be <10ms):
  - CloudFront caches most popular short codes at edge (TTL: 1 hour)
  - Cache hit: 1-2ms at nearest edge location (no backend call)
  - Cache miss: Lambda → DynamoDB → return 301 redirect + cache

Analytics (async, decoupled):
  - Lambda publishes click event to Kinesis Data Streams
  - Kinesis Firehose → S3 → Athena for analytics queries
  - No impact on redirect latency

Scale:
  - DynamoDB on-demand: handles 115K reads/sec automatically
  - CloudFront: 99%+ of traffic never hits DynamoDB (cache hit)
  - Multi-region: Route 53 latency routing to nearest region

Cost optimization:
  - Lambda@Edge for redirect (runs at CloudFront edge)
  - Eliminates round-trip to origin for uncached URLs
```

---

### Scenario 2: Real-Time Ride-Sharing Location Tracking

**The question:** Design the backend for a ride-sharing app (like Uber). Drivers update their GPS location every 3 seconds. Riders need to see their driver's location in real time. 500,000 active drivers.

**What they're testing:** WebSocket vs polling, real-time messaging, geospatial queries, DynamoDB design.

```
Strong Answer:

Problem breakdown:
  - 500K drivers × 1 update/3s = 167K writes/sec
  - Need: low-latency reads (riders polling driver location)
  - Need: geospatial queries (find nearest drivers)
  - Need: real-time push to rider (not polling)

Architecture:

  Driver App → API Gateway WebSocket → Lambda (location update)
                                     → DynamoDB (driver_id, lat, lng, timestamp)
                                     → ElastiCache Redis (geospatial index)

  Rider App ← API Gateway WebSocket ← Lambda (push to rider connection)
                                    ← EventBridge (driver_moved event)

Driver location storage:
  DynamoDB:
    PK: driver_id
    SK: timestamp
    Attrs: lat, lng, status (available/in-trip/offline)
    TTL: 5 minutes (auto-delete old locations)

  Redis GEOADD:
    GEOADD drivers_available lng lat driver_id
    GEORADIUS drivers_available lon lat 5 km → find nearby drivers
    Updates every 3 seconds → fresh geospatial index

Real-time push to rider:
  1. Driver Lambda updates DynamoDB + Redis
  2. DynamoDB Stream triggers EventBridge
  3. EventBridge rule: if driver matches active trip → push to rider connection
  4. API Gateway WebSocket: postToConnection(rider_connection_id, location)

Why not polling?
  - Polling 167K drivers every 3s from 500K riders = billions of requests
  - WebSocket: persistent connection, server pushes only when location changes
  - 10x fewer API calls
```

---

### Scenario 3: Multi-Tenant SaaS File Storage

**The question:** Build a multi-tenant file storage system where each customer (tenant) can upload files, share files with team members, and set permissions. Tenants must be strictly isolated — tenant A cannot access tenant B's data.

**What they're testing:** S3 security, IAM resource policies, multi-tenancy patterns, presigned URLs.

```
Strong Answer:

Tenant isolation strategy: S3 prefix isolation + IAM conditions

S3 structure:
  s3://company-files/tenant-{tenant_id}/files/
  s3://company-files/tenant-{tenant_id}/shared/

IAM policy (per-tenant role):
  {
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
    "Resource": "arn:aws:s3:::company-files/tenant-${aws:PrincipalTag/TenantId}/*",
    "Condition": {
      "StringEquals": {"s3:prefix": ["tenant-${aws:PrincipalTag/TenantId}/"]}
    }
  }

Upload flow (never expose long-lived credentials):
  1. User requests upload URL from API Gateway
  2. Lambda generates presigned URL (S3.generate_presigned_url)
     - URL valid for 15 minutes
     - URL scoped to tenant-{id}/files/{filename}
  3. Browser uploads directly to S3 (no Lambda in upload path)
  4. S3 Event Notification → SQS → Lambda (virus scan, thumbnail)
  5. Lambda updates DynamoDB metadata table

File sharing:
  DynamoDB: {file_id, owner_tenant, shared_with: [{tenant_id, permission}]}
  On share: Lambda generates time-limited presigned URL for shared tenant
  Permission model enforced by application layer, not IAM (simpler for fine-grained)

Encryption:
  S3 SSE-KMS: separate KMS key per tenant
  Key ARN stored in tenant config table
  Even if isolation fails → another tenant's data is still KMS-encrypted with different key
```

---

### Scenario 4: E-Commerce Flash Sale (10x Traffic Spike)

**The question:** Your e-commerce site normally handles 1,000 requests/sec. You're launching a flash sale in 1 hour that will spike to 50,000 requests/sec for 30 minutes. How do you prepare?

**What they're testing:** Auto Scaling configuration, database bottlenecks, caching, queue-based load leveling.

```
Strong Answer:

Problem: 50x traffic spike, 1-hour warning

Immediate actions (pre-sale):

1. Warm up Auto Scaling:
   - Set ASG minimum instances to handle expected peak now
   - Don't rely on auto-scale to react fast enough (takes 3-5 min to launch EC2)
   - Pre-warm to 80% of expected capacity

2. Cache product/pricing data:
   - Product catalog doesn't change during sale → cache in ElastiCache Redis
   - Cache TTL: 5 minutes
   - 90% of requests are reads → cache eliminates 90% of DB load

3. Decouple order processing:
   - Orders go to SQS queue, not directly to DB
   - SQS acts as buffer: accepts 50K/sec even if backend processes 10K/sec
   - Prevents DB from being overwhelmed
   - User gets immediate "Order Received" response
   - Order processing Lambda reads from SQS and inserts to RDS

4. RDS read replicas:
   - Scale to 5 read replicas before sale
   - All product/inventory reads → replicas
   - Only order writes → primary

5. CloudFront + WAF:
   - Static assets (images, JS) served from CloudFront edge
   - WAF rate limiting: block IPs requesting > 100/sec (bot protection)

6. Alarms (not just monitoring, but action):
   - CloudWatch alarm: CPU > 80% → SNS → on-call page
   - Set up predictive scaling (if available) or scheduled scaling

Architecture during sale:
  Users → CloudFront → ALB → EC2 ASG (pre-warmed)
                            → ElastiCache (reads)
                            → SQS (order writes) → Lambda → RDS
```

---

### Scenario 5: GDPR Compliance — User Data Deletion

**The question:** You have user data spread across RDS, DynamoDB, S3, and CloudWatch logs. A European user requests deletion of all their data under GDPR's "right to erasure." How do you design this?

**What they're testing:** Data governance, audit trails, distributed deletion, compliance architecture.

```
Strong Answer:

Challenges:
  - Data is spread across multiple services
  - CloudWatch logs → immutable (can't delete individual log entries)
  - Backups also contain PII
  - Must prove deletion to auditors

Architecture: Centralized Data Registry

1. All PII storage is tagged and registered:
   DynamoDB table: data_registry
     {user_id, service: "rds", table: "users", pk: user_id}
     {user_id, service: "s3", bucket: "uploads", prefix: "users/{id}/"}
     {user_id, service: "dynamo", table: "orders", pk: user_id}

2. Deletion request flow:
   API → Lambda → SQS (deletion_requests queue)
              → DynamoDB (mark user as deletion_pending)

   DeletionProcessor Lambda (reads from SQS):
     - RDS: DELETE FROM users WHERE user_id = ?
     - DynamoDB: delete all items with user_id partition key
     - S3: batch delete all objects in users/{id}/ prefix
     - Cognito: AdminDeleteUser
     - data_registry: mark all entries deleted + timestamp

3. CloudWatch logs (cannot delete entries):
   Solution: pseudonymization at write time
   - Never log user PII — log user_id hash only
   - user_id → hashed_id mapping stored in separate table
   - On deletion: delete the mapping table entry
   - Log entries become orphaned (no PII exposure)

4. Backups:
   - Automated RDS backups contain PII → expire after retention period
   - For regulatory compliance: document that backups will expire within X days
   - Consider: encrypt backups with customer-managed key → delete key = delete data

5. Audit trail:
   - All deletion actions logged to immutable CloudTrail
   - Step Functions state machine handles multi-step deletion
   - Final step: generate signed PDF certificate of deletion
   - Store certificate in S3 (not PII, just proof)
```

---

### Scenario 6: Design a Notification System

**The question:** Design a notification system that sends push notifications, emails, and SMS. Users can configure which channels they want. 10 million users, expected 5 million notifications/day.

**What they're testing:** SNS, SES, multi-channel fan-out, idempotency, dead letter handling.

```
Strong Answer:

Core pattern: Fan-out with per-channel routing

Architecture:
  Event Producer → EventBridge → NotificationRouter Lambda
                               → SNS Topic: per notification type
                               → SQS queues: per channel (email, SMS, push)
                               → Channel Worker Lambdas

Notification flow:
  1. order_placed event → EventBridge
  2. NotificationRouter Lambda:
     - Look up user preferences from DynamoDB
       {user_id, channels: ["email", "push"], email_addr, push_token, phone}
     - If user wants email: send to SQS email queue
     - If user wants push: send to SQS push queue
     - If user wants SMS: send to SQS sms queue

  3. Channel Workers:
     - EmailWorker Lambda → SES (10M emails/day → SES handles this)
     - PushWorker Lambda → SNS Mobile Push (FCM/APNS)
     - SMSWorker Lambda → SNS SMS or Pinpoint (for bulk SMS)

Idempotency (prevent duplicate notifications):
  - Each notification has a unique notification_id
  - DynamoDB: check if notification_id already processed before sending
  - SQS FIFO queue for SMS (must not send twice)

Dead letter handling:
  - Each SQS queue has a DLQ
  - Failed notifications → DLQ → CloudWatch alarm → manual review
  - Retry policy: 3 retries with exponential backoff

User preferences (hot path):
  - ElastiCache Redis: cache user preferences (TTL: 1 hour)
  - Saves DynamoDB lookup on every notification
  - On preference update: invalidate cache

Rate limiting per user:
  - Redis counter: "notifications:{user_id}:{hour}" incr + expire
  - Max 10 notifications/hour per user → SQS delay message by 1 hour
```

---

## Section 2 — Architecture Trade-off Questions

---

### Scenario 7: SQS vs Kinesis — When to Use Which?

**The question:** You're designing a clickstream analytics pipeline that processes user events. Should you use SQS or Kinesis Data Streams?

**What they're testing:** Messaging pattern recognition, ordering guarantees, replay capability.

```
Strong Answer: Kinesis for this use case.

Decision matrix:

                    SQS                     Kinesis
Ordering:           Per-queue (FIFO optional) Per-shard (strict order)
Replay:             ❌ Consumed = gone        ✅ Replay up to 365 days
Multiple consumers: ❌ One consumer wins      ✅ Many consumers, same data
Throughput/shard:   ~3000 msg/s              1MB/s or 1000 records/s
Retention:          14 days max              1-365 days
Message size:       256 KB                   1 MB
Use case:           Task queue, decoupling   Event streaming, analytics

For clickstream analytics:
  ✅ Kinesis: multiple consumers (real-time ML, Firehose → S3, CloudWatch)
  ✅ Kinesis: replay capability (reprocess if analytics job has a bug)
  ✅ Kinesis: ordered per user (partition key = user_id)

  ❌ SQS would mean: each event consumed once, no replay, multiple
     consumers would compete for the same messages

Use SQS when:
  - Simple task queue (process once and forget)
  - Variable message rates (SQS auto-scales, no shard management)
  - Long message retention not needed
  - Worker pool pattern (compete to process jobs)
```

---

### Scenario 8: RDS vs DynamoDB — The Database Choice

**The question:** You're building a social media feed. Each user has posts, followers, and a feed. What database would you use and why?

**What they're testing:** Data modeling, access pattern analysis, scalability thinking.

```
Strong Answer: DynamoDB for feed + RDS for user profile/auth.

Why DynamoDB for feed:

Access patterns to model:
  1. Get user's feed (most recent 50 posts)
  2. Get all posts by a user
  3. Get post + its comments
  4. Fan-out: when user posts, update 10,000 followers' feeds

DynamoDB table design:
  PK           | SK               | Data
  USER#alice   | PROFILE          | {name, bio, follower_count}
  USER#alice   | POST#2024-01-15  | {content, likes, media_url}
  FEED#bob     | 2024-01-15#alice | {alice's post content, fan-out copy}

  Query feed for bob: PK=FEED#bob, ScanIndexForward=False, Limit=50
  Query alice's posts: PK=USER#alice, SK begins_with POST#, Limit=50

Why not RDS for feed?
  - Feed is a write-heavy fan-out: 1 post → update 10K followers' feeds
  - RDS: 10K UPDATE statements per post × many posts/second = DB overload
  - DynamoDB: handles millions of writes/second with auto-scaling

Why RDS for user authentication:
  - Login, MFA, account recovery = complex transactions
  - JOINs needed: user → roles → permissions
  - Strong consistency required (you can't be "sort of logged in")
  - Volume is low (login happens once per session, not per page view)

Combined architecture:
  RDS (PostgreSQL):   user_accounts, auth_tokens, billing
  DynamoDB:           posts, feeds, comments, likes, follows
  ElastiCache Redis:  hot feeds (viral posts), session tokens
```

---

### Scenario 9: Microservices Communication — Sync vs Async

**The question:** You have an order service that needs to: (1) check inventory, (2) process payment, (3) send confirmation email, (4) update analytics. Which calls should be synchronous and which asynchronous?

**What they're testing:** Event-driven design principles, failure isolation, latency sensitivity.

```
Strong Answer:

Rule: Synchronous = user is waiting. Async = fire and forget.

Step-by-step classification:

1. Check inventory — SYNCHRONOUS
   - User is waiting to know if item is in stock
   - If inventory check fails → do NOT proceed to payment
   - Order service directly calls inventory service via REST/gRPC
   - If inventory service is down → return error to user immediately
   - Latency: must be < 200ms

2. Process payment — SYNCHRONOUS
   - User must know immediately if payment succeeded or failed
   - If payment fails → cancel order, don't ship anything
   - Direct call to payment service (Stripe API)
   - Idempotency key to prevent double-charging on retry

3. Send confirmation email — ASYNCHRONOUS
   - User doesn't need to wait for the email to appear
   - Publish OrderConfirmed event to SQS / EventBridge
   - EmailService Lambda consumes event → calls SES
   - If email fails → retry from DLQ, doesn't affect order completion
   - Latency: 30 seconds delay is acceptable

4. Update analytics — ASYNCHRONOUS
   - Analytics is not user-facing
   - Publish OrderPlaced event to Kinesis Data Streams
   - Analytics consumers (Flink, Firehose) process in batch
   - Order service doesn't wait for this at all

Architecture:

  User → OrderService → [SYNC] InventoryService → [SYNC] PaymentService
                      ↓ (on success)
                      EventBridge: OrderCompleted
                      ├── [ASYNC] SQS → EmailService → SES
                      └── [ASYNC] Kinesis → Analytics Pipeline

Result:
  - User response time: inventory + payment only (~300ms)
  - Email and analytics don't add to latency
  - Email failure doesn't break order flow
  - Full audit trail via EventBridge
```

---

### Scenario 10: Auto Scaling Doesn't Help — Finding Real Bottlenecks

**The question:** Your team added more EC2 instances behind the ALB but response times are still slow. What's your debugging approach?

**What they're testing:** Systematic debugging, understanding that scaling isn't always the answer, X-Ray usage.

```
Strong Answer:

Step 1: Verify EC2 is actually the bottleneck
  - CloudWatch: check CPU, memory, network on EC2 instances
  - If CPU is 20% → EC2 is NOT the bottleneck → adding more won't help

Step 2: Use X-Ray to trace the request
  - X-Ray service map: visualize where time is spent
  - Typical findings:
    - EC2 (50ms) → RDS (1,800ms) ← bottleneck is here
    - EC2 (50ms) → External API (2,000ms) ← external dependency

Step 3: Common actual bottlenecks:
  a) Database (most common)
     RDS CPU high → read replicas + query optimization + read caching
     RDS connections exhausted → RDS Proxy (connection pooling)
     Slow queries → CloudWatch RDS slow query log + add indexes

  b) External API
     Third-party service is slow → cache responses (ElastiCache)
     → async pattern (don't call in request path, pre-fetch)

  c) Lambda cold starts (if serverless)
     P99 latency spikes → provisioned concurrency for critical Lambdas

  d) ALB → EC2 network
     Large payloads → compress + use CloudFront

  e) In-process bottleneck
     Single-threaded CPU-bound code → refactor or use compute-optimized instance

Step 4: Prioritize by impact:
  - Query returning 10MB of data that you only need 100 bytes of?
    → Fix the query (SELECT specific columns, add WHERE clause)
  - Calling the same DB query 50 times per request?
    → N+1 query problem → fix with JOIN or batch query

Summary: Scale horizontally only when the bottleneck IS the application tier.
         Otherwise you're paying more for the same slow experience.
```

---

## Section 3 — Security Scenarios

---

### Scenario 11: Credentials Leaked to GitHub

**The question:** A developer accidentally committed an AWS access key to a public GitHub repository 10 minutes ago. What do you do right now?

**What they're testing:** Incident response, blast radius assessment, remediation speed.

```
Strong Answer (incident response — ordered by priority):

IMMEDIATE (next 5 minutes):
  1. Revoke the access key NOW:
     aws iam delete-access-key --access-key-id AKIAEXAMPLE123
     (Even if key is 10 minutes old — bots scan GitHub in <30 seconds)

  2. Check what the key did:
     CloudTrail → filter by access_key_id → last 30 minutes
     Look for: CreateUser, RunInstances, CreateBucket, AssumeRole
     → These indicate compromise/misuse

  3. Check GuardDuty:
     Look for: UnauthorizedAccess findings related to the key
     Any findings → escalate to security team immediately

SHORT TERM (next 30 minutes):
  4. Audit active resources for anomalies:
     EC2 console → any running instances you don't recognize?
     IAM → any new users, roles, or permissions you didn't create?
     S3 → any new buckets or public access enabled?
     Billing → Cost Explorer → spikes in last hour?

  5. Change the IAM user's password (if console access)
     Revoke all active sessions:
     aws iam update-login-profile + revoke all console sessions

  6. Rotate any secrets the compromised key could access:
     If key had Secrets Manager access → rotate all referenced secrets
     If key had KMS access → assess exposed encrypted data

REMEDIATION:
  7. Delete the compromised key permanently (already done in step 1)
  8. Create new key for developer using proper secret storage
     → Store in AWS Secrets Manager, not env file committed to git
  9. Add git-secrets or Gitleaks to CI pipeline to prevent future leaks
  10. Post-mortem: how did a key end up in code? → Fix the root cause

NEVER: Don't try to "hide" the incident. GitHub caches are permanent.
       Assume the key was compromised the moment it was pushed.
```

---

### Scenario 12: Design Zero-Trust Security for a Multi-Account AWS Org

**The question:** You're setting up AWS for a 200-person company with dev/staging/production environments. Design the account structure and security controls.

**What they're testing:** AWS Organizations, SCPs, multi-account strategy, least privilege at scale.

```
Strong Answer:

Account structure (AWS Organizations):

  Root (management account — billing only)
  ├── Security OU
  │   ├── Security Tooling account (GuardDuty master, Security Hub)
  │   └── Log Archive account (immutable CloudTrail, Config logs)
  ├── Production OU
  │   ├── prod-core account (shared services: VPC, DNS, Transit Gateway)
  │   ├── prod-payments account (PCI-DSS isolated)
  │   └── prod-app-team-X account (per team isolation)
  ├── Non-Production OU
  │   ├── staging account
  │   └── dev account (per developer sandbox allowed)
  └── Sandbox OU
      └── experiment accounts (SCPs prevent production-like resources)

Service Control Policies (SCPs) — guardrails:
  Applied at OU level, can't be overridden by account admins:

  All accounts SCP:
    - Deny: leaving AWS Organizations
    - Deny: disabling CloudTrail
    - Deny: disabling GuardDuty
    - Deny: creating IAM users with long-term credentials (except break-glass)
    - Deny: creating resources outside approved regions (us-east-1, eu-west-1)

  Production OU SCP (additional):
    - Deny: ec2:TerminateInstances without MFA condition
    - Deny: s3:DeleteBucket
    - Deny: any action from non-corporate IP range

  Sandbox OU SCP:
    - Deny: r5.16xlarge and above (cost control)
    - Deny: Reserved Instance purchases

IAM strategy:
  - No long-term IAM user keys in any account
  - Developers: SSO via AWS IAM Identity Center → assume role in target account
  - Applications: IAM roles with IRSA (EKS) or task roles (ECS)
  - Break-glass: 1 emergency IAM user in each account, credentials in sealed vault

Network isolation:
  - Each account has its own VPC
  - Transit Gateway in prod-core account: connects approved VPCs
  - Private Link: access shared services without exposing to internet
  - No VPC peering between prod and dev (isolation)
```

---

## Section 4 — Data & Analytics Scenarios

---

### Scenario 13: Real-Time Fraud Detection Pipeline

**The question:** Design a system that detects fraudulent transactions in real-time. Transactions come in at 50,000/second. A fraud decision must be made within 500ms.

**What they're testing:** Streaming architecture, ML integration, latency requirements.

```
Strong Answer:

Constraint: 500ms end-to-end, 50K TPS

Pipeline:

  Transaction API → Kinesis Data Streams (50 shards, 1MB/s per shard)
                  ↓
  Kinesis Analytics (Managed Flink):
    - Enrich: join with customer profile stream
    - Feature engineering: rolling aggregations per user
      - tx_count_last_5min per user
      - tx_amount_sum_last_hour per user
      - velocity: country changes in 10 minutes
      - unusual_merchant_category flag
    - Send enriched features to SageMaker endpoint

  SageMaker Endpoint (real-time inference):
    - XGBoost fraud model
    - Input: 20 features (velocity, amount, merchant, geo, device)
    - Output: fraud_probability (0.0 - 1.0)
    - Response: <50ms (model is pre-loaded, no cold start)

  Decision Lambda:
    - fraud_prob > 0.9 → BLOCK immediately (return error to payment)
    - fraud_prob 0.6-0.9 → FLAG for human review + allow
    - fraud_prob < 0.6 → ALLOW

  Results → DynamoDB (transaction decision + reason)
           → Kinesis Firehose → S3 (for model retraining)
           → SNS → fraud analyst team (high-confidence detections)

Total latency budget:
  Kinesis ingestion: 5ms
  Flink enrichment + aggregation: 50ms
  SageMaker inference: 50ms
  Decision + DynamoDB write: 20ms
  Total: ~125ms ✅ well under 500ms

Model retraining (daily):
  S3 labeled data → SageMaker Training Job → new model artifact
  → SageMaker A/B test: 10% traffic to new model
  → Monitor: precision/recall on holdout set
  → Promote if better → swap endpoint model (zero downtime)
```

---

### Scenario 14: Data Lake Migration from On-Premises Hadoop

**The question:** Your company has 5 petabytes of data on an on-premises Hadoop cluster. You need to migrate to AWS and keep costs under control. How do you approach this?

**What they're testing:** Data migration strategy, S3 as data lake, cost optimization, service selection.

```
Strong Answer:

Phase 1: Assessment (week 1-2)
  - Catalog all datasets: size, access frequency, data owners, retention
  - Tag: hot (daily access), warm (weekly), cold (monthly+), archive
  - Identify: which jobs are still running vs which are dormant

Phase 2: Foundation (week 3-4)
  - S3 data lake structure:
    s3://data-lake/raw/       (untransformed source data)
    s3://data-lake/processed/ (Glue/EMR output)
    s3://data-lake/curated/   (analytics-ready)
  - AWS Lake Formation: set up governance before data arrives
  - Glue Data Catalog: will auto-catalog data as it lands
  - S3 Intelligent-Tiering: auto-move infrequently accessed data to cheaper tier

Phase 3: Migration (phased)
  Tool: AWS DataSync (on-premises HDFS → S3, encrypted in transit)
  Alternative: Snowball Edge (if bandwidth is limited, ship 80TB device)

  Order: cold → warm → hot (migrate least risky first, validate, then hot)

  Parallel validation:
    - Run same query against on-prem Hadoop AND AWS Athena
    - Compare row counts, checksums, sample data
    - Sign-off from data owners before decommissioning on-prem

Phase 4: Query Layer
  - Ad-hoc SQL: Athena (no infrastructure, pay per TB scanned)
  - ETL/transforms: AWS Glue (replaces Hive ETL jobs)
  - Complex ML jobs: EMR Serverless (replaces Spark clusters)
  - Data warehouse workloads: Redshift (replaces Hive on YARN for BI)

Cost optimization:
  - Parquet + Snappy compression: 75% storage reduction vs raw JSON/CSV
  - Athena cost: $5/TB scanned → Parquet reduces scan → 10x cheaper queries
  - S3 Intelligent-Tiering: auto-move rarely-accessed data (saves 40-68%)
  - EMR Serverless: pay only when jobs run, not 24/7 cluster

Expected outcome:
  On-prem: ~$2M/year (hardware, power, ops team)
  AWS S3 + Athena + Glue: ~$400K/year for same 5PB
  80% cost reduction + no hardware refresh cycle
```

---

## Section 5 — Serverless & Event-Driven Scenarios

---

### Scenario 15: Lambda Cold Start Problem

**The question:** Your Lambda function processes financial transactions and must respond in under 100ms at P99. Users are complaining about intermittent 3-second response times. What's happening and how do you fix it?

**What they're testing:** Lambda internals, cold start mitigation, provisioned concurrency.

```
Strong Answer:

Root cause: Lambda cold starts

What's happening:
  Cold start = Lambda must:
    1. Provision a micro-VM (50-200ms)
    2. Download your function package (50-500ms depending on size)
    3. Start the runtime (Node/Python/Java)
    4. Run your initialization code (DB connections, imports)
  Total: 200ms - 3,000ms (Java is worst, Python is better)

When cold starts happen:
  - First invocation after a period of inactivity
  - Scaling up: each new concurrent instance = new cold start
  - After deployment (all instances recycled)

Fixes (in order of impact):

1. Provisioned Concurrency (best for P99 guarantees):
   aws lambda put-provisioned-concurrency-config \
     --function-name payment-processor \
     --qualifier prod \
     --provisioned-concurrent-executions 50

   → 50 instances pre-warmed, zero cold start latency
   → Cost: ~2x Lambda cost for those 50 instances
   → Right for: user-facing, latency-critical, predictable traffic

2. Reduce cold start duration:
   - Package size: minimize dependencies (no unused packages)
   - Python: lazy imports (import inside function if rarely used)
   - Move DB connection outside handler (reused across invocations)
   - Use Lambda Layers for shared dependencies (cached separately)

3. Use Lambda SnapStart (Java only):
   - Takes snapshot of initialized JVM state
   - Restores from snapshot instead of initializing from scratch
   - Java cold starts: 10s → 200ms

4. Keep lambdas warm (poor man's solution):
   - EventBridge rule: ping Lambda every 5 minutes
   - Keeps instances warm for moderate traffic
   - ❌ Not reliable — Lambda still scales out cold on spikes

For your 100ms P99 requirement:
  Provisioned Concurrency = 50 instances (baseline)
  + Reserved Concurrency = 200 instances (cap to prevent DB overload)
  + Lambda ARM (Graviton): 20% better price-performance
  + Connection pooling via RDS Proxy (reuse connections across invocations)
```

---

### Scenario 16: Step Functions vs SQS Chained Lambdas

**The question:** You need to build an order processing workflow: validate → charge payment → update inventory → send confirmation → notify shipping. Should you use Step Functions or chain Lambdas via SQS?

**What they're testing:** Orchestration vs choreography, observability, failure handling.

```
Strong Answer: Step Functions for this use case.

Orchestration (Step Functions) vs Choreography (SQS chain) comparison:

SQS chain (choreography):
  OrderLambda → SQS → PaymentLambda → SQS → InventoryLambda → ...

  Problems:
  - How do you see the current state of one order?
    You can't — it's scattered across 5 SQS queues
  - If PaymentLambda fails — what compensates? Who retries?
    Each Lambda must track state manually
  - If you add a new step — you must modify existing Lambdas
  - Debugging: trace an order across 5 SQS queues → nightmare

Step Functions (orchestration):
  State machine defines the entire workflow as code

  Order flow in ASL:
    ValidateOrder → ChargePayment → UpdateInventory → SendConfirmation → NotifyShipping

    Each step:
      - Automatic retry with exponential backoff (3 retries default)
      - Error catching: PaymentFailed → RefundCompensation → NotifyUser
      - Full execution history in console (see exactly where order is)
      - Execution timeout: order must complete in 5 minutes or auto-fail

  Benefits:
  ✅ Visual execution graph in console (which step failed, why)
  ✅ Built-in retry + error handling per step
  ✅ Human approval step: waitForTaskToken (fraud review)
  ✅ Parallel step: SendEmail + UpdateCRM simultaneously
  ✅ Full audit trail (every execution stored for 90 days)
  ✅ Easy to add steps without touching existing Lambdas

Use SQS chain when:
  - Simple 2-step pipelines
  - Each step is truly independent (no compensation needed)
  - High throughput (Step Functions: 5,000 state transitions/sec per account)
  - Cost is a concern (Step Functions: $0.025 per 1,000 state transitions)

For order processing with compensation logic: Step Functions wins clearly.
```

---

## Section 6 — Advanced Architecture Questions

---

### Scenario 17: Design for 99.99% Availability

**The question:** Your system currently has 99.5% availability (4 hours downtime/month). The business needs 99.99% (52 minutes downtime/year). How do you get there?

**What they're testing:** Availability math, redundancy patterns, failure domain thinking.

```
Strong Answer:

First, understand what 99.99% actually requires:
  99.5%   = 3.6 hours downtime/month
  99.9%   = 43 minutes downtime/month
  99.99%  = 4.3 minutes downtime/month
  99.999% = 26 seconds downtime/month

Gap analysis — find every single point of failure:

Layer 1: Compute
  Single EC2 → EC2 + ALB + ASG across 3 AZs
  Why 3 AZs? If one AZ has a fire, you still have 2 others (⅔ capacity)
  ASG health check: replace unhealthy instance in < 2 minutes

Layer 2: Database (usually the weakest link)
  Single RDS → RDS Multi-AZ (synchronous replica in different AZ)
  Failover time: 60-120 seconds → acceptable for 99.99%
  RDS Proxy: absorbs connection storms during failover
  Read traffic → read replicas → primary is protected

Layer 3: Network
  Single region → Cross-region active-passive failover
  Route 53 health checks: 30-second detection + 60-second DNS propagation
  Aurora Global Database: < 1 second replication lag to DR region

Layer 4: Dependencies
  External API goes down → circuit breaker (stop calling, use cached data)
  ElastiCache: if Redis fails → fallback to DynamoDB (slower but available)
  Design each dependency with a graceful degradation path

Monitoring for 99.99%:
  CloudWatch: alert in < 1 minute of degradation (not just after 5 min)
  Synthetic monitoring: Canary Lambda pings critical paths every minute
  PagerDuty: 24/7 on-call rotation, <5 min page-to-acknowledgment SLA

Chaos testing:
  Monthly FIS experiments: terminate random EC2, fail AZ, inject latency
  "If we can't break it in testing, we can't trust it in production"

Math check:
  Multi-AZ ALB + ASG: 99.99% (AWS SLA)
  RDS Multi-AZ: 99.95% (failover is 60-120s)
  Overall: ~99.95% single-region, ~99.99% multi-region active-passive
```

---

### Scenario 18: Cost Spike — Bill Went from $10K to $80K

**The question:** Your AWS bill jumped from $10,000 to $80,000 in one month. Walk me through exactly how you would investigate and fix this.

**What they're testing:** Cost Explorer proficiency, root cause analysis, cost governance.

```
Strong Answer:

Step 1: Scope the problem (Cost Explorer)
  - Group by: Service → which service spiked?
  - Group by: Region → any activity in unexpected region? (possible breach)
  - Group by: Tag → which team or project?
  - View: Daily costs → which day did it start?

Step 2: Common culprits by service

  EC2 spike ($50K increase):
    → Check: any new large instance types? (p3.16xlarge for ML?)
    → Check: auto-scaling runaway? (ASG max not set → scaled to 1000 instances)
    → Check: Spot Instance interruptions → fell back to On-Demand at 10x cost
    → Fix: set ASG max capacity, set billing alert ($1000/day)

  Data Transfer spike ($20K increase):
    → Usually: EC2 to internet egress ($0.09/GB), cross-AZ traffic ($0.01/GB)
    → Check: NAT Gateway data processed (log by VPC flow logs)
    → Check: CloudFront not caching (origin pull for every request)
    → Fix: VPC Endpoints (DynamoDB/S3 → free), S3 transfer acceleration

  S3 spike:
    → Check: PUT/GET request count (someone running 1M small file requests?)
    → Check: new Glacier restore requests (restore charges per GB)
    → Check: replication traffic (CRR at scale)

  RDS snapshot ($5K):
    → Check: automated backup retention set to 35 days (accumulates)
    → Check: manual snapshots never deleted (accumulate indefinitely)

Step 3: Immediate actions
  1. AWS Budgets: create $15,000/month budget with email alert at 80%
  2. Budget Actions: auto-stop non-critical EC2 if budget exceeded by 150%
  3. Cost Allocation Tags: every resource must have team= and env= tags
  4. Trusted Advisor: free tier → checks for underutilized resources

Step 4: Prevention governance
  - Require tags on all resources via AWS Config rule (auto-remediate)
  - SCPs: deny large instance types in dev/staging
  - Weekly cost review: FinOps meeting, each team sees their spend
  - Resource cleanup Lambda: terminate untagged resources after 7 days
```

---

### Scenario 19: Migrate a Monolith to Microservices

**The question:** You have a 5-year-old monolithic Rails app on a single EC2 instance. Downtime is unacceptable. How do you migrate to microservices on AWS without breaking production?

**What they're testing:** Strangler fig pattern, incremental migration, zero-downtime deployments.

```
Strong Answer: Strangler Fig Pattern

Core principle: Extract piece by piece. Never big-bang rewrite.

Phase 1: Wrap the monolith (week 1)
  - Put ALB in front of monolith
  - ALB routes all traffic to existing EC2 (no change, just add routing layer)
  - This is your "strangler" — ALB will gradually redirect paths to new services

Phase 2: Extract highest-value service first (weeks 2-4)
  - Pick: user authentication (touches every request, clear boundary)
  - Build: Cognito + Lambda + API Gateway for /auth/* endpoints
  - Test: in staging with real traffic copy
  - Deploy: ALB rule: path /auth/* → new auth service
  - Monolith still handles everything else

Phase 3: Strangle service by service
  For each extracted service:
  1. Build new service (Lambda/ECS) with its own database
  2. Data migration: dual-write (monolith writes to both old DB + new service)
  3. Shadow mode: new service runs in parallel, compare responses
  4. Canary: send 10% of traffic to new service, monitor error rates
  5. Full cutover: ALB routes 100% to new service
  6. Remove old code from monolith

Phase 4: Database decomposition (hardest part)
  - Monolith uses single RDS PostgreSQL with 80 tables
  - Extract: orders table → new orders service with its own RDS
  - Use DMS to replicate orders table to new DB in real-time during transition
  - After cutover: new service owns the table, monolith calls new service API

Rollback strategy (zero downtime requirement):
  - ALB weighted routing: 90% monolith / 10% new service
  - One click rollback: change weight to 100% monolith
  - Feature flags: disable new service path without deployment
  - Never delete old code for 30 days (just in case)

Timeline: 6-12 months for full migration of medium-sized monolith
          Don't rush — each extraction is a production change
```

---

### Scenario 20: Design a Serverless Multi-Region Active-Active API

**The question:** Design a REST API that serves global users with < 50ms latency anywhere in the world. The API must continue serving all requests even if an entire AWS region goes down.

**What they're testing:** Multi-region active-active, DynamoDB Global Tables, Route 53, conflict resolution.

```
Strong Answer:

Target: < 50ms globally, zero downtime on region failure

Architecture:

  Users (global) → Route 53 (latency routing) → CloudFront (edge cache)
                                               → API Gateway (us-east-1)
                                               → API Gateway (eu-west-1)
                                               → API Gateway (ap-northeast-1)

Per-region stack (identical in each region):
  API Gateway → Lambda → DynamoDB Global Table (local region replica)

Route 53 latency routing:
  - DNS resolves to nearest region based on network latency
  - US users → us-east-1 (10ms)
  - EU users → eu-west-1 (12ms)
  - Asia users → ap-northeast-1 (8ms)
  - Health checks: if region fails → remove from routing in < 30 seconds

DynamoDB Global Tables:
  - Single table replicated across all 3 regions
  - Writes go to local region → replicated to other regions in < 1 second
  - Conflict resolution: last-writer-wins (built-in)
  - On region failure: other regions have data < 1 second stale

Lambda:
  - Deployed identically to each region (CodePipeline multi-region deploy)
  - Each Lambda reads/writes only its local DynamoDB replica
  - No cross-region API calls in the hot path (would add 100ms+)

State management (the hard part):
  - Session tokens: store in DynamoDB Global Table (user_id → session)
  - All regions can validate any session
  - JWT: self-contained token → no session lookup needed (preferred)

Region failover (what actually happens):
  1. us-east-1 Lambda starts throwing 500s
  2. Route 53 health check fails after 30 seconds
  3. Route 53 removes us-east-1 from DNS within 60 seconds
  4. US users now route to us-west-2 (next lowest latency)
  5. DynamoDB Global Table: us-west-2 has all data
  6. No data loss, no manual action

Trade-offs of active-active:
  ✅ Zero downtime on region failure
  ✅ Low latency globally (read from nearest region)
  ⚠️ Conflict resolution: DynamoDB last-writer-wins may lose concurrent writes
  ⚠️ Cost: 3x Lambda + 3x DynamoDB + Global Table replication charges (~2.5x cost)
  ⚠️ Consistency: reads are eventually consistent across regions (< 1 second lag)

  Accepted trade-off: business determined that global availability + latency
  outweighs strong consistency requirement for this use case.
```

---

## Section 7 — Bonus Rapid-Fire Architecture Questions

**Q21: What is the difference between a NAT Gateway and an Internet Gateway?**
> Internet Gateway: allows public subnets to directly access the internet (bidirectional). NAT Gateway: allows private subnets to make outbound internet requests but blocks inbound connections. Private EC2 instances use NAT Gateway for software updates while remaining unreachable from the internet.

**Q22: Your S3 presigned URL expires but the user's upload is still in progress. What happens?**
> The upload fails with `403 Forbidden`. The expiration check happens at the time the upload request reaches S3, not at the start of the upload. Solution: generate presigned URLs with sufficient TTL (minimum 2x expected upload time), or use S3 multipart upload with a longer-lived presigned URL per part.

**Q23: How do you handle a DynamoDB hot partition?**
> A hot partition occurs when one partition key receives disproportionate traffic. Solutions: (1) Add a suffix to the partition key (user_id#{1..10}) and distribute writes, then query all 10 and merge; (2) Use DynamoDB DAX (cache) to absorb read hot partitions; (3) Redesign the key schema with better cardinality; (4) Use write sharding for time-series data (append timestamp to key).

**Q24: When would you choose ALB over NLB?**
> ALB (Layer 7): HTTP/HTTPS routing, path-based rules, host-based rules, WAF integration, WebSocket support, Cognito authentication. Use for web applications. NLB (Layer 4): TCP/UDP routing, extreme performance (millions of RPS, sub-millisecond), preserves source IP, static IP address. Use for: gaming servers, VoIP, IoT, financial trading systems that need ultra-low latency.

**Q25: Explain the difference between SQS visibility timeout and message retention period.**
> Visibility timeout: after a consumer reads a message, it becomes invisible to other consumers for this duration. If the consumer doesn't delete it within this time, it becomes visible again (allowing retry). Set it longer than your max processing time. Message retention: how long SQS keeps an unprocessed message before auto-deleting it (default 4 days, max 14 days). These are separate — a message can have a 12-hour visibility timeout and a 14-day retention period.

---

**[🏠 Back to README](../README.md)**

**Prev:** [← Interview Master](../99_interview_master/README.md) &nbsp;|&nbsp; **Next:** —

**Related Topics:** [Interview Master](../99_interview_master/README.md) · [Well-Architected Framework](../14_architecture/well_architected.md) · [High Availability](../14_architecture/high_availability.md) · [Disaster Recovery](../14_architecture/disaster_recovery.md)
