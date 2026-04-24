# Kubernetes StatefulSets — Industry Guide

Think of a Deployment as a hotel. Every room is identical — any guest can be checked into any room, and when a guest leaves, the room is cleaned and reassigned without ceremony. That works perfectly for a stateless web server. But imagine you are running a Postgres cluster. The primary node is room 101. It has years of transaction logs, a specific network identity that clients have memorised, and a strict relationship with its two replicas. If Kubernetes casually destroys room 101 and spins up a new one — same image, different history, different name, different volume — your database is gone. **StatefulSets** exist because some workloads are not interchangeable hotel rooms. They are assigned parking spaces: the same pod always gets the same spot, the same name, and the same persistent volume.

---

## 1. Why StatefulSets Exist

A **Deployment** treats every pod as a fungible replica. Scale from 3 to 5? Two new pods appear with random suffixes (`web-abc12`, `web-xyz99`). Scale back to 3? Kubernetes picks two to kill — it does not care which ones. Storage is either ephemeral (dies with the pod) or shared via a single `PersistentVolumeClaim` that all pods mount together. For stateless apps this is perfect.

A **StatefulSet** makes four guarantees that Deployments do not:

1. Every pod gets a stable, predictable name based on an ordinal index: `web-0`, `web-1`, `web-2`.
2. Pods are created in order (0 first, then 1, then 2) and deleted in reverse order (2 first, then 1, then 0).
3. Each pod gets its own **PersistentVolumeClaim** — its own private storage that survives pod deletion and rescheduling.
4. Each pod gets a stable DNS hostname that does not change even if the pod is rescheduled to a different node.

The rental car analogy made concrete: a Deployment is a car rental where any available car will do. A StatefulSet is an assigned parking space — pod `web-0` always parks in space 0, always mounts `data-web-0`, and always answers to `web-0.myservice.default.svc.cluster.local`.

---

## 2. Deployment vs StatefulSet Comparison

```
┌─────────────────────┬──────────────────────────────┬──────────────────────────────┐
│ Attribute           │ Deployment                   │ StatefulSet                  │
├─────────────────────┼──────────────────────────────┼──────────────────────────────┤
│ Pod naming          │ Random suffix (web-abc12)    │ Ordinal index (web-0, web-1) │
│ Start order         │ All pods start in parallel   │ 0 → 1 → 2 in sequence        │
│ Stop order          │ Random / parallel            │ N → N-1 → 0 in reverse       │
│ Storage             │ Shared PVC or ephemeral      │ One PVC per pod              │
│ Network identity    │ Unstable (changes on restart)│ Stable DNS name per pod      │
│ Pod identity        │ Interchangeable              │ Unique and persistent        │
│ Rolling update      │ Surge-based, any pod first   │ Reverse ordinal order        │
│ Use cases           │ Web servers, APIs, workers   │ Databases, queues, caches    │
└─────────────────────┴──────────────────────────────┴──────────────────────────────┘
```

---

## 3. StatefulSet Pod Naming and DNS Identity

Picture a row of safety deposit boxes at a bank. Box 0 belongs to the primary. Box 1 and box 2 belong to replicas. The box number is stamped on the key and never changes — it is not randomly assigned each visit. That is what ordinal naming gives you.

When you create a StatefulSet named `web` with 3 replicas, Kubernetes creates:

```
web-0   ← ordinal 0, always the first pod created, last deleted
web-1   ← ordinal 1
web-2   ← ordinal 2
```

Each pod gets a **stable network identity** via a **Headless Service** (covered in the next section). The DNS name pattern is:

```
<pod-name>.<service-name>.<namespace>.svc.cluster.local

web-0.myservice.default.svc.cluster.local
web-1.myservice.default.svc.cluster.local
web-2.myservice.default.svc.cluster.local
```

These DNS names are stable. If `web-1` crashes and is rescheduled to a different node, it comes back as `web-1` with the same DNS name and the same PVC. Clients that were talking to `web-1.myservice...` can reconnect without reconfiguration.

