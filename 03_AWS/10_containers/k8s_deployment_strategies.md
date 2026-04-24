# Kubernetes Deployment Strategies

A field guide to rolling updates, blue/green, canary, and progressive delivery — from first principles to production patterns.

---

## 1. How Kubernetes Deployments Work Under the Hood

Imagine a building manager whose only job is to walk the hallways and count doors. He has a clipboard with the number of rooms that should be occupied (desired state) and a counter showing how many are actually occupied (current state). Whenever those two numbers differ, he acts — opens a new room, closes one, or swaps tenants. He never sleeps, never gets bored, and never gives up until the numbers match.

That building manager is the **Deployment controller**, a reconciliation loop running inside the Kubernetes control plane. It owns a chain of objects:

```
Deployment
    └── ReplicaSet (versioned snapshot of the Pod template)
            └── Pod  Pod  Pod  ...
```

A **Deployment** is not a set of Pods. It is a description of intent — "run 3 copies of this container image." To fulfil that intent, it creates a **ReplicaSet**, which is the object that actually owns and counts Pods. When you change the Deployment's Pod template (new image, new env var, etc.), the controller does not modify the existing ReplicaSet. It creates a brand-new ReplicaSet for the new template and orchestrates traffic between the old and new sets according to the configured strategy.

```
                   kubectl apply (new image)
                           |
                           v
             +-------------+--------------+
             |         Deployment         |
             |   desired: 3 pods v2.0     |
             +--+----------------------+--+
                |                      |
                v                      v
     +-----------+------+   +----------+-------+
     |  ReplicaSet v1.0 |   |  ReplicaSet v2.0 |
     |  replicas: 0→3   |   |  replicas: 3→0   |
     +------------------+   +------------------+
          Pod Pod Pod              Pod Pod Pod
          (old)                    (new)
```

**Desired state** is the spec you write in YAML. The **observed state** is what the cluster's etcd database reflects right now. The reconciliation loop closes the gap between them. This loop is idempotent — you can run `kubectl apply` a hundred times with the same file and nothing changes if the state already matches.

The **controller manager** process runs this loop (along with many others). It watches for events from the API server, computes a diff, and issues create/delete calls to move actual state toward desired state.

---

## 2. RollingUpdate Strategy (The Default)

Think of replacing airline seats during a flight. You cannot swap every seat at once — passengers would have nowhere to sit. So the airline replaces one row at a time: new seat goes in, old seat comes out, never leaving more rows empty than the plane can afford, never overcrowding more rows than the overhead bins allow. The flight lands on time.

Kubernetes' **RollingUpdate** strategy works exactly this way. It replaces Pods gradually, controlled by two dials.

### maxSurge and maxUnavailable

**`maxSurge`** — how many extra Pods above the desired count are allowed during the rollout. This is the "new seat goes in before old one comes out" allowance. Setting it higher speeds up the rollout but costs more resources temporarily.

**`maxUnavailable`** — how many Pods below the desired count are acceptable during the rollout. This is the "acceptable empty seats" tolerance. Set it to 0 for zero-downtime; allow a value > 0 to speed things up when you can tolerate some capacity reduction.

Both accept absolute numbers (`2`) or percentages (`25%`). They cannot both be zero at the same time.

```
maxSurge=1, maxUnavailable=0, desired=3:

  Time 0:  [v1] [v1] [v1]               3 old pods running
  Time 1:  [v1] [v1] [v1] [v2]          surge: 1 new added (total=4)
  Time 2:  [v1] [v1] [v2]               1 old terminated after new is Ready
  Time 3:  [v1] [v1] [v2] [v2]          surge again
  Time 4:  [v1] [v2] [v2]               another old gone
  Time 5:  [v1] [v2] [v2] [v2]          last surge
  Time 6:  [v2] [v2] [v2]               done, old ReplicaSet at 0
```

