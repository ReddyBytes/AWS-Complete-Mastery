# Kubernetes Network Policies — Industry Guide

Picture a large open-plan office where every desk is a pod. By default, anyone can walk up to any desk and start a conversation. There are no badges, no locked doors, no reception desks. If someone compromises one desk — a junior contractor, a visiting vendor — they can roam the entire floor. Kubernetes Network Policies are the locked doors, badge readers, and security checkpoints you add to that office. You decide exactly which desks can talk to which, and everyone else gets turned away at the door.

---

## 1. Why Network Policies

Kubernetes networking has a flat default: every pod can reach every other pod across every namespace, on any port. This makes development frictionless but production dangerous.

```
┌─────────────────────────────────────────────────────────────┐
│  DEFAULT CLUSTER NETWORKING (no policies)                   │
│                                                             │
│  namespace: frontend          namespace: backend            │
│  ┌──────────┐                 ┌──────────┐                  │
│  │ web pod  │────────────────▶│ api pod  │                  │
│  └──────────┘                 └──────────┘                  │
│       │                            │                        │
│       │           any to any       │                        │
│       ▼                            ▼                        │
│  ┌──────────┐                 ┌──────────┐                  │
│  │ db pod   │◀───────────────▶│ cache pod│                  │
│  └──────────┘                 └──────────┘                  │
│                                                             │
│  Every arrow represents unrestricted traffic. A            │
│  compromised web pod can query the database directly.       │
└─────────────────────────────────────────────────────────────┘
```

The threat model is simple: lateral movement. An attacker who compromises one pod should not automatically gain access to your database, secrets store, or monitoring infrastructure. Network Policies enforce **least-privilege networking** at the pod level.

---

## 2. How Network Policies Work Under the Hood

Network Policies are a Kubernetes API resource — but the enforcement is done entirely by the **CNI plugin** (Container Network Interface). Kubernetes itself just stores the policy in etcd. The CNI plugin watches those objects and programs actual firewall rules into the Linux kernel on each node.

```
┌────────────────────────────────────────────────────────────────┐
│  NETWORK POLICY ENFORCEMENT CHAIN                              │
│                                                                │
│  You apply YAML                                                │
│       │                                                        │
│       ▼                                                        │
│  kube-apiserver stores NetworkPolicy in etcd                   │
│       │                                                        │
│       ▼                                                        │
│  CNI plugin (Calico / Cilium / WeaveNet) watches etcd         │
│       │                                                        │
│       ▼                                                        │
│  CNI agent on each node programs iptables / eBPF rules        │
│       │                                                        │
│       ▼                                                        │
│  Linux kernel drops or allows packets at the network layer     │
└────────────────────────────────────────────────────────────────┘
```

Critical fact: **if your CNI plugin does not support Network Policies, the YAML is silently ignored.** Flannel, for example, does not implement Network Policies. Applying a deny-all policy on a Flannel cluster does nothing — all traffic still flows. This is a common production mistake.

CNI plugins that enforce Network Policies:

```
┌──────────────┬────────────────────────────────────────────────┐
│ Plugin       │ Notes                                          │
├──────────────┼────────────────────────────────────────────────┤
│ Calico       │ iptables or eBPF. Most widely deployed.        │
│ Cilium       │ eBPF-native. Richer policy model (L7 aware).   │
│ WeaveNet     │ iptables. Simpler but less maintained.         │
│ Flannel      │ Does NOT enforce NetworkPolicy. Avoid for prod.│
└──────────────┴────────────────────────────────────────────────┘
```

### The Additive Model

Network Policies are **additive and selector-scoped**. The rules are:

- A pod with no matching NetworkPolicy: all traffic allowed (allow-all default)
- A pod selected by at least one NetworkPolicy: deny all traffic **not explicitly allowed** by any matching policy
- Multiple policies match the same pod: their rules are unioned (combined with OR)