---

## 4. Headless Service — The Required Companion

A regular Kubernetes **Service** with `clusterIP` set to a real IP is a load balancer in disguise. Traffic goes to the Service IP, and kube-proxy fans it out to any healthy pod behind it. For databases, this is wrong — your application needs to send writes to the primary specifically, and reads to a specific replica. You cannot send them to a random pod.

A **Headless Service** solves this. Set `clusterIP: None` and the Service stops being a load balancer. Instead, DNS returns individual pod IP addresses directly — one A record per pod. The client picks the pod it wants.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres          # ← this name appears in every pod's DNS hostname
  namespace: default
  labels:
    app: postgres
spec:
  clusterIP: None         # ← makes this headless — no VIP, DNS returns pod IPs directly
  selector:
    app: postgres
  ports:
    - port: 5432
      name: postgres
```

With this Service in place, DNS resolution for `postgres.default.svc.cluster.local` returns all pod IPs. DNS resolution for `postgres-0.postgres.default.svc.cluster.local` returns the IP of pod `postgres-0` specifically. That is how a replica knows exactly how to reach the primary — it resolves `postgres-0.postgres...` directly.

```
Regular Service DNS:
  myservice.default.svc.cluster.local  →  10.100.0.50 (VIP — kube-proxy load balances)

Headless Service DNS:
  myservice.default.svc.cluster.local  →  [10.0.1.5, 10.0.2.3, 10.0.3.8] (actual pod IPs)
  web-0.myservice.default.svc.cluster.local  →  10.0.1.5 (pod-0 directly)
  web-1.myservice.default.svc.cluster.local  →  10.0.2.3 (pod-1 directly)
