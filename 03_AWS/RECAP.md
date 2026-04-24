# AWS — Topic Recap

> One-line summary of every module. Use this to quickly find which module covers the concept you need.

---

## Cloud Foundations

### 01 · Cloud Foundations — `01_cloud_foundations/theory.md`
The "why" of cloud computing: IaaS vs PaaS vs SaaS, NIST's 5 characteristics, deployment models (public/private/hybrid/multi-cloud), the Shared Responsibility Model, and AWS pricing fundamentals (On-Demand, Reserved, Spot, Savings Plans).

### 02 · Global Infrastructure — `02_global_infrastructure/theory.md`
How AWS spans the globe: Regions, Availability Zones, Edge Locations, Local Zones, Wavelength Zones, and Outposts — plus how to choose a region and the difference between HA, Fault Tolerance, and Disaster Recovery.

---

## Compute & Storage

### 03 · Compute — `03_compute/`

| File | Covers |
|------|--------|
| `ec2.md` | EC2 instance types (families, Graviton, burstable), AMIs, EBS volume types, Security Groups, User Data, instance lifecycle, pricing models |
| `auto_scaling.md` | ALB/NLB/GWLB load balancers, Auto Scaling Groups, scaling policies (target tracking, step, scheduled, predictive), Launch Templates, connection draining |
| `elastic_beanstalk.md` | PaaS deployment for web apps; environment tiers, deployment strategies (all-at-once, rolling, immutable, blue/green), `.ebextensions` customization |

### 04 · Storage — `04_storage/`

| File | Covers |
|------|--------|
| `s3.md` | Infinite object storage, buckets, storage classes (Standard → Glacier), versioning, lifecycle policies, bucket policies, static website hosting, S3 as data lake foundation |
| `ebs_efs.md` | EBS (gp3, io2, st1, sc1 volume types, snapshots, encryption) and EFS (shared NFS filesystem for multi-instance mounts, lifecycle tiers) |

---

## Networking & Security

### 05 · Networking — `05_networking/`

| File | Covers |
|------|--------|
| `vpc.md` | VPC fundamentals: CIDR blocks, public/private subnets, Internet Gateway, NAT Gateway, Route Tables, Security Groups vs NACLs, VPC Peering, VPC Endpoints |
| `route53_cloudfront.md` | Route 53 DNS record types (A, CNAME, Alias), routing policies (latency, weighted, failover, geolocation); CloudFront CDN: origins, distributions, cache behaviors, OAC, Lambda@Edge |

### 06 · Security — `06_security/`

| File | Covers |
|------|--------|
| `iam.md` | Users, Groups, Roles, and Policies; policy anatomy (Effect/Action/Resource/Condition); IAM roles for EC2 and Lambda; least privilege; permission boundaries; STS and cross-account access |
| `kms.md` | Symmetric vs asymmetric encryption, envelope encryption, KMS key types (AWS-owned, AWS-managed, Customer-managed), key policies, S3/EBS/RDS encryption patterns |
| `waf_shield_guardduty.md` | WAF Web ACL rules (managed rule groups, rate limiting, IP sets); Shield Standard vs Advanced (DDoS protection); GuardDuty (threat detection from VPC Flow Logs, CloudTrail, DNS); Security Hub and Macie |
| `cognito.md` | User Pools (sign-up/sign-in, MFA, social login, JWT tokens) and Identity Pools (exchange JWT for temporary AWS credentials); Hosted UI; integration with API Gateway |

---

## Databases & Monitoring

### 07 · Databases — `07_databases/`

| File | Covers |
|------|--------|
| `rds_aurora.md` | RDS managed relational databases (MySQL, PostgreSQL, etc.), Multi-AZ, read replicas, automated backups; Aurora's cloud-native engine with shared storage architecture, Aurora Serverless v2 |
| `dynamodb.md` | NoSQL key-value store, partition key and sort key design, provisioned vs on-demand capacity, DynamoDB Streams, Global Tables, DAX (in-memory cache), GSIs and LSIs |
| `elasticache.md` | In-memory caching layer: Redis (data structures, persistence, pub/sub, cluster mode, Multi-AZ) vs Memcached (simple, multi-threaded); cache-aside and write-through patterns; eviction policies |

### 08 · Monitoring — `08_monitoring/`

| File | Covers |
|------|--------|
| `cloudwatch.md` | The three pillars of observability: metrics (namespaces, dimensions, custom metrics, dashboards), logs (Log Groups, Log Insights queries, metric filters), and alarms (threshold, composite, SNS actions); CloudTrail for API audit; X-Ray for distributed tracing |
| `otel.md` | OpenTelemetry on AWS: ADOT Collector, instrumenting services with traces/metrics/logs, exporting to CloudWatch, X-Ray, and Prometheus; end-to-end trace visualization across microservices |

---

## DevOps & Containers

### 09 · IaC — `09_iac/`

| File | Covers |
|------|--------|
| `cloudformation.md` | CloudFormation templates (YAML/JSON), stacks, parameters, outputs, mappings, conditions, intrinsic functions, Change Sets, drift detection, StackSets for multi-account deployment |
| `cdk_terraform.md` | AWS CDK (define infrastructure in Python/TypeScript/Java, compiles to CloudFormation; Constructs L1/L2/L3) and Terraform (HCL, state file, plan/apply, cross-cloud support) — when to choose each |

### 10 · Containers — `10_containers/`

