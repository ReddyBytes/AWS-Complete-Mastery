# Kubernetes Services and Ingress — Industry Guide

A Kubernetes cluster without Services is like a city where every building has a street address that changes every time a new tenant moves in. Your app scales up, pods restart, roll over, get rescheduled — and every time they come back, they get a new IP address. Services solve this by giving you a stable name and virtual IP that never changes, no matter how many pods come and go behind it. Ingress then sits on top of that to give you a single front door that routes HTTP traffic to the right service based on the URL path or hostname — without paying for a separate cloud load balancer per service.

---

## 1. Why Services Exist

Think of a restaurant. You don't ask for a specific waiter by name — you sit at **table 5** and whoever is assigned to table 5 serves you. The waiter might be different at lunch versus dinner. They might call in sick and get replaced mid-shift. You never care. You just talk to table 5.

Pods are waiters. Their IPs are like their phone numbers — they change when they're replaced. A **Service** is the table number: a stable identifier that always resolves to "whoever is currently handling this role." Without it, every client that talks to your pod would need to re-discover pod IPs on every restart. With a Service, clients connect once and the routing layer handles the rest.

**Pods are ephemeral** by design. They crash, they scale down, they get evicted when a node runs out of memory, they get replaced during a rolling deployment. Each new pod gets a new IP assigned by the cluster's CNI plugin. The Service abstraction exists precisely because this churn is expected — it is not an edge case.

---

## 2. How Services Work Under the Hood

When you create a Service, you are not creating a real process or a load balancer daemon. You are creating a rule set. The control plane component responsible for translating that rule set into actual network rules is **kube-proxy**, which runs on every node in the cluster.

```
CONTROL PLANE                          NODE (every node)
┌────────────────────┐                 ┌──────────────────────────────────┐
│  API Server        │   watches       │  kube-proxy                      │
│  etcd              │ ─────────────► │  reads Service + Endpoints objs  │
│  Endpoints ctrl    │                 │  writes iptables / ipvs rules    │
└────────────────────┘                 └──────────────────────────────────┘
```

### Label Selectors

A Service does not point to pods by name. It points to pods by **labels** — arbitrary key/value pairs attached to the pod metadata. The Service spec has a `selector` field, and any pod that matches ALL of those labels is considered a backend.

```
Pod labels:     app=api, version=v2, env=prod
Service selector: app=api          ← matches this pod
```

This is intentional decoupling. You can swap out which pods serve traffic just by changing their labels, without touching the Service definition.

### The Endpoints Object

When you create a Service with a selector, the **endpoints controller** in the control plane continuously watches for pods matching that selector. It maintains an **Endpoints** object with the same name as the Service. That object is just a list of `<pod-ip>:<port>` pairs — the actual destinations.

```
$ kubectl get endpoints my-api-service
NAME              ENDPOINTS                         AGE
my-api-service    10.0.1.5:8080,10.0.1.9:8080      12m
```

kube-proxy watches this Endpoints object and updates iptables rules whenever pods come or go. The ClusterIP never changes; the destinations behind it do.

### Request Flow

```
CLIENT POD
    │
    │  connects to ClusterIP 10.96.14.200:80
    ▼
┌─────────────────────────────────────┐
│  iptables on the node               │
│  DNAT rule: 10.96.14.200:80         │
│  → randomly pick one endpoint       │
│  → rewrite dest to 10.0.1.5:8080   │
└─────────────────────────────────────┘
    │
    ▼
DESTINATION POD  10.0.1.5:8080
```

The ClusterIP is a **virtual IP** — no process listens on it. The iptables DNAT (Destination NAT) rule intercepts the packet before it leaves the network stack and rewrites the destination to a real pod IP. The pod never knows its client was talking to a virtual address.

---

## 3. ClusterIP — Internal Only

**ClusterIP** is the default Service type. It allocates a virtual IP that is reachable only from inside the cluster. Nothing outside the cluster can reach a ClusterIP service directly.

```
OUTSIDE CLUSTER                    INSIDE CLUSTER
                                   ┌──────────────────────────────┐
  (no access)                      │  Service: ClusterIP          │
                                   │  IP: 10.96.14.200            │
                                   │  Port: 80                    │
                                   │           │                  │
                                   │    ┌──────┴──────┐           │
                                   │    ▼             ▼           │
                                   │  pod:8080    pod:8080        │
                                   └──────────────────────────────┘
```

### YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: payments-api
  namespace: backend
spec:
  type: ClusterIP               # ← default, can be omitted
  selector:
    app: payments               # ← matches pods with this label
  ports:
    - protocol: TCP
      port: 80                  # ← port the service listens on
      targetPort: 8080          # ← port the pod container listens on
```

### DNS Resolution

Kubernetes runs **CoreDNS** inside the cluster. Every Service gets a DNS record automatically:

```
<service-name>.<namespace>.svc.cluster.local

payments-api.backend.svc.cluster.local   → resolves to 10.96.14.200
```

From a pod in the same namespace you can use just `payments-api`. From a different namespace you need `payments-api.backend`. The full FQDN always works everywhere.

### Accessing from a Pod: ENV vars vs DNS

When a pod starts, Kubernetes injects environment variables for every Service that existed at pod creation time:

```
PAYMENTS_API_SERVICE_HOST=10.96.14.200
PAYMENTS_API_SERVICE_PORT=80
```

This is fragile — if the service is created after the pod, the vars won't be there. **DNS is the preferred approach**. Code your apps to connect by name, not by environment variable.

**When to use ClusterIP**: any service-to-service communication that should never be exposed outside the cluster — internal APIs, caches, databases, message queues.

---

## 4. NodePort — Expose on Every Node

Sometimes you need to reach a service from outside the cluster without a cloud load balancer. A **NodePort** service tells Kubernetes to open a specific port (in the range 30000-32767) on every node in the cluster and forward traffic on that port to your pods.

Imagine your cluster has three nodes. If you create a NodePort service on port 31000, you can hit any of those three nodes at `<node-ip>:31000` and reach your pods — even if the pod is running on a different node. kube-proxy handles the forwarding.

```
EXTERNAL CLIENT
    │
    │  hits any node: 192.168.1.10:31000
    ▼
┌─────────────────────────────────────────────────────────┐
│  Node 1  (192.168.1.10)                                 │
│  NodePort: 31000  →  forwards to pod endpoints          │
└────────────────────────┬────────────────────────────────┘
                         │  (even if pod is on node 2)
                         ▼
                      POD  10.0.1.5:8080
```

### YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80            # ← ClusterIP port (internal)
      targetPort: 3000    # ← pod container port
      nodePort: 31080     # ← external node port (omit to let K8s pick)
```

### When to Use NodePort

NodePort is appropriate for:
- Bare metal clusters where no cloud load balancer integration exists
- Development environments where you want quick external access
- Direct node-level access during debugging

**Why you rarely use NodePort in production on AWS**: You are responsible for managing which node IPs to point your DNS at. If a node is replaced (EC2 Auto Scaling terminates and replaces it), the IP changes. You'd need to update your DNS manually. On AWS, you almost always use a LoadBalancer Service or an Ingress with the ALB Controller instead — both handle node fleet changes automatically.

---

## 5. LoadBalancer — Cloud-Provisioned External Access

When you create a Service of type **LoadBalancer**, Kubernetes asks the cloud provider to provision an actual external load balancer and wire it to your pods. On AWS, this creates a Network Load Balancer (NLB) or Classic ELB by default. The Service gets an external IP or hostname that anyone on the internet can reach.

Think of it as a bouncer at the door of your service. External traffic hits the LB, the LB forwards to the NodePort on your nodes, kube-proxy forwards to the pods. The cloud provider handles health checks, node rotation, and SSL termination at the LB level.

```
INTERNET
    │
    ▼
AWS NLB  (auto-provisioned by K8s cloud-controller-manager)
    │
    ├── node-1:31080
    ├── node-2:31080
    └── node-3:31080
         │
         ▼ (kube-proxy forwards)
      pods running app
```

### YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-api
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"           # ← use NLB not classic ELB
    service.beta.kubernetes.io/aws-load-balancer-internal: "false"     # ← internet-facing
spec:
  type: LoadBalancer
  selector:
    app: public-api
  ports:
    - protocol: TCP
      port: 443
      targetPort: 8443
```

### AWS-Specific Annotations

```yaml
annotations:
  # NLB vs classic ELB
  service.beta.kubernetes.io/aws-load-balancer-type: "nlb"

  # Internal LB (VPC-only, not internet-facing)
  service.beta.kubernetes.io/aws-load-balancer-internal: "true"

  # Specific subnets to place LB in
  service.beta.kubernetes.io/aws-load-balancer-subnets: "subnet-abc,subnet-def"

  # ACM SSL cert for HTTPS
  service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:us-east-1:123:certificate/abc"

  # Only accept HTTPS on the LB listener
  service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
