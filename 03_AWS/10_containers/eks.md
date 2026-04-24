# Stage 10b — EKS: Managed Kubernetes on AWS

> Run Kubernetes without managing the control plane. AWS handles master nodes, etcd, and upgrades — you handle your workloads.

---

## 1. Core Intuition

Imagine you're running a massive city of microservices. Each service is a container. You need someone to:
- Decide which server each container runs on
- Restart containers that crash
- Scale containers when traffic spikes
- Route traffic between containers

That's **Kubernetes** — the container orchestration system. But running Kubernetes yourself means managing the "control plane" (the brain): etcd, API server, scheduler, controller manager. That's painful.

**EKS (Elastic Kubernetes Service)** = AWS manages the entire control plane for you. You just bring your worker nodes (EC2 or Fargate) and deploy your workloads.

---

## 2. Kubernetes Concepts (Plain English)

```
Cluster       = The entire Kubernetes environment (control plane + worker nodes)
Node          = A server (EC2 instance) that runs your containers
Pod           = The smallest unit — one or more containers that share network/storage
Deployment    = "I want 3 replicas of my API pod always running"
Service       = A stable IP/DNS for your pods (pods come and go, Service stays)
Ingress       = HTTP routing rules → which path goes to which Service
Namespace     = Virtual cluster inside cluster (dev, staging, prod separation)
ConfigMap     = Store config data (env vars, config files)
Secret        = Store sensitive data (passwords, tokens) encrypted
HPA           = Horizontal Pod Autoscaler — scale pods based on CPU/memory
```

---

## 3. EKS Architecture

```mermaid
graph TB
    subgraph AWS_Managed["AWS Managed Control Plane"]
        API[API Server]
        ETCD[etcd<br/>Cluster State]
        SCHED[Scheduler]
        CM[Controller Manager]
    end

    subgraph Customer_VPC["Your VPC — Worker Nodes"]
        subgraph NG1["Node Group AZ-a"]
            N1[EC2 Node]
            P1[Pod: API]
            P2[Pod: API]
            N1 --- P1 & P2
        end
        subgraph NG2["Node Group AZ-b"]
            N2[EC2 Node]
            P3[Pod: Worker]
            P4[Pod: DB Proxy]
            N2 --- P3 & P4
        end
        subgraph Fargate["Fargate Nodes (serverless)"]
            FP1[Pod: Batch Job]
            FP2[Pod: ETL Task]
        end
    end

    ALB[Application Load Balancer] --> SVC[K8s Service]
    SVC --> P1 & P2

    AWS_Managed -->|kubelet| N1 & N2
    AWS_Managed -->|kubelet| FP1 & FP2

    ECR[Amazon ECR<br/>Container Registry] --> P1 & P2 & P3
```

---

## 4. EKS vs ECS

```
                    ECS                         EKS
Orchestrator:       AWS proprietary             Kubernetes (open source)
Learning curve:     Low (AWS-native)            High (K8s concepts)
Portability:        AWS only                    Any cloud / on-prem
Ecosystem:          AWS integrations            Huge K8s ecosystem (Helm, Istio)
Control plane:      Fully managed (free)        Managed ($0.10/hr per cluster)
Worker options:     EC2, Fargate                EC2, Fargate, EKS Anywhere
Config style:       Task Definitions (JSON)     YAML manifests
Autoscaling:        Service Auto Scaling        HPA + Cluster Autoscaler
Use when:           Pure AWS, simpler ops       K8s expertise, multi-cloud, complex
```

---

## 5. Node Groups: EC2 vs Fargate

```
Managed Node Groups (EC2):
  AWS provisions and manages EC2 instances
  You choose instance type (m5.large, c5.2xlarge, etc.)
  Nodes are visible in your account
  Use for: stateful workloads, GPU workloads, cost optimization

Fargate Profiles:
  No EC2 to manage — pods get their own micro-VM
  Pay per pod CPU/memory (not per node)
  No need to right-size nodes
  Use for: stateless workloads, batch jobs, simplicity
  Limitation: no DaemonSets, no privileged containers

Self-Managed Nodes:
  You provision EC2 yourself using your own AMI
  Full control but full operational burden
  Use for: custom kernel, specific hardware requirements
```

