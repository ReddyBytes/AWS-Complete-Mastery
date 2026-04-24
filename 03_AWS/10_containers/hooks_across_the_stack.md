# Hooks Across the Stack — Kubernetes, Terraform, and Helm

A hook is a place where the system pauses and says: "before I proceed, does anyone have something to run?" Every layer of the infrastructure stack has hooks. Kubernetes has them at the container level and at the cluster admission level. Terraform has them at the resource lifecycle level. Helm has them at the chart deployment level. Understanding all four layers — and how they interact — is what gives you control over the full deployment pipeline.

---

## The Four Hook Layers

```
┌──────────────────────────────────────────────────────────────────────┐
│  LAYER 4: Helm Hooks                                                 │
│    pre-install, post-install, pre-upgrade, post-upgrade,             │
│    pre-delete, post-delete, pre-rollback                             │
│    → "run this Job/Pod at this point in the Helm release lifecycle"  │
├──────────────────────────────────────────────────────────────────────┤
│  LAYER 3: Kubernetes Admission Webhooks                              │
│    MutatingAdmissionWebhook, ValidatingAdmissionWebhook              │
│    → "intercept every object before it's written to etcd"            │
├──────────────────────────────────────────────────────────────────────┤
│  LAYER 2: Kubernetes Pod Lifecycle Hooks                             │
│    postStart, preStop                                                │
│    → "run this when a container starts or is about to stop"          │
├──────────────────────────────────────────────────────────────────────┤
│  LAYER 1: Terraform Lifecycle Meta-Arguments                         │
│    create_before_destroy, prevent_destroy,                           │
│    ignore_changes, replace_triggered_by                              │
│    → "control how Terraform creates, updates, and destroys resources"│
└──────────────────────────────────────────────────────────────────────┘
```

---

## Layer 1 — Terraform Lifecycle Meta-Arguments

Terraform's `lifecycle` block sits inside any resource and changes the default create → update → destroy behavior.

### create_before_destroy

By default, when Terraform needs to replace a resource (update that requires destroy + create), it destroys first, then creates. For production resources this causes downtime.

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.medium"

  lifecycle {
    create_before_destroy = true
    # ← New instance spins up FIRST
    # ← Traffic shifts to new instance
    # ← Old instance destroyed AFTER
  }
}
```

```
Default behavior:          create_before_destroy = true:
  existing running          new instance created (both running)
       ↓                          ↓
  existing destroyed         traffic shifts to new
       ↓                          ↓
  new created               old instance destroyed
  (downtime window)         (zero downtime)
```

**When to use:** Always set on EC2 instances, RDS, load balancers, any resource that handles traffic. Skip it for stateless config resources.

---

### prevent_destroy

Adds a safeguard: Terraform will refuse to destroy this resource, even if `terraform destroy` is run or if a plan would replace it. Protects production databases and S3 buckets from accidents.

```hcl
resource "aws_rds_cluster" "production" {
  cluster_identifier = "prod-postgres"
  engine             = "aurora-postgresql"

  lifecycle {
    prevent_destroy = true
    # ← terraform destroy will fail with an explicit error
    # ← forces you to manually remove the block before destroying
  }
}
```

```bash
# This fails with prevent_destroy = true:
terraform destroy

# Error: Instance cannot be destroyed
# Resource aws_rds_cluster.production has lifecycle.prevent_destroy set,
# but the plan calls for this resource to be destroyed.
```

**Important:** `prevent_destroy` only works during `terraform apply` and `terraform destroy`. If you remove the block from the config and then apply, the resource can be destroyed. It is a protection against accidents, not a hard lock.

---

### ignore_changes

Tells Terraform to ignore drift on specific attributes. Use when an external system legitimately modifies an attribute after Terraform creates the resource — and you do not want Terraform to reset it on every apply.

```hcl
resource "aws_autoscaling_group" "web" {
  name             = "web-asg"
  min_size         = 1
  max_size         = 10
  desired_capacity = 2

  lifecycle {
    ignore_changes = [
      desired_capacity,   # ← auto-scaling changes this; Terraform should not reset it
      tags,               # ← cost allocation team adds tags externally
    ]
  }
}