### YAML Spec

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2          # ← allow up to 8 pods during rollout (6+2)
      maxUnavailable: 0    # ← never drop below 6 ready pods (zero-downtime)
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      containers:
      - name: api
        image: myrepo/api-server:v2.1.0
        readinessProbe:              # ← REQUIRED for safe rolling updates
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 3
          failureThreshold: 3       # ← 3 failures → pod stays NotReady → rollout stalls
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 10
```

### Tuning for Zero-Downtime vs Speed

| Goal | maxSurge | maxUnavailable | Effect |
|------|----------|----------------|--------|
| Zero-downtime | 1–25% | 0 | Slowest; always at full capacity |
| Balanced | 25% | 25% | Default behavior |
| Fastest rollout | 100% | 100% | Essentially Recreate; brief downtime possible |
| Resource-constrained | 0 | 1 | No extra nodes needed; always 1 pod down |

### When a Rolling Update Goes Wrong

When a readiness probe fails during rollout, Kubernetes stalls. The new Pod never reaches `Ready` state, so the controller stops replacing old Pods — old Pods stay alive. This is the safety net.

```
Rollout stalled:

  [v1-Ready] [v1-Ready] [v1-Ready] [v2-NotReady]
                                        ^
                               readiness probe failing
                               rollout frozen here
                               old pods still serving traffic
```

The rollout will never complete (or time out after `progressDeadlineSeconds`, default 600s). You can watch this with `kubectl rollout status` — it will block and show the stall. The fix is to investigate the failing Pod's logs, then either fix the image or roll back.

### kubectl Rollout Commands

```bash
# Watch rollout progress in real time (blocks until complete or failed)
kubectl rollout status deployment/api-server

# Show rollout history (--record flag on apply populates CHANGE-CAUSE)
kubectl rollout history deployment/api-server

# Inspect a specific revision
kubectl rollout history deployment/api-server --revision=3

# Undo to previous revision
kubectl rollout undo deployment/api-server

# Undo to a specific revision
kubectl rollout undo deployment/api-server --to-revision=2

# Pause mid-rollout (useful for manual canary gating)
kubectl rollout pause deployment/api-server

# Resume after inspection
kubectl rollout resume deployment/api-server

# Force a restart of all pods (new rollout with same image — picks up new secrets/configmaps)
kubectl rollout restart deployment/api-server
```

---

## 3. Recreate Strategy

Sometimes you do not want a gradual handoff. Imagine replacing every checkout terminal in a store during a system migration where the old software and new software cannot talk to the same database schema at the same time. Running both versions together, even briefly, corrupts data. The only safe move is: close all registers, upgrade the system, reopen. Brief downtime is the explicit cost of correctness.

**Recreate** is that strategy. Kubernetes terminates all existing Pods before starting any new ones. There will be a gap — a period with zero running Pods.

```
Recreate timeline:

  Time 0:  [v1] [v1] [v1]   all old pods running
  Time 1:  [ ]  [ ]  [ ]    all terminated (downtime begins)
  Time 2:  [v2] [v2] [v2]   all new pods starting
  Time 3:  [v2] [v2] [v2]   ready (downtime ends)
```

### When to Use Recreate

- Single-instance stateful apps that cannot safely run two versions concurrently
- Breaking database schema changes that require the old app to be fully stopped
- Development environments where downtime does not matter
- Applications that hold a singleton lock (e.g., a scheduler that must be the only instance)

### YAML Spec

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: schema-migrator
spec:
  replicas: 1
  strategy:
    type: Recreate    # ← no rollingUpdate block needed; terminates all then starts all
  selector:
    matchLabels:
      app: schema-migrator
  template:
    metadata:
      labels:
        app: schema-migrator
    spec:
      containers:
      - name: app
        image: myrepo/app:v3.0.0
```

The deliberate downtime tradeoff is a feature, not a bug. It gives you a clean slate and removes any possibility of two versions competing for the same database row.

---

## 4. Blue/Green Deployment

Hotel analogy: you are hosting a VIP conference in Room 101. The next conference is tomorrow and you want to move to the upgraded Room 201 — nicer projector, faster WiFi. The hotel does not evict the current guests and start renovating mid-conference. Instead, they prepare Room 201 completely while 101 is still occupied. When 201 is ready and inspected, they hand the conference organiser a new key card and deactivate the old one. If something is wrong with 201, they hand back the 101 key card instantly.

