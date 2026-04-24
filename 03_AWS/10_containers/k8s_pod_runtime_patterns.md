# Kubernetes Pod Runtime Patterns — Industry Guide

A pod is not just a wrapper around one container. It is a small group of tightly coupled processes that share a network identity, storage volumes, and lifecycle. Understanding the patterns built into the pod spec — init containers, sidecars, the downward API, health probes, and lifecycle hooks — is what separates engineers who fight Kubernetes from engineers who use it intentionally.

---

## Pod Lifecycle Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│  POD LIFECYCLE                                                          │
│                                                                         │
│  Pending                                                                │
│    └── Scheduler assigns pod to node                                    │
│    └── kubelet pulls images                                             │
│                                                                         │
│  Init Phase (sequential, must all succeed)                              │
│    └── init-container-1 runs to completion ✓                           │
│    └── init-container-2 runs to completion ✓                           │
│                                                                         │
│  Running                                                                │
│    └── All app containers start simultaneously                          │
│    └── postStart hook fires (if configured)                             │
│    └── Readiness probe starts checking                                  │
│    └── Liveness probe starts checking                                   │
│                                                                         │
│  Terminating                                                            │
│    └── preStop hook runs                                                │
│    └── SIGTERM sent to containers                                       │
│    └── terminationGracePeriodSeconds window                            │
│    └── SIGKILL if not exited                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Init Containers: Setup That Must Finish Before Your App Starts

Init containers run sequentially, to completion, before any app container starts. If any init container fails, the pod restarts and tries again. They are for setup work that must succeed before your application is safe to start.

**When to use init containers:**

```
┌─────────────────────────────────────────────────────────────────────┐
│  Use init containers when:                                          │
│                                                                     │
│  ✓ Wait for a dependency to be ready                                │
│    (database, external API, config service)                         │
│                                                                     │
│  ✓ Populate a shared volume before app starts                       │
│    (download model weights, clone config files, render templates)   │
│                                                                     │
│  ✓ Register with a service registry                                 │
│                                                                     │
│  ✓ Run database migrations (with care — see below)                  │
│                                                                     │
│  ✓ Security setup — fetch secrets from Vault                        │
│    and write to shared emptyDir volume                              │
└─────────────────────────────────────────────────────────────────────┘
```

```yaml
apiVersion: v1
kind: Pod
spec:
  initContainers:

  # Pattern 1: Wait for dependency
  - name: wait-for-db
    image: busybox:1.36
    command:
      - sh
      - -c
      - |
        until nc -z postgres-service 5432; do
          echo "waiting for postgres..."
          sleep 2
        done
        echo "postgres is ready"

  # Pattern 2: Populate shared volume with config
  - name: render-config
    image: my-config-renderer:latest
    command:
      - sh
      - -c
      - |
        # Template rendering: substitute env vars into config files
        envsubst < /templates/app.conf.tmpl > /shared/app.conf
        echo "Config rendered: $(cat /shared/app.conf | head -3)"
    env:
      - name: DB_HOST
        valueFrom:
          configMapKeyRef:
            name: app-config
            key: DB_HOST
    volumeMounts:
      - name: shared-config
        mountPath: /shared
      - name: config-templates
        mountPath: /templates

  containers:
  - name: app
    image: my-app:latest
    volumeMounts:
      - name: shared-config
        mountPath: /etc/app            # ← reads rendered config here

  volumes:
  - name: shared-config
    emptyDir: {}                       # ← shared between init and app containers
  - name: config-templates
    configMap:
      name: config-templates
```

**Database migrations warning:** Running migrations in init containers means every pod restart triggers the migration. In rolling updates, multiple pods may run migrations simultaneously. Better pattern: a separate Kubernetes `Job` that runs migrations once before the Deployment rollout.

---

## Sidecar Containers: Persistent Helpers That Run Alongside Your App

A sidecar is a container in the same pod that augments or supports the main container. It shares the pod's network and can share volumes. It runs for the lifetime of the pod (unlike init containers which exit).