---

## 6. Core Kubernetes Objects (with YAML)

### Deployment

```yaml
# deployment.yaml — Run 3 replicas of your API
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-api
  template:
    metadata:
      labels:
        app: my-api
    spec:
      containers:
      - name: api
        image: 123456789.dkr.ecr.us-east-1.amazonaws.com/my-api:v1.2.3
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 30
```

### Service + Ingress

```yaml
# service.yaml — Stable internal IP for pods
apiVersion: v1
kind: Service
metadata:
  name: my-api-service
spec:
  selector:
    app: my-api          # routes to pods with this label
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP        # internal only

---
# ingress.yaml — Route external traffic
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-api-ingress
  annotations:
    kubernetes.io/ingress.class: alb         # AWS ALB Ingress Controller
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
  - host: api.myapp.com
    http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: my-api-service
            port:
              number: 80
```

### Horizontal Pod Autoscaler

HPA watches a metric — usually CPU or memory — and adjusts the replica count of a Deployment to keep that metric at the target level. It does not provision new nodes; it only adds or removes pods within the capacity already available on nodes.

```yaml
# hpa.yaml — Scale based on CPU utilization
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-api
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70    # ← scale up when avg CPU across all pods > 70%
  - type: Resource
    resource:
      name: memory
      target:
        type: AverageValue
        averageValue: 400Mi       # ← scale up when avg memory per pod > 400Mi
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60    # ← wait 60s before scaling up again
      policies:
      - type: Pods
        value: 4
        periodSeconds: 60              # ← add at most 4 pods per 60 seconds
    scaleDown:
      stabilizationWindowSeconds: 300  # ← wait 5min before scaling down (prevents flapping)
```

**HPA requires Metrics Server** to be installed in the cluster. EKS does not install it by default:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl top pods    # ← verify metrics are flowing
```

---

### Vertical Pod Autoscaler (VPA)

While HPA adds more pods, **VPA** adjusts the CPU and memory *requests and limits* of existing pods. Think of HPA as adding more checkout lanes at a grocery store, and VPA as making each lane worker faster.

VPA solves the problem of right-sizing: you set requests once at deploy time and often get them wrong. VPA monitors actual usage and recommends (or auto-applies) better values.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-api-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-api
  updatePolicy:
    updateMode: "Auto"       # ← Off = recommend only, Initial = set on new pods, Auto = evict and recreate
  resourcePolicy:
    containerPolicies:
    - containerName: "*"
      minAllowed:
        cpu: 100m
        memory: 50Mi
      maxAllowed:
        cpu: 2
        memory: 2Gi
```

```bash
# Check VPA recommendations
kubectl describe vpa my-api-vpa
# Shows: Recommendation > Container > Lower Bound / Target / Upper Bound
```

**VPA + HPA together:** Do NOT use VPA and HPA both targeting CPU/memory on the same deployment — they fight each other. Safe combination: HPA on custom metrics (queue depth, RPS) + VPA on CPU/memory.

VPA requires installing the VPA controller (not included in EKS by default):
```bash
# Install via Helm
helm repo add cowboysysop https://cowboysysop.github.io/charts/
helm install vpa cowboysysop/vertical-pod-autoscaler -n kube-system
```

---

### KEDA — Event-Driven Autoscaling

**KEDA (Kubernetes Event-Driven Autoscaling)** extends HPA to scale on any external signal: queue depth, Kafka lag, database row count, HTTP request rate, cron schedule. It is the standard approach for scaling workers that process queues or events.

The problem KEDA solves: HPA only knows about CPU and memory. A queue worker sitting idle at 5% CPU while 10,000 messages pile up will never scale with plain HPA. KEDA scales based on queue depth.

