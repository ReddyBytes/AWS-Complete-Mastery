# Kubernetes Jobs and CronJobs — Industry Guide

A Deployment is a store that stays open — its job is to keep a fixed number of identical processes running forever, restarting anything that crashes. A Job is a postal delivery — it has a specific package to drop off, and once it is delivered, the worker goes home. You do not want your postal worker standing on your doorstep indefinitely after handing you the parcel. That is the fundamental difference: **Jobs run to completion**, and Kubernetes tracks that completion.

A CronJob is the same postal worker, but on a recurring schedule: every morning at 9am, a new delivery is made. Each delivery is its own Job, with its own lifecycle.

---

## 1. Why Jobs Exist

Before Jobs, teams ran batch workloads by creating a Deployment with `replicas: 1` and either waiting for it to finish or writing custom logic to detect completion. This was fragile — if the pod crashed midway, the Deployment would restart it, but without any concept of "how many times has this run" or "did it finish successfully."

Jobs bring three things Deployments cannot provide:

```
┌──────────────────────────────────────────────────────────────────┐
│  WHAT JOBS ADD OVER DEPLOYMENTS                                  │
│                                                                  │
│  1. Completion tracking                                          │
│     Kubernetes knows when the work is done (exit code 0)        │
│                                                                  │
│  2. Retry budget                                                 │
│     backoffLimit controls how many times to retry on failure    │
│     before giving up and marking the Job as Failed              │
│                                                                  │
│  3. Parallelism model                                            │
│     Run N pods simultaneously, coordinate via completions count  │
│     or a shared work queue                                       │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. Job vs Deployment vs Pod

```
┌──────────────────┬──────────────────┬──────────────────┬──────────────────┐
│                  │ Pod (bare)        │ Deployment        │ Job              │
├──────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Restarts         │ Depends on        │ Always restarts  │ Retries up to    │
│ on failure       │ restartPolicy     │ (that is its job)│ backoffLimit     │
├──────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Tracks           │ No               │ No               │ Yes              │
│ completion       │                  │                  │                  │
├──────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Survives node    │ No               │ Yes (reschedules)│ Yes (reschedules)│
│ failure          │                  │                  │                  │
├──────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Best for         │ One-off debugging│ Long-running     │ Batch work,      │
│                  │ tasks            │ services         │ migrations,      │
│                  │                  │                  │ data processing  │
└──────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

---

## 3. The Job Resource

A complete Job spec with all key fields explained:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-export
  namespace: production
spec:
  completions: 5            # ← total successful pod completions needed
  parallelism: 2            # ← how many pods may run simultaneously
  backoffLimit: 4           # ← max retries before marking Job as Failed
  activeDeadlineSeconds: 600  # ← kill the entire Job after 10 minutes
  ttlSecondsAfterFinished: 3600  # ← auto-delete Job 1 hour after completion
  completionMode: NonIndexed  # ← NonIndexed (default) or Indexed
  template:
    spec:
      restartPolicy: Never  # ← Never or OnFailure — never use Always
      containers:
        - name: exporter
          image: my-org/data-exporter:1.4.2
          command: ["python", "export.py"]
          resources:
            requests:
              cpu: "500m"
              memory: "256Mi"
            limits:
              cpu: "1"
              memory: "512Mi"
```

### Key fields explained

**completions** — how many pods must exit successfully (code 0) before the Job is considered complete. Defaults to 1.

**parallelism** — how many pods may run at the same time. Kubernetes creates pods up to this limit and replaces finished ones until `completions` is reached.

**backoffLimit** — number of pod failures allowed before the Job itself is marked Failed. Each failed pod (exit code non-zero) counts against this budget. Default is 6.

**activeDeadlineSeconds** — a hard wall-clock timeout for the entire Job. When this time expires, all running pods are killed and the Job is marked Failed, regardless of backoffLimit. Use this as a safety net against runaway jobs.

**ttlSecondsAfterFinished** — after the Job reaches terminal state (Complete or Failed), Kubernetes waits this many seconds then garbage-collects the Job and its pods. Without this, completed Jobs accumulate in the cluster.

### restartPolicy: Never vs OnFailure

```
┌──────────────────────────────────────────────────────────────────┐
│  restartPolicy: OnFailure                                        │
│    The SAME pod is restarted in place on the same node.          │
│    Logs from previous attempts may be lost.                      │
│    Pod counter stays at 1 but failure history is harder to see.  │
│                                                                  │
│  restartPolicy: Never  (recommended)                             │
│    A NEW pod is created on failure.                              │
│    Each attempt has its own pod — logs are preserved.            │
│    backoffLimit counts each failed pod.                          │
│    Easier to debug: kubectl logs job/data-export --all-pods      │
└──────────────────────────────────────────────────────────────────┘
```

Prefer `restartPolicy: Never`. You lose nothing except a tiny overhead from new pod scheduling, and you gain full log history per attempt.

---

## 4. Parallelism Patterns

Think of completions and parallelism like a shipping warehouse. `completions` is the total number of packages to ship. `parallelism` is the number of workers on the floor at once.

### Pattern 1: Run once (default)

One pod, must succeed once. The simplest case.

```yaml
spec:
  completions: 1     # ← one successful run needed
  parallelism: 1     # ← one pod at a time