resource "aws_ecs_service" "app" {
  name          = "web-app"
  desired_count = 2

  lifecycle {
    ignore_changes = [
      desired_count,   # ← ECS auto-scaling manages this
    ]
  }
}
```

**Danger:** `ignore_changes = all` is a trap. It means Terraform never enforces the resource's config — you lose infrastructure-as-code guarantees. Use it for specific attributes only.

---

### replace_triggered_by

Forces a resource to be replaced when another resource or value changes — even if the resource itself has not changed. Introduced in Terraform 1.2.

```hcl
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = var.ami_id
  instance_type = "t3.medium"
  user_data     = base64encode(var.user_data_script)
}

resource "aws_autoscaling_group" "app" {
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  lifecycle {
    replace_triggered_by = [
      aws_launch_template.app   # ← if the launch template changes, replace the ASG
    ]
  }
}
```

**Use case:** Rolling replacement of EC2 instances when the AMI or user-data changes, without manually triggering a refresh.

---

### precondition and postcondition (Terraform 1.2+)

Not in the `lifecycle` block, but closely related — these are assertions that run before or after a resource is created.

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  lifecycle {
    precondition {
      condition     = contains(["t3.medium", "t3.large", "m5.large"], var.instance_type)
      error_message = "instance_type must be t3.medium, t3.large, or m5.large for production."
    }
  }
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint

  lifecycle {
    postcondition {
      condition     = length(self.value) > 0
      error_message = "DB endpoint is empty — RDS creation may have failed silently."
    }
  }
}
```

---

## Layer 2 — Kubernetes Pod Lifecycle Hooks

Every container in a pod can define two hooks that fire at key moments.

### postStart

Fires immediately after the container's entrypoint starts. Runs **in parallel** with the entrypoint — there is no guarantee the entrypoint has finished starting when postStart fires.

```
Container created
  ├── entrypoint starts (your app)   } both fire at the same time
  └── postStart hook fires           }

If postStart fails → container is killed and restarted.
Container is not marked Ready until postStart completes.
```

```yaml
lifecycle:
  postStart:
    exec:
      command:
        - /bin/sh
        - -c
        - |
          # Register with service mesh
          curl -X POST http://localhost:15000/register \
            -d "{\"service\": \"$POD_NAME\", \"ip\": \"$POD_IP\"}"
```

```yaml
lifecycle:
  postStart:
    httpGet:
      path: /internal/warmup    # trigger cache warmup endpoint
      port: 8080
```

**What NOT to do in postStart:**
- Do not use it for initialization that the app depends on (race condition with entrypoint)
- Do not run long operations — pod stays in `ContainerCreating` state until it completes
- Use init containers for guaranteed sequential setup

---

### preStop

Fires before SIGTERM is sent. Blocks SIGTERM until the hook completes (or times out at `terminationGracePeriodSeconds`).

```
Pod stop requested
  ├── preStop hook fires
  │     (runs to completion — or until terminationGracePeriodSeconds)
  ├── SIGTERM sent to container
  ├── terminationGracePeriodSeconds countdown begins
  └── SIGKILL if container still running
```

```yaml
lifecycle:
  preStop:
    exec:
      command:
        - /bin/sh
        - -c
        - |
          # Pattern 1: Sleep to let load balancer drain connections
          sleep 5

          # Pattern 2: Notify app to enter drain mode
          curl -X POST http://localhost:8080/drain

          # Pattern 3: Deregister from service mesh or discovery
          curl -X DELETE http://consul:8500/v1/agent/service/$POD_NAME
```

**The timing math:**