```
┌──────────────────────────────────────────────────────────────┐
│  ADDITIVE MODEL                                              │
│                                                              │
│  Policy A: allow ingress from frontend pods                  │
│  Policy B: allow ingress from monitoring namespace           │
│                                                              │
│  Pod selected by A and B can receive traffic from:           │
│    - frontend pods (via A)                                   │
│    - monitoring namespace pods (via B)                       │
│    - nothing else (implicitly denied because at least        │
│      one policy applies)                                     │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Policy Selectors

A NetworkPolicy has three ways to select what traffic to allow. You compose them.

### podSelector

Selects pods **within the same namespace** by label.

```yaml
podSelector:
  matchLabels:
    app: backend           # ← matches pods with this label
```

An empty `podSelector: {}` selects all pods in the namespace.

### namespaceSelector

Selects pods in namespaces that match the label selector.

```yaml
namespaceSelector:
  matchLabels:
    team: monitoring       # ← matches namespaces with this label
```

Note: namespaces must be labeled for this to work. `kubectl label namespace monitoring team=monitoring`

### ipBlock

Selects an IP CIDR range. Used for traffic to/from outside the cluster (load balancers, external services, on-prem systems).

```yaml
ipBlock:
  cidr: 10.0.0.0/8        # ← allow this range
  except:
    - 10.0.0.0/24         # ← but not this subnet
```

### Combining selectors

When `podSelector` and `namespaceSelector` appear together inside one `from` or `to` entry, they are ANDed. When they are separate list items, they are ORed.

```yaml
# AND: pod must have app=frontend AND be in namespace team=web
from:
  - podSelector:
      matchLabels:
        app: frontend
    namespaceSelector:           # ← same list item = AND
      matchLabels:
        team: web

# OR: pod has app=frontend OR pod is in namespace team=web
from:
  - podSelector:
      matchLabels:
        app: frontend
  - namespaceSelector:           # ← separate list item = OR
      matchLabels:
        team: web
```

---

## 4. Default Deny All (Zero-Trust Starting Point)

The recommended production posture is to start with explicit deny-all policies and then open only what is needed. This is the **zero-trust networking** baseline.

### Deny all ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production             # ← applies to this namespace
spec:
  podSelector: {}                   # ← selects ALL pods in namespace
  policyTypes:
    - Ingress                       # ← this policy governs ingress
                                    # ← no ingress rules = deny all ingress
```

### Deny all egress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Egress                        # ← governs egress
                                    # ← no egress rules = deny all egress
```

### Deny all in both directions

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress                        # ← both types, no rules = deny all
```

After applying `default-deny-all`, you add specific policies to re-open only the paths your application needs. Every new policy is an explicit allowlist entry.

---

## 5. Allow Specific Ingress

### Allow from same namespace only

Useful for microservices that must stay within their namespace boundary.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: production
spec:
  podSelector: {}                   # ← all pods in this namespace
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector: {}           # ← any pod... in same namespace (default scope)
```

### Allow from specific pod label

The frontend tier can reach the backend tier; nothing else can.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend                  # ← this policy protects backend pods
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend         # ← only pods labeled app=frontend may connect
      ports:
        - protocol: TCP
          port: 8080                # ← only on this port
```

### Allow from specific namespace

Monitoring infrastructure in a separate namespace needs to scrape metrics from all pods.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring-scrape
  namespace: production
spec:
  podSelector: {}                   # ← all pods in production namespace
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              team: monitoring      # ← pods from the monitoring namespace
      ports:
        - protocol: TCP
          port: 9090                # ← Prometheus metrics port
```

### Allow from external CIDR range

Incoming traffic from a corporate VPN or load balancer IP range.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-vpn-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - from:
        - ipBlock:
            cidr: 10.10.0.0/16     # ← VPN address range
            except:
              - 10.10.100.0/24     # ← except this problematic subnet
      ports:
        - protocol: TCP
          port: 443
```

---

## 6. Allow Specific Egress

### Allow DNS (always required first)

This is the first thing to add after a default-deny-egress. Without it, pods cannot resolve any service name and will appear completely broken.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system   # ← kube-dns lives here
      ports:
        - protocol: UDP
          port: 53                  # ← DNS over UDP
        - protocol: TCP
          port: 53                  # ← DNS over TCP (large responses)
```

### Allow specific external IP range

Allow pods to reach an external data warehouse.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-warehouse-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: etl
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 203.0.113.0/24   # ← external data warehouse IPs
      ports:
        - protocol: TCP
          port: 5439               # ← Redshift default port
```