```
┌─────────────────────────────────────────────────────────────────────┐
│  Pod                                                                │
│  ┌──────────────────┐   ┌──────────────────┐                       │
│  │   main app       │   │  sidecar         │                       │
│  │                  │   │                  │                       │
│  │  writes logs to  │   │  reads logs from │  → ships to           │
│  │  /var/log/app/   │   │  /var/log/app/   │    Elasticsearch      │
│  │                  │   │                  │                       │
│  └──────────────────┘   └──────────────────┘                       │
│          │                       │                                 │
│          └──────────┬────────────┘                                 │
│               shared emptyDir volume                               │
│               same network (localhost)                             │
└─────────────────────────────────────────────────────────────────────┘
```

**Common sidecar patterns:**

| Pattern | Sidecar role | Example |
|---|---|---|
| Log shipper | Reads log files, forwards to central store | Fluentd, Fluent Bit |
| Metrics exporter | Exposes app metrics in Prometheus format | Prometheus exporter |
| Service mesh proxy | Intercepts network traffic for mTLS, tracing | Envoy (Istio, Linkerd) |
| Secret injector | Fetches secrets from Vault, writes to volume | Vault agent |
| Config reloader | Watches ConfigMap, sends SIGHUP to app | Configmap-reload |

```yaml
spec:
  containers:
  # Main app
  - name: web-app
    image: my-app:latest
    volumeMounts:
      - name: logs
        mountPath: /var/log/app

  # Sidecar: log forwarding
  - name: log-forwarder
    image: fluent/fluent-bit:latest
    volumeMounts:
      - name: logs
        mountPath: /var/log/app        # ← reads same directory as main app
      - name: fluentbit-config
        mountPath: /fluent-bit/etc/

  # Sidecar: metrics
  - name: metrics-exporter
    image: prom/statsd-exporter:latest
    ports:
      - containerPort: 9102            # ← Prometheus scrapes this port

  volumes:
  - name: logs
    emptyDir: {}
  - name: fluentbit-config
    configMap:
      name: fluentbit-config
```

**Kubernetes 1.29+ sidecar containers:** Kubernetes added native sidecar support — sidecars start before the main container and shut down after it (solving the ordering problem). Declare them with `restartPolicy: Always` inside `initContainers`.

---

## Health Probes: Liveness, Readiness, and Startup

Probes are how Kubernetes knows whether your container is working. Three types, three distinct jobs.

```
┌────────────────────────────────────────────────────────────────────┐
│  Probe       │  Question asked        │  Action on failure         │
├────────────────────────────────────────────────────────────────────┤
│  startup     │  Has it started yet?   │  Restart container         │
│              │  (checked first)       │  (replaces liveness during │
│              │                        │   slow startup)            │
├────────────────────────────────────────────────────────────────────┤
│  liveness    │  Is it still alive?    │  Restart container         │
│              │  (deadlock? crash?)    │                            │
├────────────────────────────────────────────────────────────────────┤
│  readiness   │  Is it ready for       │  Remove from Service       │
│              │  traffic?              │  load balancer (NOT        │
│              │                        │  restarted)                │
└────────────────────────────────────────────────────────────────────┘
```

```yaml
spec:
  containers:
  - name: app
    image: my-app:latest

    # Startup probe: gives app 5 * 12 = 60 seconds to start
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      failureThreshold: 12
      periodSeconds: 5

    # Liveness probe: restart if app deadlocks
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 0       # ← 0 because startupProbe handles startup
      periodSeconds: 10
      failureThreshold: 3          # ← 3 failures = restart

    # Readiness probe: remove from load balancer if not ready
    readinessProbe:
      httpGet:
        path: /readyz               # ← different endpoint from liveness
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
```

**Implementing probe endpoints in your app:**

```python
from flask import Flask, jsonify
import os

app = Flask(__name__)

# Liveness: "is the process functioning at all?"
# Return 200 = alive. Return 5xx = restart me.
# Keep it SIMPLE — just check the process is not deadlocked.
# Do NOT check downstream dependencies here (that causes cascading restarts).
@app.route("/healthz")
def liveness():
    return jsonify({"status": "ok"}), 200

# Readiness: "am I ready to serve traffic?"
# Check database connection, cache warmup, model loaded, etc.
# Failing this removes the pod from the load balancer WITHOUT restarting it.
@app.route("/readyz")
def readiness():
    try:
        db.execute("SELECT 1")          # quick DB connectivity check
        if not model_loaded:
            return jsonify({"status": "not ready", "reason": "model loading"}), 503
        return jsonify({"status": "ready"}), 200
    except Exception as e:
        return jsonify({"status": "not ready", "reason": str(e)}), 503
```