```

Use for: database migrations, one-off data fixes, initial seed jobs.

### Pattern 2: Fixed completion count

Process exactly N items. Kubernetes keeps spawning pods (up to `parallelism` at a time) until N succeed.

```yaml
spec:
  completions: 10    # ← need 10 successful completions
  parallelism: 3     # ← run 3 pods at a time
```

```
┌──────────────────────────────────────────────────────────────────┐
│  FIXED COMPLETION COUNT EXECUTION                                │
│                                                                  │
│  Time 0:  pod-1, pod-2, pod-3 start                             │
│  pod-1 completes ✓  → pod-4 starts  (completions: 1/10)        │
│  pod-2 completes ✓  → pod-5 starts  (completions: 2/10)        │
│  pod-3 fails     ✗  → pod-6 starts  (retry, backoffLimit -1)   │
│  ...                                                             │
│  Until 10 successful completions are recorded.                  │
└──────────────────────────────────────────────────────────────────┘
```

Use for: generating N reports, processing N files from a known list, sending N batches.

### Pattern 3: Work queue

`completions` is unset. Pods consume from an external queue (SQS, RabbitMQ, Redis). Each pod exits 0 when the queue is empty. The Job ends when all running pods exit 0.

```yaml
spec:
  parallelism: 5     # ← 5 workers drain the queue in parallel
                     # ← completions omitted: Job ends when all pods exit 0
```

Use for: asynchronous message processing, event-driven batch work.

---

## 5. Indexed Jobs

In the work queue pattern, pods must coordinate externally (via a queue). **Indexed completion mode** gives each pod a unique index — a number from 0 to `completions - 1` — injected as the `JOB_COMPLETION_INDEX` environment variable. Each pod knows exactly which slice of work it owns without any external coordination.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ml-training-shards
spec:
  completions: 8            # ← 8 shards total
  parallelism: 4            # ← 4 pods run at a time
  completionMode: Indexed   # ← each pod gets a unique index 0–7
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: trainer
          image: my-org/ml-trainer:2.1.0
          command: ["python", "train.py"]
          env:
            - name: SHARD_INDEX
              valueFrom:
                fieldRef:
                  fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
```

Reading the index in Python:

```python
import os

shard_index = int(os.environ["JOB_COMPLETION_INDEX"])  # ← 0-based shard number
total_shards = int(os.environ.get("TOTAL_SHARDS", "8"))

# Each pod processes a non-overlapping slice of the dataset
records_per_shard = total_records // total_shards
start = shard_index * records_per_shard
end   = start + records_per_shard

print(f"Processing shard {shard_index}: records {start}–{end}")
process_records(start, end)
```

Use for: ML training data sharding, parallel report generation with known splits, distributed ETL over a fixed dataset.

---

## 6. The CronJob Resource

A **CronJob** is a factory for Jobs. It wakes up on a schedule and creates a new Job object. The Job then creates pods. The CronJob itself never runs any pods directly.

```
┌──────────────────────────────────────────────────────────────┐
│  CRONJOB HIERARCHY                                           │
│                                                              │
│  CronJob (schedule: "0 2 * * *")                            │
│    └── Job (created at 2:00am)                               │
│          └── Pod-1 (runs the actual work)                    │
│    └── Job (created at 2:00am next day)                      │
│          └── Pod-1                                           │
└──────────────────────────────────────────────────────────────┘
```

Full CronJob spec:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-db-backup
  namespace: production
spec:
  schedule: "0 2 * * *"          # ← cron expression: 2am every day
  timeZone: "America/New_York"   # ← Kubernetes 1.27+ (UTC if omitted)
  concurrencyPolicy: Forbid      # ← Allow | Forbid | Replace
  startingDeadlineSeconds: 300   # ← if missed by 5 min, skip this run
  successfulJobsHistoryLimit: 3  # ← keep last 3 successful Jobs
  failedJobsHistoryLimit: 5      # ← keep last 5 failed Jobs
  jobTemplate:
    spec:
      backoffLimit: 2
      activeDeadlineSeconds: 3600  # ← kill if backup takes > 1 hour
      ttlSecondsAfterFinished: 86400  # ← clean up after 24 hours
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: backup
              image: my-org/db-backup:3.0.1
              command: ["bash", "backup.sh"]