```

---

## 5. VolumeClaimTemplates — One PVC Per Pod

Think of the hotel analogy again, but now each guest has a personal storage locker — not a shared luggage room. When a guest (pod) checks out and checks back in, their locker is still there with everything inside. Nobody else touches it.

**`volumeClaimTemplates`** in a StatefulSet spec tells Kubernetes: for every pod you create, also create a dedicated **PersistentVolumeClaim**. The PVC name is derived from the template name and the pod ordinal:

```
Template name: data
Pod-0 gets PVC: data-web-0
Pod-1 gets PVC: data-web-1
Pod-2 gets PVC: data-web-2
```

Critically: when a pod is deleted, the PVC is NOT deleted. If `web-1` crashes and Kubernetes recreates it, the new `web-1` mounts `data-web-1` — the same volume with the same data. This is the primary reason StatefulSets exist.

```
┌──────────────────────────────────────────────────────────────┐
│ StatefulSet: web (3 replicas)                                │
│                                                              │
│  Pod web-0 ──── PVC data-web-0 ──── PV (EBS volume az-a)    │
│  Pod web-1 ──── PVC data-web-1 ──── PV (EBS volume az-a)    │
│  Pod web-2 ──── PVC data-web-2 ──── PV (EBS volume az-a)    │
│                                                              │
│  Delete pod web-1:                                           │
│    PVC data-web-1 still exists ✓                            │
│    Kubernetes recreates web-1                                │
│    web-1 mounts data-web-1 ← same data                      │
└──────────────────────────────────────────────────────────────┘
```

**EBS vs EFS for StatefulSet storage:**

**EBS (Elastic Block Store)** is block storage attached to a single EC2 instance in a single Availability Zone. If your pod is rescheduled to a node in a different AZ, the EBS volume cannot follow — the pod will be stuck `Pending`. For StatefulSets with EBS, node affinity is critical: each pod must stay in the AZ where its EBS volume lives.

**EFS (Elastic File System)** is network-attached storage available across all AZs in a region. It can follow a pod anywhere. The trade-off: EFS is slower (NFS protocol) and more expensive at high throughput. EFS works well for shared configuration, logs, or applications where performance is not critical. For databases, EBS (or better yet, managed RDS) is almost always the right answer.

```
EBS:   Pod ─── AZ-a ─── EBS vol (az-a only)   ← pod CANNOT move to az-b
EFS:   Pod ─── any AZ ─── EFS mount target     ← pod can move freely
```

---

## 6. Full StatefulSet YAML — Annotated Example

The following example defines a minimal Redis-like key-value store cluster. Read every comment — the annotations explain the non-obvious choices.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kvstore
  namespace: default
spec:
  serviceName: kvstore          # ← MUST match the Headless Service name exactly
  replicas: 3
  selector:
    matchLabels:
      app: kvstore
  podManagementPolicy: OrderedReady   # ← start/stop one at a time (default, safe for DBs)
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0              # ← update all pods; set to N to do canary (see section 8)
  template:
    metadata:
      labels:
        app: kvstore
    spec:
      terminationGracePeriodSeconds: 30   # ← give the process time to flush to disk
      initContainers:
        - name: init-role
          image: busybox:1.35
          command:
            - sh
            - -c
            - |
              # Determine role based on pod ordinal in the name
              ORDINAL="${MY_POD_NAME##*-}"   # ← extract number from "kvstore-2" → "2"
              if [ "$ORDINAL" = "0" ]; then
                echo "primary" > /data/role  # ← pod-0 is always the primary
              else
                echo "replica" > /data/role  # ← all others wait and replicate
              fi
          env:
            - name: MY_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name  # ← inject pod name via Downward API
          volumeMounts:
            - name: data
              mountPath: /data
      containers:
        - name: kvstore
          image: redis:7.2-alpine          # ← using Redis as a representative KV store
          ports:
            - containerPort: 6379
              name: redis
          command:
            - sh
            - -c
            - |
              ROLE=$(cat /data/role)
              if [ "$ROLE" = "primary" ]; then
                redis-server --save 60 1 --loglevel notice
              else
                # Wait until primary is reachable, then replicate
                until redis-cli -h kvstore-0.kvstore ping; do
                  echo "waiting for primary..."; sleep 2
                done
                redis-server --replicaof kvstore-0.kvstore 6379
              fi
          env:
            - name: MY_POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          volumeMounts:
            - name: data
              mountPath: /data
          readinessProbe:
            exec:
              command: ["redis-cli", "ping"]
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            exec:
              command: ["redis-cli", "ping"]
            initialDelaySeconds: 15
            periodSeconds: 20
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
  volumeClaimTemplates:
    - metadata:
        name: data                      # ← PVCs become: data-kvstore-0, data-kvstore-1 ...
      spec:
        accessModes: ["ReadWriteOnce"]  # ← RWO = one node at a time (correct for EBS)
        storageClassName: gp3           # ← use your cluster's StorageClass name
        resources:
          requests:
            storage: 10Gi
```

The accompanying Headless Service:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kvstore          # ← must match spec.serviceName above
  namespace: default
spec:
  clusterIP: None        # ← headless
  selector:
    app: kvstore
  ports:
    - port: 6379
      name: redis
```

---

## 7. Pod Management Policy

By default, StatefulSets use careful, sequential orchestration — like boarding an airplane one row at a time instead of letting everyone rush the door at once. This is safe but slow. Kubernetes gives you a knob to change this.

**`OrderedReady`** (default): Kubernetes creates pods one at a time, in ordinal order. It waits for pod `N` to be Running and Ready before creating pod `N+1`. On scale-down or delete, it goes in reverse: `N`, `N-1`, ..., `0`. This is the right policy for databases and any system where order matters.

**`Parallel`**: Kubernetes creates or deletes all pods simultaneously. No waiting for readiness between pods. Use this when your application can tolerate any start order — for example, a distributed cache where all nodes are peers and there is no primary/replica distinction.

```yaml
spec:
  podManagementPolicy: Parallel   # ← all pods start at once, no ordering guarantee
```

```
OrderedReady (scale up 0→3):
  t=0s   web-0 created, waiting for Ready...
  t=10s  web-0 Ready → web-1 created, waiting for Ready...
  t=20s  web-1 Ready → web-2 created
  Total: ~30s, but safe