```yaml
# ScaledObject — KEDA's custom resource
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: sqs-worker-scaler
spec:
  scaleTargetRef:
    name: sqs-worker-deployment    # ← which Deployment to scale
  minReplicaCount: 0               # ← scale to zero when queue is empty
  maxReplicaCount: 50
  triggers:
  - type: aws-sqs-queue
    authenticationRef:
      name: keda-trigger-auth-aws
    metadata:
      queueURL: https://sqs.us-east-1.amazonaws.com/123456789/my-queue
      queueLength: "5"             # ← target: 1 worker per 5 messages
      awsRegion: us-east-1
      identityOwner: operator      # ← use IRSA
```

```yaml
# Kafka trigger example
triggers:
- type: kafka
  metadata:
    bootstrapServers: kafka:9092
    consumerGroup: my-consumer-group
    topic: my-topic
    lagThreshold: "100"            # ← 1 pod per 100 messages of lag
```

```yaml
# Cron trigger — scale up during business hours, down overnight
triggers:
- type: cron
  metadata:
    timezone: America/New_York
    start: "0 8 * * 1-5"          # ← 8am weekdays
    end: "0 20 * * 1-5"           # ← 8pm weekdays
    desiredReplicas: "10"
```

```bash
# Install KEDA via Helm
helm repo add kedacore https://kedacore.github.io/charts
helm install keda kedacore/keda --namespace keda --create-namespace
```

**Scale-to-zero:** KEDA can scale a Deployment to 0 replicas when idle (minReplicaCount: 0). This is not possible with plain HPA (minimum 1). Useful for development environments and infrequently-triggered workers.

---

### Autoscaling Decision Table

| What to scale on | Tool | Notes |
|---|---|---|
| CPU / memory utilization | HPA | Built-in; requires Metrics Server |
| Right-size resource requests | VPA | Do not combine with CPU/memory HPA |
| Queue depth (SQS, Kafka, Redis) | KEDA | Industry standard for async workers |
| Custom app metrics (RPS, latency) | HPA + custom metrics adapter | Requires Prometheus Adapter |
| Time of day / business hours | KEDA cron trigger | Scale to zero overnight |
| Node capacity (pending pods) | Cluster Autoscaler or Karpenter | Provisions new EC2 nodes |

---

## 7. EKS with AWS Services

```mermaid
graph LR
    subgraph EKS["EKS Cluster"]
        POD[Pods]
        SA[Service Account<br/>+ IRSA]
    end

    SA -->|assume role| IAM[IAM Role]
    IAM --> S3[S3 Bucket]
    IAM --> DDB[DynamoDB]
    IAM --> SM[Secrets Manager]

    ECR[Amazon ECR] -->|pull images| POD
    ALB[AWS ALB<br/>Ingress Controller] -->|route traffic| POD
    CW[CloudWatch<br/>Container Insights] -->|metrics/logs| POD
    EFS[Amazon EFS<br/>CSI Driver] -->|persistent storage| POD
```

**IRSA (IAM Roles for Service Accounts):**
```
Instead of giving EC2 nodes broad IAM permissions,
IRSA lets individual pods assume specific IAM roles.

Pod A (payment service) → assumes role with DynamoDB access only
Pod B (report service) → assumes role with S3 read access only

Much safer than node-level IAM!
```

---

## 8. kubectl — The CLI

```bash
# Configure kubectl to use EKS cluster
aws eks update-kubeconfig --name my-cluster --region us-east-1

# View cluster nodes
kubectl get nodes

# Deploy application
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# View pods
kubectl get pods -n production
kubectl get pods -o wide      # shows which node each pod runs on

# Describe a pod (troubleshooting)
kubectl describe pod my-api-7d9f8b-xyz -n production

# View logs
kubectl logs my-api-7d9f8b-xyz -n production
kubectl logs -f my-api-7d9f8b-xyz    # follow/tail logs

# Scale deployment
kubectl scale deployment my-api --replicas=5

# Rolling update
kubectl set image deployment/my-api api=my-api:v1.2.4

# Rollback
kubectl rollout undo deployment/my-api

# Port-forward for local testing
kubectl port-forward svc/my-api-service 8080:80

# Execute into a pod
kubectl exec -it my-api-7d9f8b-xyz -- /bin/sh
```

---

## 9. Console Walkthrough