### Allow pod-to-pod within namespace

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-intranamespace-egress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector: {}          # ← any pod in same namespace
```

### Allow to specific service by label

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-to-cache
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: redis           # ← Redis cache pods only
      ports:
        - protocol: TCP
          port: 6379
```

---

## 7. Complete Production Example: 3-Tier Application

This example models a real production deployment: a frontend tier that faces the internet, a backend API, and a database. Each tier gets its own Network Policy set. Start with `default-deny-all` applied to the namespace, then layer these on top.

```
┌─────────────────────────────────────────────────────────────────────┐
│  3-TIER NETWORK POLICY MAP                                          │
│                                                                     │
│  Internet                                                           │
│     │  HTTPS:443                                                    │
│     ▼                                                               │
│  ┌────────────┐                                                     │
│  │  frontend  │  egress → backend:8080 only                        │
│  └────────────┘                                                     │
│         │  TCP:8080                                                 │
│         ▼                                                           │
│  ┌────────────┐                                                     │
│  │  backend   │  ingress ← frontend only                           │
│  └────────────┘  egress → database:5432 only                       │
│         │  TCP:5432                                                 │
│         ▼                                                           │
│  ┌────────────┐                                                     │
│  │  database  │  ingress ← backend only                            │
│  └────────────┘  egress → nothing                                  │
└─────────────────────────────────────────────────────────────────────┘
```

### Frontend: allow ingress from internet, allow egress to backend

```yaml
# Frontend ingress: allow from load balancer IP range
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - ipBlock:
            cidr: 0.0.0.0/0        # ← internet (filtered upstream by LB/WAF)
      ports:
        - protocol: TCP
          port: 443
---
# Frontend egress: DNS + backend only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    - to:
        - podSelector:
            matchLabels:
              app: backend         # ← only the backend tier
      ports:
        - protocol: TCP
          port: 8080
```

### Backend: allow ingress from frontend, allow egress to database

```yaml
# Backend ingress: frontend only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
---
# Backend egress: DNS + database only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    - to:
        - podSelector:
            matchLabels:
              app: database
      ports:
        - protocol: TCP
          port: 5432
```

### Database: allow ingress from backend, deny all egress

```yaml
# Database ingress: backend only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 5432
---
# Database egress: nothing (explicit deny-all egress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-egress-deny
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
    - Egress              # ← no egress rules = deny all egress
```

---

## 8. Debugging Network Policies

Kubernetes does not emit events when a Network Policy drops traffic — the packet is silently discarded at the kernel level. Here is a systematic debugging approach.

```
┌──────────────────────────────────────────────────────────────────┐
│  DEBUGGING WORKFLOW                                              │
│                                                                  │
│  Step 1: Verify the CNI plugin supports NetworkPolicy           │
│    kubectl get pods -n kube-system | grep -E 'calico|cilium'    │
│                                                                  │
│  Step 2: List policies in the target namespace                   │
│    kubectl get networkpolicy -n production                       │
│                                                                  │
│  Step 3: Check which policies select your pod                   │
│    kubectl describe networkpolicy -n production                  │
│    (look at PodSelector and compare to your pod labels)         │
│                                                                  │
│  Step 4: Test connectivity from inside the cluster              │
│    kubectl run debug --image=nicolaka/netshoot -it --rm         │
│    > curl -v http://backend-service:8080                        │
│    > nslookup backend-service   (DNS check)                     │
│                                                                  │
│  Step 5: Check pod labels match what policies expect            │
│    kubectl get pod <name> --show-labels                         │
│                                                                  │
│  Step 6: Check namespace labels (for namespaceSelector)         │
│    kubectl get namespace production --show-labels               │
└──────────────────────────────────────────────────────────────────┘
```

**Common root causes:**