Parallel (scale up 0→3):
  t=0s   web-0, web-1, web-2 created simultaneously
  Total: ~10s, but your app must handle concurrent init
```

---

## 8. Rolling Updates with Partition (Canary Pattern)

Imagine you want to test a new version of your database image on one replica before risking your primary. The **partition** field in `updateStrategy` is your safety net. It tells Kubernetes: only update pods whose ordinal is greater than or equal to this number.

With `partition: 2` on a 3-pod StatefulSet, only `web-2` gets the new image. `web-0` and `web-1` stay on the old version. You can watch `web-2` for errors, run queries against it, and only then lower the partition to roll out further.

```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 2       # ← only pods with ordinal >= 2 get the new image
                         #    web-0 and web-1 stay on old version
                         #    web-2 gets new version immediately
```

Canary rollout sequence:

```
Step 1: Set partition: 2
  web-0  → old image (ordinal 0, 0 < 2, skipped)
  web-1  → old image (ordinal 1, 1 < 2, skipped)
  web-2  → NEW image (ordinal 2, 2 >= 2, updated)

Step 2: Verify web-2 is healthy. Watch logs, run smoke tests.

Step 3: Set partition: 1
  web-0  → old image (0 < 1, skipped)
  web-1  → NEW image (1 >= 1, updated)
  web-2  → NEW image (already updated)

Step 4: Set partition: 0
  web-0  → NEW image (0 >= 0, updated)
  All pods on new version.
```

To trigger the update, change the image in the StatefulSet spec — the partition controls which pods receive the change:

```bash
kubectl set image statefulset/kvstore kvstore=redis:7.4-alpine

kubectl patch statefulset kvstore \
  -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'
  # ← apply the partition before or together with the image change
```

---

## 9. Init Patterns for StatefulSets — Role Detection via Ordinal

When a StatefulSet pod starts, it does not know whether it is the primary or a replica until it looks at its own name. The init container pattern for database clusters exploits this: strip the ordinal from the pod name and use it to decide the startup role.

The pod name is injected via the **Downward API** (`metadata.name`), which gives you the string `kvstore-0`, `kvstore-1`, etc. A shell one-liner strips everything up to the last dash to extract the ordinal number.

```yaml
initContainers:
  - name: determine-role
    image: busybox:1.35
    command:
      - sh
      - -c
      - |
        # Extract ordinal: "postgres-2" → "2"
        ORDINAL="${MY_POD_NAME##*-}"

        if [ "$ORDINAL" = "0" ]; then
          # I am the primary — initialize the data directory if it is empty
          if [ ! -f /data/PG_VERSION ]; then
            initdb -D /data                     # ← PostgreSQL: initialize data dir
          fi
          echo "primary" > /data/my-role
        else
          # I am a replica — wait for primary to be reachable, then clone
          until pg_isready -h postgres-0.postgres; do
            echo "waiting for primary postgres-0..."; sleep 3
          done
          # Clone primary's data if data dir is empty
          if [ ! -f /data/PG_VERSION ]; then
            pg_basebackup -h postgres-0.postgres -D /data -P -U replicator -R
            # -R writes recovery.conf automatically so the replica connects on start
          fi
          echo "replica" > /data/my-role
        fi
    env:
      - name: MY_POD_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.name   # ← Downward API injects "postgres-0"
    volumeMounts:
      - name: data
        mountPath: /data
```

The key insight: `pod-0` is always the primary because it is always created first and is the last to be deleted. All other ordinals are replicas. This is a convention that Kubernetes operators like the CloudNativePG operator bake into their logic at a deeper level — but you can replicate the same pattern with a plain StatefulSet and init containers.

```
Init container flow for postgres-1:

  MY_POD_NAME = "postgres-1"
  ORDINAL = "1"            (stripped suffix)
  1 != 0 → replica path
  ↓
  Wait: pg_isready -h postgres-0.postgres
  ↓ (primary responds)
  pg_basebackup → clone primary data into /data
  ↓
  Write "replica" → /data/my-role
  ↓
  Init container exits 0
  ↓
  Main postgres container starts, reads recovery.conf, connects to primary