```
Create EKS Cluster:
━━━━━━━━━━━━━━━━━━
Console: EKS → Create cluster

Step 1: Configure cluster
  Name: my-production-cluster
  Kubernetes version: 1.29 (latest)
  Cluster service role: create new (AmazonEKSClusterPolicy)

Step 2: Specify networking
  VPC: your production VPC
  Subnets: private subnets in 3 AZs
  Security groups: allow worker nodes to reach API server
  Cluster endpoint access: Public and private

Step 3: Configure logging
  Enable: API server, Audit, Authenticator logs → CloudWatch

Step 4: Select add-ons
  Enable: CoreDNS, kube-proxy, Amazon VPC CNI, AWS Load Balancer Controller

Step 5: Review and create (takes ~10 min)

Add Node Group:
━━━━━━━━━━━━━━
EKS → Clusters → my-cluster → Compute → Add Node Group
  Name: production-workers
  Node IAM role: create with AmazonEKSWorkerNodePolicy + ECR access
  Instance type: m5.xlarge
  Scaling: min=2, desired=3, max=10
  Subnets: private subnets
```

---

## 10. EKS Add-ons (Important)

```
AWS Load Balancer Controller:
  Creates ALB/NLB automatically when you create Ingress/Service objects
  Install via: EKS console → Add-ons → AWS Load Balancer Controller

Cluster Autoscaler:
  Adds/removes EC2 nodes based on pod pending state
  Pod can't be scheduled (no resources) → CA adds a node
  Nodes underutilized → CA removes a node

AWS EFS CSI Driver:
  Mount EFS volumes into pods as persistent storage
  Shared across pods, survives pod restarts

Amazon VPC CNI:
  Assigns real VPC IPs to pods (not overlay network)
  Pods get actual IPs from your subnet CIDR
  Enables direct communication with other AWS services

Karpenter (modern alternative to Cluster Autoscaler):
  Smarter node provisioning — picks the right instance type per workload
  Faster scaling (seconds vs minutes)
  Supports spot instances automatically
```

---

## 11. Interview Perspective

**Q: What is the difference between EKS and ECS?**
ECS is AWS's proprietary container orchestrator — simpler, fully managed, deeply integrated with AWS but AWS-only. EKS runs Kubernetes — more complex, portable across clouds, huge ecosystem (Helm charts, service meshes, GitOps tools). Use ECS when you're AWS-only and want simplicity; use EKS when your team knows Kubernetes, needs multi-cloud portability, or needs advanced features like custom operators and service meshes.

**Q: What is IRSA and why is it better than node-level IAM?**
IRSA (IAM Roles for Service Accounts) lets individual pods assume specific IAM roles via OIDC federation. With node-level IAM, all pods on a node share the same permissions — a compromised pod can access everything. With IRSA, each pod gets its own minimal IAM role. If the payment pod is compromised, it can only access what that role allows, not the S3 buckets or RDS databases used by other pods.

**Q: How does Kubernetes handle pod scaling vs node scaling?**
Two separate systems: HPA (Horizontal Pod Autoscaler) scales pods based on CPU/memory/custom metrics — fast, seconds to add a pod. Cluster Autoscaler (or Karpenter) scales nodes when pods can't be scheduled due to insufficient resources — slower, 1-3 minutes to provision an EC2. Both work together: HPA adds pods → CA adds nodes when pods are pending.

---

**[🏠 Back to README](../README.md)**

**Prev:** [← ECS](../10_containers/ecs.md) &nbsp;|&nbsp; **Next:** [Lambda →](../11_serverless/lambda.md)

**Related Topics:** [ECS](../10_containers/ecs.md) · [IAM](../06_security/iam.md) · [CloudWatch & Observability](../08_monitoring/cloudwatch.md) · [CI/CD Pipeline](../13_devops_cicd/cicd_pipeline.md)

---

## 📝 Practice Questions

- 📝 [Q46 · eks-basics](../aws_practice_questions_100.md#q46--normal--eks-basics)
- 📝 [Q72 · eks-node-groups](../aws_practice_questions_100.md#q72--thinking--eks-node-groups)