That key-card swap is the **Service selector**. Kubernetes Services route traffic based on **label selectors**. Blue/Green works by keeping two identical Deployments — one labeled `version: blue`, one `version: green` — and switching the Service selector between them.

```
                    ┌─────────────────────────────────────┐
                    │           Kubernetes Service         │
                    │   selector: app=web, version=blue    │ ← change this to green
                    └────────────────┬────────────────────┘
                                     │ traffic
                    ┌────────────────▼──────────────────────────────┐
                    │                                               │
          ┌─────────▼─────────┐                  ┌─────────────────┐
          │  Deployment blue  │                  │ Deployment green │
          │  version: blue    │ ← live           │  version: green  │ ← standby
          │  [Pod] [Pod] [Pod]│                  │  [Pod] [Pod] [Pod]│
          └───────────────────┘                  └──────────────────┘
                                                  fully running, not receiving traffic
```

### Implementation: Two Deployments + Service Selector Swap

**Blue Deployment (live)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      version: blue          # ← selector must match pod labels exactly
  template:
    metadata:
      labels:
        app: web
        version: blue
    spec:
      containers:
      - name: web
        image: myrepo/web:v1.0.0
```

**Green Deployment (new version, prepared in advance)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      version: green
  template:
    metadata:
      labels:
        app: web
        version: green
    spec:
      containers:
      - name: web
        image: myrepo/web:v2.0.0
```

**Service — starts pointing at blue**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector:
    app: web
    version: blue            # ← this single line controls all traffic routing
  ports:
  - port: 80
    targetPort: 8080
```

**The switch — edit the Service selector to point at green**

```bash
kubectl patch service web-svc \
  -p '{"spec":{"selector":{"app":"web","version":"green"}}}'
```

Traffic now flows to green instantly. Rollback is equally instant:

```bash
kubectl patch service web-svc \
  -p '{"spec":{"selector":{"app":"web","version":"blue"}}}'
```

### Terraform Implementation

```hcl
resource "kubernetes_service" "web" {
  metadata {
    name      = "web-svc"
    namespace = "default"
  }
  spec {
    selector = {
      app     = "web"
      version = var.active_slot   # ← "blue" or "green" controlled by variable
    }
    port {
      port        = 80
      target_port = 8080
    }
    type = "ClusterIP"
  }
}

variable "active_slot" {
  description = "Which slot is live: blue or green"
  type        = string
  default     = "blue"
}
```

Switch by running `terraform apply -var="active_slot=green"`.

### Tradeoffs

| Aspect | Detail |
|--------|--------|
| Instant rollback | One command; no re-image needed |
| Zero downtime | Switch is atomic at the Service level |
| Resource cost | 2x node capacity required at all times (or during deployment) |
| Test in prod | Green cluster gets real smoke tests before switch |
| Database migrations | Still risky if schema is not backward-compatible |

---

## 5. Canary Deployment

The term comes from coal mining. Miners carried canary birds into tunnels. Canaries are more sensitive to carbon monoxide than humans — if the canary stopped singing, miners knew to evacuate. The canary absorbed risk that would otherwise fall on the entire workforce.

In software, a **canary deployment** sends a small percentage of real user traffic to the new version before committing everyone. If errors spike, latency jumps, or crash rates climb, you pull back — only a fraction of users experienced the problem.

### Two-Deployment Approach with Replica Ratio

Kubernetes has no native percentage-based traffic splitting at the Pod level. But if all Pods share the same Service selector label, the Service load-balances across all of them by replica count. Ten Pods total, one running the new version = roughly 10% canary traffic.

```
Service selector: app=web   (matches ALL pods regardless of track label)

  [stable] [stable] [stable] [stable] [stable]
  [stable] [stable] [stable] [stable] [canary]
                                           ^
                              ~10% of traffic hits here
```

**Stable Deployment (9 replicas)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-stable
spec:
  replicas: 9                  # ← 9 of 10 total pods
  selector:
    matchLabels:
      app: web
      track: stable
  template:
    metadata:
      labels:
        app: web               # ← MUST match Service selector
        track: stable
    spec:
      containers:
      - name: web
        image: myrepo/web:v1.0.0
```