```
terminationGracePeriodSeconds = 30 (default)

Actual shutdown budget:
  preStop hook time = 5s
  + app graceful shutdown time = 20s
  = 25s total needed

Set terminationGracePeriodSeconds to at least preStop + app shutdown + buffer
```

```yaml
spec:
  terminationGracePeriodSeconds: 60   # ← set this explicitly for slow-shutting apps
  containers:
  - name: app
    lifecycle:
      preStop:
        exec:
          command: ["sleep", "10"]
```

---

### Full lifecycle hook example with all signals

```python
# app.py — complete lifecycle handling

import os
import signal
import sys
import threading
from flask import Flask

app = Flask(__name__)
shutdown_event = threading.Event()

@app.route("/healthz")
def liveness():
    return {"status": "ok"}, 200

@app.route("/readyz")
def readiness():
    if shutdown_event.is_set():
        return {"status": "draining"}, 503   # ← removes from LB during shutdown
    return {"status": "ready"}, 200

@app.route("/drain")
def drain():
    """Called by preStop hook to begin graceful drain"""
    shutdown_event.set()
    return {"status": "draining"}, 200

def handle_sigterm(signum, frame):
    print("SIGTERM received — beginning graceful shutdown")
    shutdown_event.set()
    # Finish processing in-flight requests
    # Flask will stop accepting new requests
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_sigterm)
signal.signal(signal.SIGINT, handle_sigterm)
```

---

## Layer 3 — Kubernetes Admission Webhooks

Admission webhooks are the most powerful and least understood hook in Kubernetes. Every time you `kubectl apply` a resource, before it is written to etcd, the request passes through an admission chain. Webhooks are HTTP servers that can intercept this chain.

```
kubectl apply -f deployment.yaml
        │
        ▼
  kube-apiserver
        │
        ▼
  Authentication (who are you?)
        │
        ▼
  Authorization (are you allowed?)
        │
        ▼
  Mutating Admission Webhooks  ← can MODIFY the object
    [webhook 1: Istio sidecar injector]
    [webhook 2: your custom mutating webhook]
        │
        ▼
  Object Schema Validation
        │
        ▼
  Validating Admission Webhooks  ← can ACCEPT or REJECT the object
    [webhook 3: OPA/Kyverno policy enforcement]
    [webhook 4: your custom validating webhook]
        │
        ▼
  Written to etcd  ✓
```

### Mutating Webhooks — modify objects on the way in

The most famous example: **Istio sidecar injection**. You apply a deployment with one container. The Istio mutating webhook intercepts it and adds the Envoy sidecar container automatically. You never write the sidecar yourself.

```yaml
# What you apply:
spec:
  containers:
  - name: app
    image: my-app:latest

# What actually gets written to etcd (after Istio's mutating webhook):
spec:
  containers:
  - name: app
    image: my-app:latest
  - name: istio-proxy             # ← injected by mutating webhook
    image: docker.io/istio/proxyv2:1.20.0
    ...
  initContainers:
  - name: istio-init              # ← also injected
    image: docker.io/istio/proxyv2:1.20.0
    ...
```

The webhook is triggered by a label on the namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    istio-injection: enabled   # ← this label triggers the Istio mutating webhook
```

### Validating Webhooks — accept or reject objects

**OPA Gatekeeper** and **Kyverno** implement policy-as-code using validating webhooks. Common policies enforced this way:

```
✗ Reject pods with no resource limits
✗ Reject images from untrusted registries
✗ Reject containers running as root (UID 0)
✗ Reject deployments with no readiness probe
✓ Require specific labels on all deployments
✓ Require image tags to be pinned (not "latest")
```

```yaml
# Kyverno policy example — blocks "latest" image tag
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce   # ← Audit = log only, Enforce = block
  rules:
  - name: require-image-tag
    match:
      any:
      - resources:
          kinds: [Pod]
    validate:
      message: "Image tag 'latest' is not allowed. Pin to a specific version."
      pattern:
        spec:
          containers:
          - image: "!*:latest"