**Critical distinction:** Never check external dependencies in the **liveness** probe. If your database goes down and liveness fails, Kubernetes restarts all your pods — making the outage worse (the pods were fine, only the database was down). Use readiness for dependency checks.

---

## Lifecycle Hooks: postStart and preStop

Lifecycle hooks fire at specific moments in a container's life.

```
Container starts
  │
  ├── entrypoint process starts
  └── postStart hook fires (simultaneously — not after startup completes)
        → runs a command or HTTP call
        → if it fails, container is killed and restarted

  ... container runs ...

Container stop requested
  └── preStop hook fires
        → runs before SIGTERM is sent
        → use for: draining connections, deregistering from service mesh,
                   delaying shutdown until load balancer updates routing
```

```yaml
spec:
  containers:
  - name: app
    lifecycle:

      # postStart: fire immediately when container starts
      # NOTE: runs in parallel with ENTRYPOINT — do NOT use for initialization
      # Use init containers for that. Use postStart for fire-and-forget tasks.
      postStart:
        exec:
          command:
            - /bin/sh
            - -c
            - echo "Container started at $(date)" >> /var/log/startup.log

      # preStop: runs BEFORE SIGTERM — use to delay shutdown
      # Common pattern: sleep to let load balancer drain connections
      preStop:
        exec:
          command:
            - /bin/sh
            - -c
            - |
              sleep 5                          # wait for LB to drain
              curl -X POST localhost:8080/drain  # tell app to stop accepting new requests
```

**preStop sleep pattern:** When Kubernetes removes a pod from a Service's endpoints, the load balancer takes a few seconds to stop routing traffic to it. SIGTERM arrives almost simultaneously. Without a `preStop` sleep, requests still in-flight to the pod during that window get connection refused. Adding `sleep 5` in preStop delays SIGTERM long enough for the load balancer to drain.

---

## The Downward API: Pod Metadata as Environment Variables

Your application sometimes needs to know things about itself — its own pod name, namespace, node, resource limits. The **Downward API** injects this metadata into the container as environment variables or files, without requiring any Kubernetes API calls from inside the app.

```yaml
spec:
  containers:
  - name: app
    env:
      # Pod metadata
      - name: POD_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.name

      - name: POD_NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace

      - name: NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName

      - name: POD_IP
        valueFrom:
          fieldRef:
            fieldPath: status.podIP

      # Resource limits (useful for tuning thread pools, JVM heap, etc.)
      - name: MEMORY_LIMIT
        valueFrom:
          resourceFieldRef:
            resource: limits.memory     # → "536870912" (bytes)
            containerName: app

      - name: CPU_REQUEST
        valueFrom:
          resourceFieldRef:
            resource: requests.cpu      # → "250" (millicores)
            containerName: app
```

**Using Downward API in practice:**

```python
import os

pod_name      = os.environ.get("POD_NAME", "unknown")
pod_namespace = os.environ.get("POD_NAMESPACE", "default")
memory_bytes  = int(os.environ.get("MEMORY_LIMIT", "536870912"))

# Auto-tune thread pool based on actual memory limit
memory_mb = memory_bytes // (1024 * 1024)
thread_pool_size = max(4, memory_mb // 64)    # 1 thread per 64MB

# Include pod identity in all log lines
import logging
logging.basicConfig(
    format=f"%(asctime)s {pod_name} %(levelname)s %(message)s"
)
```

**Downward API as volume (for labels and annotations):**

Labels and annotations can change at runtime (kubectl annotate). Environment variables are set at container start and do not update. Use volume mount for dynamic metadata:

```yaml
volumes:
- name: pod-info
  downwardAPI:
    items:
      - path: "labels"
        fieldRef:
          fieldPath: metadata.labels
      - path: "annotations"
        fieldRef:
          fieldPath: metadata.annotations
```