**Canary Deployment (1 replica)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-canary
spec:
  replicas: 1                  # ← 1 of 10 total pods = ~10% traffic
  selector:
    matchLabels:
      app: web
      track: canary
  template:
    metadata:
      labels:
        app: web               # ← same Service selector label as stable
        track: canary
    spec:
      containers:
      - name: web
        image: myrepo/web:v2.0.0   # ← new version
```

**Service — routes to all Pods with `app: web`**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  selector:
    app: web                   # ← intentionally omits 'track' — hits both stable and canary
  ports:
  - port: 80
    targetPort: 8080
```

### Ingress-Based Canary with nginx-ingress

For precise percentage control (not dependent on replica math), nginx-ingress supports weight annotations:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-canary-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"           # ← marks this as canary ingress
    nginx.ingress.kubernetes.io/canary-weight: "10"      # ← 10% of requests go here
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-canary-svc    # ← canary version's dedicated Service
            port:
              number: 80
```

The stable Ingress (without annotations) receives the remaining 90%. Changing `canary-weight` does not require redeployment — edit the annotation, nginx-ingress picks it up.

### Graduated Rollout: 5% → 25% → 100%

```
Phase 1 — Smoke test:
  Canary replicas: 1, Stable replicas: 19  → ~5% traffic
  Monitor: error rate, p99 latency, business metrics (15-30 min)

Phase 2 — Expand if healthy:
  Canary replicas: 5, Stable replicas: 15  → ~25% traffic
  Monitor: same metrics (1-2 hours)

Phase 3 — Full promotion:
  Scale canary to 20, scale stable to 0
  OR: update stable Deployment image, delete canary Deployment
  → 100% on new version
```

Rollback at any phase: scale canary to 0, traffic reverts entirely to stable.

---

## 6. Progressive Delivery Tools

Native Kubernetes gives you the raw building blocks — two Deployments, replica ratios, Ingress weights. But coordinating those manually (watch metrics, update replicas, decide pass/fail) is operator work. **Progressive delivery tools** automate that loop.

Think of the difference between manually adjusting a car's throttle to maintain highway speed versus using cruise control. Same physics, same car — cruise control just closes the feedback loop for you.

### Argo Rollouts

**Argo Rollouts** adds a `Rollout` **Custom Resource Definition (CRD)** that replaces the Deployment for canary and blue/green use cases. It integrates with metrics providers (Prometheus, Datadog, New Relic) to automatically promote or abort based on analysis results.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-rollout
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 5          # ← step 1: send 5% to canary
      - pause: {duration: 5m} # ← wait 5 minutes
      - setWeight: 25         # ← step 2: increase to 25%
      - analysis:             # ← automated metric check before proceeding
          templates:
          - templateName: success-rate
      - setWeight: 100        # ← step 3: full promotion if analysis passed
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: myrepo/web:v2.0.0
```

The `analysis` step queries a metric (e.g., HTTP 5xx rate) and aborts the rollout automatically if the threshold is breached — no human needed at 3am.

### Flagger

**Flagger** watches a standard Deployment and runs canary analysis automatically when it detects a change. It integrates with service meshes (Istio, Linkerd) for traffic splitting and with metrics backends for automated promotion gates. Flagger is operator-driven: you deploy normally, Flagger intercepts and controls the rollout.

### When to Reach for These Tools vs Native Approach

| Situation | Recommendation |
|-----------|----------------|
| Simple rollout, no traffic analysis | Native RollingUpdate |
| Blue/green with manual switch | Two Deployments + Service patch |
| Canary with rough percentage | Replica ratio approach |
| Canary with precise % + automated metric gates | Argo Rollouts or Flagger |
| Large team, GitOps workflow already using Argo CD | Argo Rollouts (native integration) |
| Service mesh already in place | Flagger |

---

## 7. kubectl Rollout Commands — Full Cheatsheet