```

### The Cost Problem

Every LoadBalancer Service creates one AWS load balancer. If you have 20 services that need external access, you provision 20 load balancers. At current AWS pricing, an NLB costs around $16-25/month plus data transfer. 20 services = $300-500/month before you've written a line of application code. This is the core motivation for Ingress.

---

## 6. ExternalName — Mapping to External DNS

**ExternalName** is the outlier Service type. It does not proxy traffic or create load balancers. It creates a **CNAME** in the cluster's DNS that points to an external hostname. No kube-proxy rules are written. No endpoints are tracked.

Think of it as a forwarding alias. Your code inside the cluster talks to `payments-gateway` — a clean internal name. The DNS lookup returns a CNAME pointing to `api.stripe.com`. Your code never needs to know the external address.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: payments-gateway
  namespace: backend
spec:
  type: ExternalName
  externalName: api.stripe.com    # ← DNS resolves to this CNAME
```

### Use Cases

- **Abstracting external dependencies**: Your code connects to `db.backend.svc.cluster.local`. Today that's an ExternalName pointing to an RDS instance. Next quarter you migrate the database in-cluster. You update the Service — your app code changes nothing.
- **Migration path**: Route traffic to an external service while you build the in-cluster replacement. Cut over by changing the Service type, not the application.

A limitation: ExternalName does not do port remapping or TLS inspection. It is purely a DNS trick.

---

## 7. Headless Services — Direct Pod DNS

A regular ClusterIP Service hides the individual pod IPs behind a virtual IP. Sometimes you need the opposite: give me the actual IP of each pod directly. This is what a **headless Service** does.

Setting `clusterIP: None` tells Kubernetes not to allocate a virtual IP. Instead, DNS queries for the service return A records pointing directly to the IPs of every matching pod.

```
Regular Service DNS query:
  payments-api.backend.svc.cluster.local → 10.96.14.200 (single VIP)

Headless Service DNS query:
  payments-api.backend.svc.cluster.local → 10.0.1.5, 10.0.1.9, 10.0.2.3
                                            (all pod IPs directly)
```

### YAML

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: messaging
spec:
  clusterIP: None               # ← this makes it headless
  selector:
    app: kafka
  ports:
    - port: 9092
      targetPort: 9092
```

### Why StatefulSets Require Headless Services

**StatefulSets** manage pods with stable, persistent identities: `kafka-0`, `kafka-1`, `kafka-2`. A Kafka consumer needs to connect to a specific broker, not a random one. A regular Service would load-balance across all brokers — useless if you need broker-0 specifically.

With a headless Service, each StatefulSet pod gets a stable DNS record:

```
kafka-0.kafka.messaging.svc.cluster.local → 10.0.1.5
kafka-1.kafka.messaging.svc.cluster.local → 10.0.1.9
kafka-2.kafka.messaging.svc.cluster.local → 10.0.2.3
```

Your Kafka client can enumerate `kafka-0`, `kafka-1`, `kafka-2` by convention. The addresses are stable across pod restarts as long as the pod name stays the same — and StatefulSets guarantee that.

---

## 8. Ingress — HTTP Routing at Layer 7

You have ten microservices. Each needs to be reachable from the internet. With LoadBalancer Services you'd pay for ten cloud load balancers. **Ingress** solves this with one load balancer at the edge and routing rules that distribute traffic internally.

Think of Ingress as the front desk of a hotel. One door, one address, one phone number. You walk in and say "I'm here for the spa" or "I'm here for the restaurant." The front desk sends you to the right floor. Ingress does the same: one external endpoint, routing decisions made on HTTP hostname or URL path.

```
INTERNET
    │
    ▼