```python
# Reads current labels (including dynamically added ones)
with open("/etc/pod-info/labels") as f:
    labels = dict(line.strip().split('=', 1) for line in f if '=' in line)
app_version = labels.get("app.kubernetes.io/version", "unknown")
```

---

## Resource Requests and Limits: Scheduler Meets cgroups

Requests and limits have two separate jobs that are often confused.

```
┌──────────────────────────────────────────────────────────────────────┐
│  REQUESTS                          LIMITS                           │
│                                                                      │
│  Used by the SCHEDULER             Used by the KERNEL (cgroups)     │
│  "guarantee this much"             "hard cap at this much"          │
│                                                                      │
│  cpu.request = 250m                cpu.limit = 500m                 │
│  → scheduler only places           → kernel throttles process       │
│    pod on nodes with                 when it exceeds 500m           │
│    250m CPU available                                               │
│                                                                      │
│  memory.request = 256Mi            memory.limit = 512Mi             │
│  → scheduler guarantee             → kernel OOM kills process       │
│                                      if it exceeds 512Mi            │
└──────────────────────────────────────────────────────────────────────┘
```

**QoS classes** (affects eviction priority under node pressure):

| Class | Condition | Evicted |
|---|---|---|
| `Guaranteed` | requests == limits for all containers | Last |
| `Burstable` | requests < limits | Middle |
| `BestEffort` | no requests or limits set | First |

**Tuning JVM-based apps (Java, Kotlin, Scala):**

The JVM reads available memory from cgroups if configured. Without tuning, it sees host memory and allocates too much heap.

```yaml
env:
  - name: JAVA_OPTS
    value: "-XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0"
    # ← JVM reads cgroup memory limit, uses 75% for heap
```

**Python thread pool tuning via Downward API:**

```python
import os

memory_limit = int(os.environ.get("MEMORY_LIMIT", "536870912"))  # bytes
cpu_request  = int(os.environ.get("CPU_REQUEST", "250"))          # millicores

# uvicorn workers = CPU millicores / 250, minimum 2
workers = max(2, cpu_request // 250)
```

---

## ServiceAccount: How Pods Authenticate to Kubernetes and AWS

Think of a ServiceAccount as a badge. When a new employee (pod) joins a company (cluster), security doesn't give them the CEO's master key — they get a badge that grants access only to the rooms they actually need. A ServiceAccount is that badge. It is a Kubernetes identity assigned to a pod, used to control what that pod is allowed to do inside the cluster and, on AWS, what it is allowed to do in AWS itself.

```
┌────────────────────────────────────────────────────────────────────┐
│  ServiceAccount — the identity layer                               │
│                                                                    │
│  ServiceAccount (identity)                                         │
│       │                                                            │
│       ├── RoleBinding / ClusterRoleBinding                         │
│       │        └── grants permissions inside Kubernetes            │
│       │             (list pods, read secrets, etc.)                │
│       │                                                            │
│       └── IRSA annotation (on EKS)                                 │
│                └── grants permissions in AWS                       │
│                     (read S3, write DynamoDB, etc.)                │
└────────────────────────────────────────────────────────────────────┘
```

### What Kubernetes does automatically

Every namespace has a `default` ServiceAccount. Every pod gets the `default` SA unless you specify otherwise. Kubernetes auto-mounts a signed JWT token into every pod:

```
Pod starts
  └── kubelet mounts token at /var/run/secrets/kubernetes.io/serviceaccount/
        ├── token      ← JWT signed by the cluster CA — proves pod's identity
        ├── ca.crt     ← CA cert to verify the API server's TLS certificate
        └── namespace  ← the namespace this pod lives in
```

The token is a short-lived JWT (rotated automatically by Kubernetes). It identifies the pod to the API server as: `system:serviceaccount:<namespace>:<serviceaccount-name>`.

### Giving a pod Kubernetes API permissions (RBAC)

ServiceAccount alone grants no permissions. You pair it with a `Role` (namespace-scoped) or `ClusterRole` (cluster-wide) via a binding:

```yaml
# 1. Create a dedicated ServiceAccount — never use "default" for real workloads
apiVersion: v1
kind: ServiceAccount
metadata:
  name: job-runner
  namespace: production

---
# 2. Define what it is allowed to do (Role = namespace-scoped)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: job-runner-role
  namespace: production
rules:
- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["create", "get", "list", "delete"]   # ← only what it needs

---
# 3. Bind the ServiceAccount to the Role
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: job-runner-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: job-runner
  namespace: production
roleRef:
  kind: Role
  name: job-runner-role
  apiGroup: rbac.authorization.k8s.io

---
# 4. Assign the ServiceAccount to the pod
spec:
  serviceAccountName: job-runner   # ← pod gets job-runner's token
```

### Calling the Kubernetes API from inside a pod

```python
import requests

with open("/var/run/secrets/kubernetes.io/serviceaccount/token") as f:
    token = f.read().strip()

with open("/var/run/secrets/kubernetes.io/serviceaccount/namespace") as f:
    namespace = f.read().strip()

headers = {"Authorization": f"Bearer {token}"}
resp = requests.get(
    f"https://kubernetes.default.svc/api/v1/namespaces/{namespace}/pods",
    headers=headers,
    verify="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
)
# Returns 403 if ServiceAccount has no permission — 200 if allowed
```

### Role vs ClusterRole — the scope distinction

A **Role** grants permissions within a single namespace. A **ClusterRole** grants permissions cluster-wide — across all namespaces, or for cluster-scoped resources (nodes, PersistentVolumes, namespaces themselves) that do not belong to any namespace.

```
┌─────────────────────────────────────────────────────────────────┐
│  Role                      ClusterRole                          │
│                                                                 │
│  namespace-scoped          cluster-scoped                       │
│  "in namespace X, do Y"    "in ALL namespaces, do Y"           │
│                            OR "manage cluster resources"        │
│                                                                 │
│  Bound with:               Bound with:                          │
│  RoleBinding               ClusterRoleBinding                   │
│  (namespace-scoped)        (cluster-scoped)                     │
│                                                                 │
│                            OR RoleBinding                       │
│                            (ClusterRole used in one namespace)  │
└─────────────────────────────────────────────────────────────────┘
```

```yaml
# ClusterRole — can read pods in ANY namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]

# ClusterRole — manage nodes (cluster-scoped resource — can't use namespaced Role)
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "patch"]
```

```yaml
# ClusterRoleBinding — grants cluster-wide permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pod-reader-global
subjects:
- kind: ServiceAccount
  name: monitoring-agent
  namespace: monitoring            # ← the SA lives in 'monitoring' namespace
roleRef:
  kind: ClusterRole
  name: pod-reader                 # ← but can read pods in ALL namespaces
  apiGroup: rbac.authorization.k8s.io
```

```yaml
# RoleBinding using a ClusterRole — restricts the ClusterRole to one namespace
# Useful: define the Role once as ClusterRole, reuse it in many namespaces
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-in-production
  namespace: production            # ← scope limited to 'production' namespace
subjects:
- kind: ServiceAccount
  name: my-app
  namespace: production
roleRef:
  kind: ClusterRole                # ← referencing a ClusterRole (not Role)
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Common RBAC verbs reference:**

| Verb | HTTP equivalent | Meaning |
|---|---|---|
| `get` | GET (single) | Read one resource |
| `list` | GET (collection) | List all resources |
| `watch` | GET (streaming) | Stream changes |
| `create` | POST | Create resource |
| `update` | PUT | Replace resource |
| `patch` | PATCH | Partial update |
| `delete` | DELETE | Remove resource |

```bash
# Check what a ServiceAccount can do (auth can-i)
kubectl auth can-i list pods --as=system:serviceaccount:production:my-app -n production
kubectl auth can-i create jobs --as=system:serviceaccount:production:job-runner -n production

# List all roles in a namespace
kubectl get roles,rolebindings -n production

# Describe what a role permits
kubectl describe role job-runner-role -n production
```

### Security best practice — disable when not needed

Most pods never call the Kubernetes API. Auto-mounting the token is unnecessary and slightly increases attack surface. Disable it explicitly:

```yaml
spec:
  automountServiceAccountToken: false   # ← no token file in the container at all