```

---

## 10. Real-World Use Cases

Every stateful system on Kubernetes follows the same underlying logic: stable identity, ordered startup, private storage. The application changes; the StatefulSet contract does not.

**PostgreSQL primary + replicas**

The most common StatefulSet use case. Pod `postgres-0` is the primary, handling all writes. `postgres-1` and `postgres-2` are streaming replicas. Applications connect to `postgres-0.postgres...` for writes and to the headless service (round-robin across replicas) for reads. Tools like CloudNativePG wrap this pattern into a Kubernetes operator that handles failover, backups, and connection pooling automatically.

```
postgres-0 (primary)  ← writes from app
postgres-1 (replica)  ← reads from app, streams WAL from postgres-0
postgres-2 (replica)  ← reads from app, streams WAL from postgres-0
```

**Redis Sentinel**

Redis Sentinel uses a 3-pod StatefulSet: one master, two replicas, with Sentinel processes watching for master failure. Because the pods have stable DNS names, Sentinel can reference `redis-0.redis...` as the initial master in its configuration, and replicas use the same address to configure replication.

**Zookeeper quorum**

ZooKeeper requires a quorum — a majority of nodes must be alive for the cluster to accept writes. A 3-node ZooKeeper StatefulSet (`zk-0`, `zk-1`, `zk-2`) uses stable pod DNS names in each node's `zoo.cfg` file to identify peers. If you used Deployment-style random names, the config would break on every restart.

```
zoo.cfg on each node:
  server.1=zk-0.zookeeper.default.svc.cluster.local:2888:3888
  server.2=zk-1.zookeeper.default.svc.cluster.local:2888:3888
  server.3=zk-2.zookeeper.default.svc.cluster.local:2888:3888
```

**What NOT to run as a StatefulSet**

The honest advice most tutorials omit: do not run production databases on Kubernetes StatefulSets unless you have a specific reason to. The operational overhead is high. Managed services almost always win:

```
┌─────────────────────────────┬──────────────────────────────────────────────┐
│ You might consider          │ But you probably want the managed version     │
├─────────────────────────────┼──────────────────────────────────────────────┤
│ PostgreSQL StatefulSet      │ AWS RDS or Aurora PostgreSQL                 │
│ MySQL StatefulSet           │ AWS RDS MySQL or Aurora MySQL                │
│ Redis StatefulSet           │ AWS ElastiCache for Redis                    │
│ Kafka StatefulSet           │ AWS MSK (Managed Streaming for Kafka)        │
│ Elasticsearch StatefulSet   │ AWS OpenSearch Service                       │
└─────────────────────────────┴──────────────────────────────────────────────┘
```

StatefulSets shine when: you need data locality with your compute, you are building a platform product (like an operator), you have strong Kubernetes expertise in-house, or cost constraints make managed services prohibitive at scale.

---

## 11. StatefulSet Limitations and When to Use Managed Services

StatefulSets push a significant amount of operational complexity onto the platform team. Understanding the limits helps you make the build-vs-buy decision clearly.

**Storage is per-AZ with EBS.** If your cluster spans 3 AZs and a pod is rescheduled to a different AZ than its EBS volume, the pod will never start. You must use node affinity rules or topology-aware volume provisioning to pin pods to their AZ. EFS avoids this problem but is not suitable for database workloads.

**PVCs are not garbage-collected.** When you delete a StatefulSet, the PVCs remain. This is a feature (data is safe) but it means you must manually delete PVCs when decommissioning. Automation that deletes the StatefulSet without cleaning up PVCs will leak expensive storage indefinitely.

**No built-in failover.** If `postgres-0` (your primary) crashes, Kubernetes will restart it — but it will not promote a replica to primary. That requires an operator (like CloudNativePG, Patroni, or Vitess) sitting on top of the StatefulSet and handling leader election.

**Rolling updates stop on failure.** If pod `N` fails to start on a new image, the rollout halts. The cluster is left in a mixed state — some pods on the old version, some on new. You must manually investigate and fix the failing pod before the rollout continues.

**Scaling down does not delete PVCs.** Scale from 5 to 3 pods and the PVCs for `pod-4` and `pod-3` remain. If you scale back up to 5, the pods reattach to the same PVCs — which is usually what you want, but can surprise operators expecting fresh storage.

```
Managed Service vs StatefulSet — operational responsibility:

              StatefulSet               Managed (RDS, ElastiCache)