```
┌─────────────────────────────────────────────────────────────────┐
│  Symptom                    │ Likely cause                      │
├─────────────────────────────┼───────────────────────────────────┤
│ Policy applied but traffic  │ CNI plugin doesn't enforce        │
│ still flows                 │ NetworkPolicy (e.g., Flannel)     │
├─────────────────────────────┼───────────────────────────────────┤
│ DNS fails after deny-all    │ Missing DNS egress rule (port 53) │
├─────────────────────────────┼───────────────────────────────────┤
│ namespaceSelector not        │ Namespace not labeled; run       │
│ matching                    │ kubectl label namespace ...       │
├─────────────────────────────┼───────────────────────────────────┤
│ AND vs OR confusion         │ podSelector + namespaceSelector   │
│                             │ in same list item = AND           │
├─────────────────────────────┼───────────────────────────────────┤
│ Policy targets wrong pods   │ Label mismatch; check pod labels  │
└─────────────────────────────┴───────────────────────────────────┘
```

For Cilium clusters, the `cilium monitor` command shows dropped packets with the policy reason in real time:

```bash
kubectl exec -n kube-system ds/cilium -- cilium monitor --type drop
```

For Calico clusters, enable flow logging or use `calicoctl`:

```bash
calicoctl get networkpolicy -n production -o yaml
```

---

## 9. CNI Comparison: Calico vs Cilium

```
┌─────────────────────────────────────────────────────────────────────┐
│                     CALICO vs CILIUM                                │
├──────────────────────────┬──────────────────────────────────────────┤
│ Calico                   │ Cilium                                   │
├──────────────────────────┼──────────────────────────────────────────┤
│ iptables or eBPF mode    │ eBPF-native (kernel 4.9+)               │
│ Kubernetes NetworkPolicy │ Kubernetes NetworkPolicy +               │
│ only                     │ CiliumNetworkPolicy (L7 aware)          │
│ Mature, very widely      │ Richer observability via Hubble UI      │
│ deployed (EKS default    │                                          │
│ with Calico addon)       │ Can enforce HTTP method/path rules       │
│ Lower overhead on        │ Higher feature ceiling; steeper         │
│ traditional workloads    │ operational learning curve              │
│ Global policy via        │ ClusterwideCiliumNetworkPolicy for      │
│ GlobalNetworkPolicy CRD  │ cross-namespace cluster-wide rules      │
└──────────────────────────┴──────────────────────────────────────────┘
```

For most teams on EKS, Calico is the practical default — it is well-documented, widely supported, and sufficient for standard Network Policy enforcement. Cilium is worth the investment when you need L7 (HTTP/gRPC-aware) policy enforcement or deep network observability.

---

## 10. Common Mistakes

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Mistake                          │ Fix                                │
├───────────────────────────────────┼────────────────────────────────────┤
│ Using Flannel and expecting       │ Switch to Calico or Cilium.        │
│ policies to be enforced           │ Flannel ignores NetworkPolicy.     │
├───────────────────────────────────┼────────────────────────────────────┤
│ Forgetting DNS egress after       │ Always add port 53 UDP/TCP egress  │
│ applying deny-all egress          │ to kube-system as first rule.      │
├───────────────────────────────────┼────────────────────────────────────┤
│ Namespace not labeled; namespace  │ kubectl label namespace <name>     │
│ Selector silently matches nothing │ <key>=<value>                      │
├───────────────────────────────────┼────────────────────────────────────┤
│ Confusing AND vs OR when          │ Same list item = AND. Separate     │
│ combining podSelector +           │ list items = OR.                   │
│ namespaceSelector                 │                                    │
├───────────────────────────────────┼────────────────────────────────────┤
│ Applying policy to wrong          │ Double-check podSelector labels    │
│ namespace                         │ against namespace in metadata.     │
├───────────────────────────────────┼────────────────────────────────────┤
│ Assuming egress policy on source  │ Policy must also be on the         │
│ pod is sufficient                 │ destination. Both sides matter     │
│                                   │ when deny-all is in place.         │
├───────────────────────────────────┼────────────────────────────────────┤
│ Not testing after apply           │ Always run a connectivity test     │
│                                   │ with netshoot or curl pod after    │
│                                   │ every policy change.               │
└───────────────────────────────────┴────────────────────────────────────┘
```

---

## Navigation

- Back to: [Containers README](../README.md)
- Previous: [Kubernetes Services and Ingress](k8s_services_and_ingress.md)
- Next: [Kubernetes Pod Runtime Patterns](k8s_pod_runtime_patterns.md)
- Related: [Linux OS for Containers](linux_os_for_containers.md) | [EKS](eks.md)