```

### Cron expression format

The same five-field format as Linux cron:

```
┌──────────────────────────────────────────────────────────────┐
│  ┌─────── minute      (0–59)                                 │
│  │ ┌───── hour        (0–23)                                 │
│  │ │ ┌─── day of month (1–31)                                │
│  │ │ │ ┌─ month        (1–12)                                │
│  │ │ │ │ ┌ day of week  (0–6, Sun=0)                         │
│  │ │ │ │ │                                                   │
│  0 2 * * *    →  2:00am every day                            │
│  */15 * * * * →  every 15 minutes                            │
│  0 9 * * 1-5  →  9:00am Monday–Friday                        │
│  0 0 1 * *    →  midnight on the 1st of each month           │
└──────────────────────────────────────────────────────────────┘
```

### concurrencyPolicy

What happens when the previous Job is still running when the next scheduled run fires:

```
Allow   → start a new Job anyway (two Jobs run in parallel)
Forbid  → skip this run; wait for the current Job to finish
Replace → kill the current Job and start a fresh one
```

`Forbid` is the safest default for most batch jobs — you do not want two database backups running simultaneously.

### startingDeadlineSeconds

If the Kubernetes control plane was down (upgrade, outage) and a cron run was missed, `startingDeadlineSeconds` defines how late it is still acceptable to start. If the deadline passes, the missed run is counted as a failure. If more than 100 missed runs accumulate, the CronJob stops scheduling entirely — this is a known edge case when the control plane is down for a long period.

### timeZone

Before Kubernetes 1.27, all CronJob schedules were evaluated in UTC. The `timeZone` field (1.27+) accepts IANA timezone strings. Without it, `"0 9 * * 1-5"` fires at 9am UTC, which is 4am or 5am Eastern depending on DST — a common production surprise.

---

## 7. Common CronJob Patterns

### Database backup at 2am

```yaml
schedule: "0 2 * * *"
concurrencyPolicy: Forbid          # ← never run two backups simultaneously
activeDeadlineSeconds: 3600        # ← fail if backup takes more than 1 hour
```

### Report generation at 9am weekdays

```yaml
schedule: "0 9 * * 1-5"
timeZone: "America/Chicago"        # ← fire at 9am Chicago time
concurrencyPolicy: Forbid
```

### Cache invalidation every 15 minutes

```yaml
schedule: "*/15 * * * *"
concurrencyPolicy: Allow           # ← short jobs; overlap is acceptable
activeDeadlineSeconds: 60          # ← must finish within 1 minute
```

### Cleanup job with TTL

```yaml
schedule: "0 3 * * *"
jobTemplate:
  spec:
    ttlSecondsAfterFinished: 3600  # ← delete Job record after 1 hour
    template:
      spec:
        restartPolicy: Never
        containers:
          - name: cleanup
            image: my-org/cleanup:1.0.0
            command: ["python", "cleanup_old_records.py", "--days=30"]
```

---

## 8. Job Failure Handling

### backoffLimit and retry behavior

Each time a pod exits with a non-zero code, Kubernetes increments the failure counter. When the counter exceeds `backoffLimit`, the Job is marked Failed and no more pods are created.

The retry delay follows exponential backoff: 10s, 20s, 40s, 80s... capped at 6 minutes. This is automatic — you do not configure it.

```
┌────────────────────────────────────────────────────────────────┐
│  backoffLimit: 3 (allow 3 failures total)                      │
│                                                                │
│  Attempt 1 fails  → wait 10s  → retry                         │
│  Attempt 2 fails  → wait 20s  → retry                         │
│  Attempt 3 fails  → wait 40s  → retry                         │
│  Attempt 4 fails  → Job marked Failed, no more retries         │
└────────────────────────────────────────────────────────────────┘
```

### Pod failure policy (Kubernetes 1.26+)

**PodFailurePolicy** lets you distinguish between failure types and handle them differently:

```yaml
spec:
  backoffLimit: 6
  podFailurePolicy:
    rules:
      - action: FailJob             # ← immediately fail the whole Job
        onExitCodes:
          operator: In
          values: [42]              # ← exit code 42 means unrecoverable error
      - action: Ignore              # ← don't count this against backoffLimit
        onPodConditions:
          - type: DisruptionTarget  # ← pod was evicted (node pressure, etc.)