```

```bash
# Apply a pod with :latest image — blocked by Kyverno
kubectl apply -f pod-with-latest.yaml
Error: admission webhook "validate.kyverno.svc" denied the request:
  Image tag 'latest' is not allowed.
```

### Writing your own admission webhook

An admission webhook is an HTTP server you deploy that Kubernetes calls with a JSON `AdmissionReview` request.

```python
# Minimal mutating webhook — adds a default label to every pod
from flask import Flask, request, jsonify
import base64, json

app = Flask(__name__)

@app.route("/mutate", methods=["POST"])
def mutate():
    admission_review = request.json
    pod = admission_review["request"]["object"]

    # Build a JSON patch to add a label
    patch = [
        {
            "op": "add",
            "path": "/metadata/labels/injected-by",
            "value": "my-webhook"
        }
    ]

    patch_b64 = base64.b64encode(json.dumps(patch).encode()).decode()

    return jsonify({
        "apiVersion": "admission.k8s.io/v1",
        "kind": "AdmissionReview",
        "response": {
            "uid": admission_review["request"]["uid"],
            "allowed": True,
            "patchType": "JSONPatch",
            "patch": patch_b64
        }
    })
```

The webhook is registered with a `MutatingWebhookConfiguration`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: my-webhook
webhooks:
- name: my-webhook.example.com
  clientConfig:
    service:
      name: my-webhook-service
      namespace: default
      path: "/mutate"
    caBundle: <base64-encoded-ca-cert>   # ← must be TLS
  rules:
  - apiGroups:   [""]
    apiVersions: ["v1"]
    resources:   ["pods"]
    operations:  ["CREATE"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
  failurePolicy: Fail    # ← Fail = reject if webhook unavailable; Ignore = allow through
```

**Critical:** Admission webhooks must use TLS. If your webhook server is down and `failurePolicy: Fail`, nothing can be deployed to that cluster. Always run webhook servers with high availability.

---

## Layer 4 — Helm Hooks

Helm hooks attach Kubernetes Jobs or Pods to specific points in the Helm release lifecycle.

```
helm install / helm upgrade
        │
        ▼
  pre-install / pre-upgrade hooks run (Jobs must complete ✓)
        │
        ▼
  Kubernetes resources applied (Deployments, Services, etc.)
        │
        ▼
  post-install / post-upgrade hooks run
        │
        ▼
  Release marked DEPLOYED

helm uninstall
        │
        ▼
  pre-delete hooks run
        │
        ▼
  Resources deleted
        │
        ▼
  post-delete hooks run
```

### Database migration hook (pre-upgrade)

The canonical use case: run migrations before new pods roll out.

```yaml
# charts/my-app/templates/migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ .Release.Name }}-migration"
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install    # ← fires before resources are applied
    "helm.sh/hook-weight": "-5"                 # ← lower = runs first (among hooks)
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
    #  ↑ delete old job before creating new one, and delete after success
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        command: ["python", "manage.py", "migrate", "--no-input"]
        env:
          - name: DATABASE_URL
            valueFrom:
              secretKeyRef:
                name: app-secrets
                key: DATABASE_URL
```

### Smoke test hook (post-upgrade)

```yaml
# charts/my-app/templates/smoke-test.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ .Release.Name }}-smoke-test"
  annotations:
    "helm.sh/hook": post-upgrade,post-install
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: smoke-test
        image: curlimages/curl:latest
        command:
          - sh
          - -c
          - |
            # Wait for service, run basic health check
            sleep 10
            curl -f http://{{ .Release.Name }}-service/healthz || exit 1
            echo "Smoke test passed"
```

### Hook weight — ordering multiple hooks

```yaml
# Runs first (weight -10)
annotations:
  "helm.sh/hook": pre-upgrade
  "helm.sh/hook-weight": "-10"   # ← backup database

# Runs second (weight -5)
annotations:
  "helm.sh/hook": pre-upgrade
  "helm.sh/hook-weight": "-5"    # ← run migrations

# Runs third (weight 0)
annotations:
  "helm.sh/hook": pre-upgrade
  "helm.sh/hook-weight": "0"     # ← seed reference data
```