```

Or at the ServiceAccount level (applies to all pods using it):

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: web-app
automountServiceAccountToken: false
```

### AWS IRSA — ServiceAccount as an AWS identity (EKS)

On EKS, the same ServiceAccount token is also used to authenticate to AWS. This is **IRSA (IAM Roles for Service Accounts)** — the pod gets AWS credentials without any hardcoded access keys.

```
How IRSA works:
  1. EKS cluster has an OIDC provider registered with AWS
  2. ServiceAccount annotated with IAM role ARN
  3. Pod's SA token = OIDC web identity token
  4. AWS STS exchanges token for temporary IAM credentials
  5. boto3 / AWS SDK picks up credentials automatically (no config needed)

Your code:      s3 = boto3.client("s3")
SDK sees:       IRSA token → calls STS → gets temp credentials → signs request
```

```yaml
# Step 1: ServiceAccount with IAM role annotation
apiVersion: v1
kind: ServiceAccount
metadata:
  name: s3-reader
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/prod-s3-reader

---
# Step 2: Pod uses this ServiceAccount
spec:
  serviceAccountName: s3-reader
  containers:
  - name: app
    image: my-app:latest
    # No AWS credentials needed here — IRSA handles it
```

```python
# In the container — AWS SDK automatically uses IRSA credentials
import boto3

s3 = boto3.client("s3", region_name="us-east-1")
response = s3.list_objects_v2(Bucket="my-prod-bucket")

# What happens under the hood:
# boto3 → checks env vars (none) → checks ~/.aws (none)
# → finds IRSA web identity token at $AWS_WEB_IDENTITY_TOKEN_FILE
# → calls STS AssumeRoleWithWebIdentity
# → gets temp credentials → signs S3 request
```

```hcl
# Terraform creates the IRSA setup
module "irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "prod-s3-reader"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["production:s3-reader"]
      #                              ↑namespace  ↑ServiceAccount name
    }
  }

  role_policy_arns = {
    s3_read = aws_iam_policy.s3_read.arn
  }
}
```

---

## Projected Volumes: Merging Multiple Sources

A **projected volume** combines multiple volume sources into a single mount point. Common use: merge ServiceAccount token + ConfigMap + Secret into `/etc/config/`.

```yaml
volumes:
- name: app-config
  projected:
    sources:
    - configMap:
        name: app-config
    - secret:
        name: app-secrets
    - serviceAccountToken:
        path: token
        expirationSeconds: 3600
    - downwardAPI:
        items:
          - path: "pod-name"
            fieldRef:
              fieldPath: metadata.name
```

```
/etc/config/
├── DB_HOST           ← from configMap
├── LOG_LEVEL         ← from configMap
├── DB_PASSWORD       ← from secret
├── API_KEY           ← from secret
├── token             ← serviceAccountToken
└── pod-name          ← downwardAPI
```

---

## Common Pod Spec Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Liveness checks downstream dependency | DB outage cascades to pod restarts | Liveness checks local process only; readiness checks deps |
| No `startupProbe` for slow-starting app | Liveness kills app before it finishes starting | Add `startupProbe` with generous `failureThreshold` |
| No `preStop` sleep | In-flight requests fail during rolling update | Add `preStop: exec: sleep 5` |
| No resource limits | Node runs OOM, all pods killed together | Always set memory limits; set CPU limits for non-latency-critical apps |
| Init container runs migrations | Multiple pods migrate concurrently on rollout | Use a separate `Job` for migrations |
| Using `postStart` for initialization | Runs parallel to ENTRYPOINT — race condition | Use init containers for sequential setup |
| No `readinessProbe` | Pod receives traffic before app is ready | Always add readiness probe |
| `requests == 0` (BestEffort) | First to be evicted under node pressure | Always set requests |

---

## Navigation

**Related:**
- [Linux OS for Containers](../01_Linux/linux_os_for_containers.md) — OS primitives behind containers
- [Variable Flow: Terraform → Pod](../04_Terraform/04_variables_outputs/terraform_to_k8s_variable_flow.md) — Config injection
- [EKS](./eks.md) — Kubernetes cluster on AWS
- [ECS](./ecs.md) — Managed container service on AWS