```

This prevents spending your retry budget on infrastructure disruptions that are not your application's fault.

---

## 9. TTL for Automatic Cleanup

Completed Jobs and their pods remain in the cluster until you delete them. In a busy production cluster with many CronJobs, this accumulates thousands of completed pod records — they do not consume compute, but they clutter `kubectl get pods` output and slow down API server list operations.

`ttlSecondsAfterFinished` solves this automatically:

```yaml
spec:
  ttlSecondsAfterFinished: 3600   # ← delete Job (and its pods) 1 hour after completion
```

The TTL controller runs in the background and garbage-collects Jobs that have passed their deadline. Setting this on the Job spec is the recommended approach. On CronJobs, set it in `jobTemplate.spec`.

Complement this with `successfulJobsHistoryLimit` and `failedJobsHistoryLimit` on CronJobs, which limit how many past Job objects the CronJob controller itself retains.

---

## 10. Triggering Jobs from Application Code

Production systems often need to fire off a batch Job in response to an application event — a user upload, a webhook, a message on a queue. The Kubernetes API lets you create Job objects programmatically.

The cleanest pattern on AWS EKS is **IRSA (IAM Roles for Service Accounts)** combined with the Kubernetes client library. Your application pod assumes an IAM role that has permission to create Jobs in its own namespace.

```python
from kubernetes import client, config

# In-cluster config picks up the service account token automatically
config.load_incluster_config()                     # ← runs inside a pod

batch_v1 = client.BatchV1Api()

job = client.V1Job(
    api_version="batch/v1",
    kind="Job",
    metadata=client.V1ObjectMeta(
        name=f"export-{event_id}",                 # ← unique name per trigger
        namespace="production",
    ),
    spec=client.V1JobSpec(
        backoff_limit=3,
        ttl_seconds_after_finished=3600,
        template=client.V1PodTemplateSpec(
            spec=client.V1PodSpec(
                restart_policy="Never",
                containers=[
                    client.V1Container(
                        name="exporter",
                        image="my-org/data-exporter:1.4.2",
                        command=["python", "export.py", "--event", event_id],
                    )
                ],
            )
        ),
    ),
)

batch_v1.create_namespaced_job(namespace="production", body=job)
```

The service account bound to the triggering pod needs a Role with these permissions:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: job-creator
  namespace: production
rules:
  - apiGroups: ["batch"]
    resources: ["jobs"]
    verbs: ["create", "get", "watch", "list"]  # ← create + monitor
```

---

## 11. Common Mistakes

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Mistake                          │ Fix                                │
├───────────────────────────────────┼────────────────────────────────────┤
│ restartPolicy: Always on a Job    │ Jobs require Never or OnFailure.   │
│ (copy-paste from Deployment)      │ Always is rejected by the API.     │
├───────────────────────────────────┼────────────────────────────────────┤
│ No backoffLimit set; Job retries  │ Set backoffLimit explicitly.       │
│ forever on transient errors       │ Default is 6 — often too high.     │
├───────────────────────────────────┼────────────────────────────────────┤
│ CronJob schedule in UTC but team  │ Add timeZone field (k8s 1.27+) or  │
│ assumes local timezone            │ convert schedule to UTC manually.  │
├───────────────────────────────────┼────────────────────────────────────┤
│ No activeDeadlineSeconds; runaway │ Always set a deadline on Jobs that  │
│ Job consumes cluster resources    │ should complete in bounded time.    │
├───────────────────────────────────┼────────────────────────────────────┤
│ No ttlSecondsAfterFinished; API   │ Set TTL on all Jobs. Set           │
│ server slows from stale objects   │ successfulJobsHistoryLimit: 3 on   │
│                                   │ CronJobs.                          │
├───────────────────────────────────┼────────────────────────────────────┤
│ concurrencyPolicy: Allow on slow  │ Use Forbid for jobs that must not  │
│ jobs that sometimes overlap       │ run in parallel (backups, reports).│
├───────────────────────────────────┼────────────────────────────────────┤
│ Control plane outage; 100+        │ Set startingDeadlineSeconds and    │
│ missed CronJob runs; scheduling   │ monitor for missed schedules.      │
│ stops silently                    │                                    │
├───────────────────────────────────┼────────────────────────────────────┤
│ Non-unique Job name when          │ Include a timestamp or event ID in │
│ triggering from application code  │ the Job name. Names must be unique │
│                                   │ within a namespace.                │
└───────────────────────────────────┴────────────────────────────────────┘
```

---

## Navigation

- Back to: [Containers README](../README.md)
- Previous: [Kubernetes Pod Runtime Patterns](k8s_pod_runtime_patterns.md)
- Next: [Hooks Across the Stack](hooks_across_the_stack.md)
- Related: [EKS](eks.md)