| File | Covers |
|------|--------|
| `ecs.md` | ECS concepts (cluster, task definition, task, service), Fargate vs EC2 launch types, ECR image registry, service auto scaling, rolling and blue/green deployments via CodeDeploy, ECS service connect |
| `eks.md` | Kubernetes on AWS: managed control plane, node groups (managed, self-managed, Fargate), kubectl basics, Deployments/Services/Ingress, cluster autoscaler, EKS Add-ons (CoreDNS, kube-proxy, VPC CNI) |

### 11 · Serverless — `11_serverless/`

| File | Covers |
|------|--------|
| `lambda.md` | Event-driven compute: triggers (S3, API Gateway, SQS, EventBridge), execution model, cold starts, memory/timeout configuration, Lambda layers, versions and aliases, Lambda@Edge |
| `api_gateway.md` | REST API vs HTTP API vs WebSocket API; routes, integrations, authorizers (Lambda, Cognito), throttling, caching, stages, usage plans and API keys |
| `sqs_sns_eventbridge.md` | SQS (standard vs FIFO queues, visibility timeout, DLQ, long polling); SNS (pub/sub topics, fan-out pattern, message filtering); EventBridge (event buses, rules, targets, schema registry) |
| `step_functions.md` | State machine orchestration: states (Task, Choice, Parallel, Map, Wait), Standard vs Express workflows, error handling and retries, visual debugging, integrations with Lambda/ECS/DynamoDB |
| `appsync.md` | Managed GraphQL API: schema definition, resolvers (direct Lambda, VTL templates), data sources (DynamoDB, RDS, Lambda, HTTP), real-time subscriptions, caching, fine-grained authorization |

---

## Architecture & Cost

### 12 · Data Analytics — `12_data_analytics/`

| File | Covers |
|------|--------|
| `kinesis.md` | Real-time streaming: Kinesis Data Streams (shards, producers, consumers, retention), Kinesis Data Firehose (serverless delivery to S3/Redshift/OpenSearch), Kinesis Data Analytics (SQL on streams), MSK (managed Kafka) |
| `athena_glue_redshift.md` | Serverless SQL on S3 with Athena; Glue Data Catalog (crawlers, ETL jobs, schema registry); Redshift columnar data warehouse (nodes, distribution styles, Spectrum for S3 queries) |
| `emr_lake_formation_flink.md` | EMR managed Spark/Hadoop clusters for petabyte-scale processing; Lake Formation for fine-grained data lake access control (column/row-level permissions); Kinesis Analytics for real-time Flink applications |

### 13 · DevOps & CI/CD — `13_devops_cicd/cicd_pipeline.md`
AWS-native CI/CD pipeline: CodeCommit (Git hosting), CodeBuild (build and test), CodeDeploy (deployment strategies — in-place, blue/green, canary), CodePipeline (orchestrates all stages), integration with GitHub Actions and Jenkins.

### 14 · Architecture — `14_architecture/`

| File | Covers |
|------|--------|
| `well_architected.md` | The 6 pillars of the AWS Well-Architected Framework: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability — with key design principles for each |
| `high_availability.md` | HA patterns: Multi-AZ deployments, ALB + ASG across AZs, RDS Multi-AZ failover, read replicas, health checks, graceful degradation, stateless application design, session management with ElastiCache |
| `disaster_recovery.md` | DR strategies (Backup & Restore, Pilot Light, Warm Standby, Active-Active), RTO/RPO definitions, Route 53 failover routing, cross-region replication for S3/RDS/DynamoDB, DR testing runbooks |

### 15 · Cost Optimization — `15_cost_optimization/theory.md`
Four cost principles (right-size, commit on compute, eliminate waste, architect for cost); EC2 pricing models; Compute Optimizer for right-sizing; Savings Plans vs Reserved Instances; Spot for fault-tolerant jobs; S3 lifecycle policies; Cost Explorer, Budgets, and Cost Anomaly Detection; common waste patterns (idle EBS, oversized RDS, unoptimized data transfer).

### 16 · AI/ML — `16_ai_ml/`

| File | Covers |
|------|--------|
| `bedrock.md` | Foundation model API (Claude, Llama, Mistral, Titan): InvokeModel, streaming, model comparison, prompt engineering, fine-tuning with continued pre-training, model evaluation |
| `bedrock_knowledge_bases.md` | RAG on AWS: connect S3 documents to a vector store (OpenSearch Serverless or Aurora), automatic chunking and embedding, RetrieveAndGenerate API, citation support |
| `bedrock_agents.md` | AI Agents that take actions: action groups backed by Lambda, tool calling (ReAct loop), code interpreter, multi-agent collaboration, memory, integration with Knowledge Bases |
| `guardrails_amazon_q.md` | Bedrock Guardrails (content filtering, topic blocking, PII redaction, grounding checks); Amazon Q Business (enterprise AI assistant over internal documents) and Amazon Q Developer (AI coding assistant in IDE) |
| `sagemaker.md` | Custom ML at scale: Data Wrangler, Training Jobs on GPU clusters, Hyperparameter Tuning, Model Registry, SageMaker Endpoints (real-time and batch), Pipelines for ML workflows |
| `ai_services.md` | Pre-built AI APIs: Rekognition (image/video analysis), Textract (document OCR), Comprehend (NLP/sentiment), Transcribe (speech-to-text), Polly (text-to-speech), Translate, Personalize (recommendations) |

---

## Interview

### 99 · Interview Master — `99_interview_master/scenarios.md`
Senior-level scenario-based questions from Amazon, Google, Stripe, and top startups: system design (URL shortener, file upload service, notification system, data pipeline), architecture trade-offs, cost/availability decisions, and how to structure interview answers with clarifying questions and RTO/RPO framing.

---

*Total modules: 16 + interview · Last updated: 2026-04-21*