### Hook delete policy options

| Policy | Meaning |
|---|---|
| `before-hook-creation` | Delete previous hook resource before creating new one |
| `hook-succeeded` | Delete after hook completes successfully |
| `hook-failed` | Delete after hook fails (use for cleanup) |

Default if unset: resources are never deleted — old job resources pile up.

---

## How the Layers Interact in a Real Deployment

```
helm upgrade my-app ./charts/my-app
    │
    ├── [Helm] pre-upgrade hook fires
    │     └── migration Job runs → alembic upgrade head ✓
    │
    ├── [Terraform] has already created:
    │     └── kubernetes_config_map, kubernetes_secret, kubernetes_deployment
    │
    ├── [Kubernetes API] receives new Deployment manifest
    │     │
    │     ├── [Admission Webhook - Kyverno] validates:
    │     │     ✓ image tag is not :latest
    │     │     ✓ resource limits are set
    │     │     ✓ container is not running as root
    │     │
    │     └── [Admission Webhook - Istio] mutates:
    │           → injects istio-proxy sidecar
    │           → injects istio-init init container
    │
    ├── [Kubernetes] rolling update begins
    │     ├── new pod starts
    │     │     ├── init containers run (wait-for-db, render-config)
    │     │     ├── app container starts
    │     │     ├── [Pod Hook] postStart fires → warm cache
    │     │     └── readiness probe passes → pod added to Service
    │     │
    │     └── old pod stops
    │           ├── [Pod Hook] preStop fires → sleep 5, drain
    │           ├── SIGTERM sent → app finishes in-flight requests
    │           └── SIGKILL after grace period
    │
    └── [Helm] post-upgrade hook fires
          └── smoke-test Job runs → curl /healthz ✓
              helm release marked DEPLOYED
```

---

## Common Mistakes Across All Hook Layers

| Layer | Mistake | Consequence | Fix |
|---|---|---|---|
| Terraform | `create_before_destroy` not set on DB | Destroy + recreate = data loss window | Set on all stateful resources |
| Terraform | `ignore_changes = all` | Terraform stops enforcing config | List specific attributes only |
| Terraform | No `prevent_destroy` on production DB | `terraform destroy` wipes prod DB | Add to all production databases |
| K8s lifecycle | No `preStop` sleep | In-flight requests fail on rolling update | Add `sleep 5` minimum |
| K8s lifecycle | `postStart` used for init logic | Race condition with entrypoint | Use init containers instead |
| K8s lifecycle | Grace period too short | App killed mid-request | Set `terminationGracePeriodSeconds` ≥ preStop + shutdown time |
| Admission webhook | `failurePolicy: Fail` with no HA | Webhook outage = nothing deploys | Run 2+ replicas, set PodDisruptionBudget |
| Admission webhook | Webhook on its own namespace | Bootstrapping deadlock | Exclude webhook namespace from its own rules |
| Helm hook | No `hook-delete-policy` | Old Job resources pile up | Always set `before-hook-creation,hook-succeeded` |
| Helm hook | Migration in pre-upgrade | Runs even if upgrade is dry-run | Use `--dry-run` awareness or separate migration pipeline |

---

## Navigation

**Related:**
- [Pod Runtime Patterns](./k8s_pod_runtime_patterns.md) — Init containers, sidecars, health probes, downward API
- [Linux OS for Containers](../../01_Linux/linux_os_for_containers.md) — Signals, PID 1, cgroups
- [Variable Flow: Terraform → Pod](../../04_Terraform/04_variables_outputs/terraform_to_k8s_variable_flow.md) — ConfigMaps, Secrets, env vars
- [Terraform Variables](../../04_Terraform/04_variables_outputs/variables.md) — Terraform variable fundamentals