ONE load balancer (ALB or nginx pod)
    │
    ├── /api/*      → backend-service:8080
    ├── /auth/*     → auth-service:3000
    └── /*          → frontend-service:80
```

### Cost Comparison

```
Without Ingress:
  10 services × $18/month (NLB) = $180/month

With Ingress:
  1 ALB × $18/month + data processing = ~$20-30/month
```

The difference compounds with scale.

### Path-Based Routing

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: "nginx"   # ← tells which controller owns this
spec:
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix               # ← matches /api, /api/users, /api/orders
            backend:
              service:
                name: backend-service
                port:
                  number: 8080
          - path: /
            pathType: Prefix               # ← catch-all, must come last
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

### Host-Based Routing

Route to different backends based on the HTTP `Host` header — no path matching required:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  rules:
    - host: api.example.com               # ← Host header must match exactly
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
    - host: app.example.com               # ← different hostname, different backend
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

### TLS Termination at Ingress

The Ingress can terminate HTTPS so your backend pods only need to handle plain HTTP internally:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls-secret        # ← K8s Secret containing cert and key
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

The Secret must contain `tls.crt` and `tls.key`. cert-manager (a common cluster add-on) can provision and auto-renew Let's Encrypt certificates and write them into these Secrets automatically.

---

## 9. Ingress Controllers — The Part That Actually Does the Work

Here is the subtle point that trips up most people: **an Ingress resource is just a configuration object**. It describes your routing intentions. By itself it does nothing. You need an **Ingress Controller** — a running process in your cluster that reads Ingress objects and implements them.

The separation is intentional. You define your routing rules in a standard Kubernetes API object. The controller that enforces those rules is pluggable. You can swap nginx for Traefik for the AWS ALB Controller without changing your Ingress YAML.

```
YOU CREATE                  CONTROLLER READS         TRAFFIC FLOWS
┌──────────────┐           ┌────────────────────┐        │
│ Ingress YAML │ ─────────►│  Ingress Controller│◄───────┘
│ (routing     │           │  (nginx pod or ALB)│
│  rules)      │           │  enforces rules    │
└──────────────┘           └────────────────────┘
```

### nginx Ingress Controller

Runs as a pod inside your cluster. It watches Ingress objects and dynamically rewrites its own nginx configuration. All HTTP/HTTPS traffic enters the cluster through this pod (via a LoadBalancer Service in front of it).

Use nginx when:
- You want full control over the proxy layer
- You need advanced L7 features: rate limiting, request rewriting, basic auth, custom headers
- You run on bare metal or a cloud that doesn't have a native Ingress integration
- You want the same behavior across any cloud or on-prem

### AWS ALB Ingress Controller (AWS Load Balancer Controller)

Runs as a pod in EKS. When it sees an Ingress object with the right annotations, it provisions a real **AWS Application Load Balancer** and creates target groups pointing to your pods. Traffic never enters the cluster through a proxy pod — it hits the ALB directly and routes to nodes, then to pods.

```
INTERNET
    │
    ▼
AWS ALB  (provisioned by controller, managed outside cluster)
    │
    ├── /api   Target Group → pod IPs (IP mode) or node ports (instance mode)
    └── /      Target Group → pod IPs
```

Use the ALB Controller when:
- You are on EKS and want native AWS integration
- You need AWS WAF, ACM certificates, or Cognito auth at the LB layer
- You want to use IP-mode target groups (direct pod routing, no kube-proxy hop)
- You need granular ALB features: sticky sessions, weighted target groups, OIDC authentication

### nginx vs ALB Controller: Decision Table

```
┌──────────────────────────┬─────────────────────┬───────────────────────┐
│ Dimension                │ nginx Controller     │ AWS ALB Controller    │
├──────────────────────────┼─────────────────────┼───────────────────────┤
│ Traffic path             │ Through nginx pod    │ Directly to pods      │
│ Cloud portability        │ Any cloud / on-prem  │ AWS only              │
│ AWS WAF integration      │ Manual               │ Native annotation     │
│ ACM cert management      │ Use cert-manager     │ Native annotation     │
│ Rate limiting            │ Built-in             │ Needs WAF             │
│ Websockets               │ Yes                  │ Yes                   │
│ Cost                     │ 1 NLB for nginx LB   │ 1 ALB per Ingress     │
│ Ops overhead             │ Manage nginx pods    │ Managed by controller │
│ Pod-level routing        │ Via ClusterIP        │ IP-mode target groups │
└──────────────────────────┴─────────────────────┴───────────────────────┘
```

### ALB Controller Annotations

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: alb                              # ← claim this for ALB controller
    alb.ingress.kubernetes.io/scheme: internet-facing            # ← or 'internal' for VPC-only
    alb.ingress.kubernetes.io/target-type: ip                    # ← route direct to pod IPs
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:..."  # ← ACM cert for HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
    alb.ingress.kubernetes.io/actions.ssl-redirect: |
      {"type":"redirect","redirectConfig":{"protocol":"HTTPS","statusCode":"HTTP_301"}}
    alb.ingress.kubernetes.io/healthcheck-path: /healthz          # ← ALB health check endpoint
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
    alb.ingress.kubernetes.io/success-codes: "200"
    alb.ingress.kubernetes.io/wafv2-acl-arn: "arn:aws:wafv2:..."  # ← attach WAF ACL
spec:
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-service
                port:
                  number: 8080
```

### Traefik

A third option popular in smaller clusters and development environments. It supports automatic service discovery via Kubernetes CRDs, has a built-in dashboard, and handles Let's Encrypt natively without cert-manager. Less common in large AWS production deployments but worth knowing.

---

## 10. EndpointSlices and Topology-Aware Routing

As clusters grow to hundreds of nodes and thousands of pods, the original Endpoints object becomes a bottleneck. Every time a single pod changes state (restarts, scales), the entire Endpoints object for that Service is rewritten and broadcast to every kube-proxy instance on every node.

**EndpointSlices** replace this with a sharded model. Each slice holds up to 100 endpoints. A Service with 500 pods has 5 slices. When one pod changes, only the relevant slice is updated and propagated — 80% less data broadcast in large clusters.

**Topology-aware routing** (also called "topology hints") extends this further. kube-proxy can prefer pod endpoints in the same availability zone as the calling pod. A pod in `us-east-1a` preferentially hits pods in `us-east-1a` before routing cross-zone. This reduces inter-AZ data transfer costs and latency.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    service.kubernetes.io/topology-mode: "Auto"   # ← enable zone-aware routing
spec:
  selector:
    app: my-app
  ports:
    - port: 80
```

Both features are enabled by default in Kubernetes 1.24+. You don't need to configure them unless you want topology hints, which require the annotation above and a reasonably balanced pod distribution across zones.

---

## 11. Common Mistakes

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ MISTAKE                              │ SYMPTOM                 │ FIX                 │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ Selector doesn't match pod labels    │ Service has no          │ kubectl get         │
│                                      │ endpoints, 503 always   │ endpoints; fix      │
│                                      │                         │ label mismatch      │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ targetPort doesn't match container   │ Connection refused at   │ Check containerPort │
│ port in pod spec                     │ the pod level           │ vs targetPort       │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ Using env var service discovery      │ New services invisible  │ Always use DNS      │
│ instead of DNS                       │ to old pods             │ for service lookup  │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ One LoadBalancer Service per         │ $200+/month in idle     │ Use Ingress with    │
│ microservice on AWS                  │ LB charges              │ one ALB             │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ Ingress resource created but no      │ Ingress address never   │ Install the         │
│ Ingress Controller installed         │ populates               │ controller first    │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ nginx Ingress and ALB Controller     │ Race conditions, rules  │ Use one controller  │
│ both installed, no class annotation  │ applied by wrong ctrl   │ or set ingressClass │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ StatefulSet using regular Service    │ All traffic load-       │ Use headless        │
│ (not headless)                       │ balanced; can't reach   │ Service for         │
│                                      │ individual pod          │ StatefulSets        │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ Missing readinessProbe on pods       │ Service sends traffic   │ Add readinessProbe; │
│ behind a Service                     │ to starting/broken pods │ endpoints only add  │
│                                      │                         │ ready pods          │
├──────────────────────────────────────┼─────────────────────────┼─────────────────────┤
│ ExternalName used for TLS service    │ TLS SNI mismatch,       │ ExternalName is     │
│ without SNI passthrough config       │ cert errors             │ DNS-only; use proxy │
│                                      │                         │ for TLS passthrough │
└──────────────────────────────────────┴─────────────────────────┴─────────────────────┘
```

---

## Navigation

- Back to [README](../../../README.md)
- Previous: [k8s_pod_runtime_patterns.md](./k8s_pod_runtime_patterns.md)
- Next: [k8s_network_policies.md](./k8s_network_policies.md)
- Related: [k8s_deployment_strategies.md](./k8s_deployment_strategies.md)
- Related: [eks.md](./eks.md)
- Related: [terraform_to_k8s_variable_flow.md](./terraform_to_k8s_variable_flow.md)