Backups:      You configure/verify      Automatic, point-in-time
Failover:     Operator or manual        Automatic (Multi-AZ)
Patching:     You roll updates          AWS applies during maintenance
Monitoring:   You instrument            CloudWatch metrics built-in
Storage:      You size, you expand      Auto-scaling options available
Replication:  You configure             Handled by the service
```

---

## 12. Common Mistakes

```
┌──────────────────────────────────────┬────────────────────────────────────────────────────┐
│ Mistake                              │ Consequence and Fix                                │
├──────────────────────────────────────┼────────────────────────────────────────────────────┤
│ Using a ClusterIP Service instead    │ DNS returns VIP — clients cannot target specific   │
│ of Headless Service                  │ pods. Fix: set clusterIP: None on the Service.     │
│                                      │                                                    │
│ serviceName in StatefulSet spec does │ Pod DNS names are broken — pods cannot find each   │
│ not match the Service name           │ other. Names must be identical.                    │
│                                      │                                                    │
│ Using EBS across multiple AZs        │ Pod gets stuck Pending after rescheduling to a     │
│ without node affinity                │ different AZ. Fix: use topology affinity or EFS.  │
│                                      │                                                    │
│ Deleting StatefulSet and expecting   │ PVCs are not deleted — storage leaks. Fix:         │
│ PVCs to be cleaned up                │ delete PVCs manually after StatefulSet deletion.   │
│                                      │                                                    │
│ Not setting terminationGracePeriod   │ Pod is SIGKILLed mid-write, corrupting data.       │
│ long enough for flush                │ Fix: set enough seconds for checkpoint/flush.      │
│                                      │                                                    │
│ Using Parallel podManagement         │ All pods race to initialize simultaneously —        │
│ with a primary/replica topology      │ two pods try to become primary. Use OrderedReady.  │
│                                      │                                                    │
│ Forgetting readinessProbe            │ OrderedReady policy advances to the next pod too   │
│                                      │ soon. The previous pod is not ready but appears    │
│                                      │ Running. Fix: always define a readinessProbe.      │
│                                      │                                                    │
│ Setting partition: 0 accidentally    │ All pods update at once — you lose canary safety.  │
│ before verifying canary              │ Fix: always set partition before changing image.   │
│                                      │                                                    │
│ Hardcoding pod-0 IP instead of DNS   │ IP changes when pod is rescheduled. DNS name is    │
│ name in replica config               │ stable. Always use DNS: pod-0.svc.namespace...     │
│                                      │                                                    │
│ Not handling the "empty PVC"         │ Replica pod starts without data, connects to a     │
│ case in init container               │ primary that has not finished initializing. Use    │
│                                      │ a flag file (e.g. /data/initialized) to check.    │
└──────────────────────────────────────┴────────────────────────────────────────────────────┘
```

---

## Navigation

- Back to: [10_containers README](./README.md)
- Previous: [k8s_pod_runtime_patterns.md](./k8s_pod_runtime_patterns.md)
- Next: [k8s_jobs_and_cronjobs.md](./k8s_jobs_and_cronjobs.md)
- Related: [eks.md](./eks.md) — managed Kubernetes on AWS, node groups, Fargate
- Related: [terraform_to_k8s_variable_flow.md](./terraform_to_k8s_variable_flow.md) — how Terraform outputs wire into K8s manifests