```bash
# --- STATUS ---
# Watch until rollout completes (exits 0) or fails (exits 1)
kubectl rollout status deployment/<name>

# Check status of a specific namespace
kubectl rollout status deployment/<name> -n <namespace>

# --- HISTORY ---
# List all recorded revisions
kubectl rollout history deployment/<name>

# Show full pod template for a specific revision
kubectl rollout history deployment/<name> --revision=<n>

# --- UNDO ---
# Roll back to the immediately previous revision
kubectl rollout undo deployment/<name>

# Roll back to a specific revision number
kubectl rollout undo deployment/<name> --to-revision=<n>

# --- PAUSE / RESUME ---
# Freeze an in-progress rollout (new pods stop being created)
kubectl rollout pause deployment/<name>

# Resume a paused rollout
kubectl rollout resume deployment/<name>

# --- RESTART ---
# Force a fresh rollout with the existing spec (rotates pods)
# Useful to pick up new Secret/ConfigMap values without changing the image
kubectl rollout restart deployment/<name>

# --- OTHER OBJECT TYPES ---
# Rollout commands also work on DaemonSets and StatefulSets
kubectl rollout status daemonset/<name>
kubectl rollout undo statefulset/<name>
```

---

## 8. Decision Table — Which Strategy for Which Situation

| Situation | Recommended Strategy | Reason |
|-----------|---------------------|--------|
| Stateless web service, no schema change | RollingUpdate | Gradual, no extra cost, built-in |
| Must maintain full capacity at all times | RollingUpdate (maxUnavailable=0) | Surge absorbs replacement cost |
| Breaking DB schema change | Recreate | Prevents two-version DB conflict |
| Single-replica stateful app | Recreate | Rolling makes no sense with 1 pod |
| Need instant, atomic rollback | Blue/Green | Service switch is instantaneous |
| Compliance requires zero traffic to new version until approved | Blue/Green | Green receives no traffic until manual switch |
| New feature validation with real users | Canary | Small blast radius, real signal |
| Performance regression detection | Canary | Baseline comparison at scale |
| Automated metric-gated promotion | Argo Rollouts / Flagger | Closes feedback loop automatically |
| Dev/staging environment | Recreate or RollingUpdate | Simplicity over sophistication |

---

## 9. Common Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| No readiness probe on RollingUpdate | Bad pods receive traffic during rollout | Add `readinessProbe` to every container |
| maxSurge and maxUnavailable both set to 0 | Deployment validation error — rejected by API server | Always have at least one non-zero |
| Blue/Green selector label collision | Both blue and green pods receive traffic simultaneously | Ensure Service selector includes the `version` label |
| Canary with only 1 replica total (0 stable, 1 canary) | Not actually a canary — all traffic goes to new version | Keep stable running until canary is validated |
| `kubectl rollout history` shows no CHANGE-CAUSE | History is empty, hard to audit | Use `kubectl annotate` or `--record` (deprecated but still works) |
| Not setting `progressDeadlineSeconds` | Stalled rollout hangs indefinitely | Set to a reasonable value (e.g., 300s) with alerting on failure |
| Blue/Green with stateful sessions | Users mid-session get routed to new version after switch | Use sticky sessions or drain connections before switching |
| Deleting old ReplicaSet immediately after rollout | Lose ability to `kubectl rollout undo` | Leave old ReplicaSets in place (`.spec.revisionHistoryLimit` controls retention) |
| Canary replica ratio with very low replica count | 1/3 = 33%, not 10% — math is coarse | Use Ingress weights or Argo Rollouts for precise control |
| Forgetting `imagePullPolicy: Always` on `latest` tag | Nodes cache old `latest` image; rollout appears to succeed but runs old code | Use versioned tags; never deploy `latest` to production |

---

## Navigation

- Previous: [k8s_pod_runtime_patterns.md](./k8s_pod_runtime_patterns.md)
- Related: [hooks_across_the_stack.md](./hooks_across_the_stack.md)
- Related: [eks.md](./eks.md)
- Related: [linux_os_for_containers.md](../../../02_Linux/linux_os_for_containers.md)
- Back to: [README](../../README.md)
