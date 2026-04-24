# Linux OS Concepts for Containers — What Actually Happens Under the Hood

A container is not magic. It is a Linux process with a restricted view. The kernel running your containers is the same kernel running your laptop — there is no separate OS inside the container image. What changes is what that process is *allowed to see and do*. Understanding the Linux OS primitives that enforce that restriction is what separates engineers who debug container issues from engineers who guess at them.

---

## The Big Picture: What Makes a Container

```
┌──────────────────────────────────────────────────────────────────────┐
│                         HOST KERNEL                                  │
│                                                                      │
│  Linux Namespaces   →  what you CAN SEE                              │
│    pid namespace    →  your PID tree (PID 1 = your entrypoint)       │
│    net namespace    →  your network interfaces (eth0, lo)            │
│    mnt namespace    →  your filesystem mount points                  │
│    uts namespace    →  your hostname                                 │
│    ipc namespace    →  your inter-process communication              │
│    user namespace   →  your UID/GID mapping                         │
│                                                                      │
│  cgroups (v2)       →  what you CAN USE                              │
│    cpu.max          →  CPU bandwidth limit                           │
│    memory.max       →  memory hard limit                             │
│    blkio.weight     →  I/O weight                                    │
│    pids.max         →  max number of processes                       │
│                                                                      │
│  seccomp / AppArmor →  what you CAN CALL                            │
│    syscall filter   →  blocks dangerous kernel calls                 │
│                                                                      │
│  Overlay Filesystem →  what you CAN WRITE                           │
│    lowerdir = image layers (read-only)                               │
│    upperdir = container writes (ephemeral)                           │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Linux Processes: The Foundation

Everything in a container starts here. A process is a running program — it has a PID, memory space, open file descriptors, and an environment.

### How processes are born

```
kernel boots
    └── PID 1: init (systemd on most Linux distros)
             └── forks child processes
                      └── each child inherits:
                           - environment variables
                           - open file descriptors
                           - working directory
                           - UID/GID
```

`fork()` creates a copy of the parent process. `exec()` replaces the current process image with a new program. Together they are how every process on Linux starts:

```
shell runs: python app.py
  → shell calls fork()     → creates child copy of shell
  → child calls exec()     → replaces itself with python interpreter
  → python runs app.py
  → inherits shell's env vars, UID, working directory
```

**Why this matters for containers:** When Docker/containerd starts your container, it calls `clone()` (a `fork` variant that creates namespaces) then `exec()` with your `ENTRYPOINT`. Your process is PID 1 inside the container's PID namespace. That has consequences — more below.

---

## Environment Variables: The OS Mechanism

Environment variables are not a shell feature. They are a kernel feature. Every process has an environment block — a flat list of `KEY=VALUE` strings stored in the process's memory space.

```
┌─────────────────────────────────────────────────┐
│  Process Memory                                 │
│                                                 │
│  Stack                                          │
│  Heap                                           │
│  Code (text segment)                            │
│  Environment block ← KEY=VALUE strings here     │
│    PATH=/usr/bin:/usr/local/bin                 │
│    DB_HOST=xxx.rds.amazonaws.com                │
│    APP_ENV=prod                                 │
│    HOME=/root                                   │
└─────────────────────────────────────────────────┘
```

```bash
# See your current process environment:
env                         # all env vars
printenv DB_HOST            # specific var
cat /proc/$$/environ        # raw kernel view (null-byte separated)
cat /proc/1/environ | tr '\0' '\n'  # PID 1's environment (inside container)
```

**Inheritance:** Child processes inherit the parent's environment. This is how Kubernetes-injected env vars reach your application — kubelet sets them when starting the container process, your app inherits them.

**Modification:** `os.environ["KEY"] = "value"` in Python modifies the current process's env. It does NOT affect the parent process or sibling processes. Env vars are per-process, not global.

```python
import os

# Reading — always preferred over hardcoding
db_host = os.environ["DB_HOST"]           # raises KeyError if missing
db_port = os.environ.get("DB_PORT", "5432")  # with default

# All env vars as dict
all_config = dict(os.environ)

# Check presence
if "FEATURE_FLAG" in os.environ:
    enable_feature()
```

---

## The Filesystem: Layers and Mounts

### Overlay filesystem (how container images work)

A container image is a stack of read-only layers. When the container runs, a writable layer is added on top. This is implemented with OverlayFS:

```
┌─────────────────────────────────────────────────┐
│  upperdir (writable, ephemeral)                 │  ← your container writes here
│    /tmp/myfile.txt                              │
│    /app/cache/                                  │
├─────────────────────────────────────────────────┤
│  lowerdir layer 3 (read-only)                   │  ← your app code
│    /app/main.py                                 │
├─────────────────────────────────────────────────┤
│  lowerdir layer 2 (read-only)                   │  ← pip install results
│    /usr/local/lib/python3.11/                   │
├─────────────────────────────────────────────────┤
│  lowerdir layer 1 (read-only)                   │  ← base OS (ubuntu:22.04)
│    /usr/bin/, /lib/, /etc/                      │
└─────────────────────────────────────────────────┘
        ↑ unified view presented to container
```

**What this means practically:**
- Writing inside the container only modifies the upper layer — it is gone when the container stops
- Logs written to the container filesystem are lost on restart — use stdout/stderr or a mounted volume
- `docker build` each `RUN` instruction creates a new read-only layer — minimize layers for smaller images

### Volumes and mounts

Kubernetes mounts ConfigMaps and Secrets by bind-mounting files into the container's namespace:

```
Host (kubelet managed):
  /var/lib/kubelet/pods/abc123/volumes/kubernetes.io~secret/app-secrets/
    ├── DB_PASSWORD   (file, content = the secret value)
    └── API_KEY

Container sees:
  /etc/secrets/
    ├── DB_PASSWORD
    └── API_KEY

Implemented as: bind mount of host path into container namespace
```

```bash
# Inside the container — verify mounts
mount | grep secrets         # shows bind mount details
ls -la /etc/secrets/         # list mounted files
cat /etc/secrets/DB_PASSWORD # read the value
```

**Volume types that matter:**

| Type | Lifecycle | Use case |
|---|---|---|
| `emptyDir` | Pod lifetime | Sharing data between containers in same pod |
| `hostPath` | Node lifetime | DaemonSets needing host access (logs, metrics) |
| `persistentVolumeClaim` | Independent | Databases, stateful apps |
| `configMap` | ConfigMap object | App configuration files |
| `secret` | Secret object | Passwords, TLS certs |
| `projected` | Multiple sources | Merge configMap + secret + serviceAccountToken |

---

## PID 1: The Init Problem

Inside a container, your entrypoint is PID 1. On a normal Linux system, PID 1 is `init`/`systemd`, which has special responsibilities. When you run your app directly as PID 1, two problems emerge.

**Problem 1 — Signal handling:**

The kernel sends `SIGTERM` to PID 1 when it wants to stop the container (graceful shutdown). Most application runtimes — Python, Node, Java — install a default SIGTERM handler. But if your entrypoint is a shell script (`CMD ["./start.sh"]`), the shell receives SIGTERM. By default, **bash does not forward signals to its children**. Your app never gets the signal and the container is killed with SIGKILL after the grace period.

```
Container stop signal: SIGTERM → PID 1
  ✗ PID 1 = bash script → bash ignores or doesn't forward → app killed hard
  ✓ PID 1 = app binary  → app handles SIGTERM → graceful shutdown
```

**Fix 1:** Use `exec` in shell scripts so the app replaces the shell process:

```bash
#!/bin/sh
# Bad — bash is PID 1, python is a child
python app.py

# Good — exec replaces bash with python, python becomes PID 1
exec python app.py
```

**Fix 2:** Use a minimal init system:

```dockerfile
# tini handles signal forwarding and zombie reaping
FROM ubuntu:22.04
RUN apt-get install -y tini
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["python", "app.py"]
```

**Problem 2 — Zombie processes:**

PID 1 is responsible for `wait()`-ing on orphaned child processes. If your app spawns subprocesses and they exit, they become zombies (completed but not reaped) until PID 1 calls `wait()`. Most application code does not do this. Over time, zombie accumulation wastes PIDs and shows up as processes stuck in `Z` state.

```bash
# Inside container — check for zombies
ps aux | grep Z
```

`tini` solves both problems. Kubernetes 1.20+ enables a built-in init process via `shareProcessNamespace` or the `initContainers` mechanism.

---

## Users, UID/GID, and Container Security

Linux permissions are based on UID (user ID) and GID (group ID) — numeric values, not names. User names are just a convenience layer that `/etc/passwd` maps to UIDs.

**The default danger:** Most container images run as UID 0 (root). Inside the container, this feels normal. But if the container escapes (via a kernel exploit), that process has root on the host.

```dockerfile
# Dockerfile best practice — create and use a non-root user
FROM python:3.11-slim

RUN groupadd -r appgroup && useradd -r -g appgroup -u 1001 appuser

WORKDIR /app
COPY --chown=appuser:appgroup . .
RUN pip install -r requirements.txt

USER appuser                     # ← switch to non-root
CMD ["python", "app.py"]
```

```yaml
# Pod spec — enforce non-root at Kubernetes level
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  runAsGroup: 1001
  fsGroup: 1001                  # ← GID for volume mounts (files owned by this group)
  readOnlyRootFilesystem: true   # ← prevent writes to container filesystem
```

**fsGroup:** When a volume is mounted, Kubernetes `chown`s the mount directory to this GID, so the container process can read it without being root.

```
Secret mounted at /etc/secrets/
  Owner: root:1001 (fsGroup)
  Permissions: 0640
  → app running as UID 1001, GID 1001 can read ✓
```

---

## Signals: How Processes Communicate

Signals are asynchronous notifications sent from the kernel or other processes. They are the OS mechanism for stopping, pausing, and reloading processes.

```
┌────────────────────────────────────────────────────────────────┐
│  Signal      │  Number │  Default action  │  Container use     │
├────────────────────────────────────────────────────────────────┤
│  SIGTERM     │  15     │  Terminate       │  graceful stop     │
│  SIGKILL     │  9      │  Force kill*     │  hard stop         │
│  SIGINT      │  2      │  Terminate       │  Ctrl+C            │
│  SIGHUP      │  1      │  Terminate       │  reload config     │
│  SIGUSR1/2   │  10/12  │  Terminate       │  custom handlers   │
└────────────────────────────────────────────────────────────────┘
* SIGKILL cannot be caught or ignored — the kernel kills the process directly
```

**Kubernetes shutdown sequence:**

```
kubectl delete pod / rolling update triggers
  │
  ├── Pod moves to Terminating
  ├── Kubernetes sends SIGTERM to PID 1
  ├── preStop hook runs (if configured)  ← up to terminationGracePeriodSeconds
  ├── App has terminationGracePeriodSeconds (default 30s) to finish in-flight requests
  └── After grace period: SIGKILL
```

**Handling SIGTERM in Python:**

```python
import signal
import sys
import time

def graceful_shutdown(signum, frame):
    print("SIGTERM received — finishing in-flight requests")
    # close DB connections, flush buffers, etc.
    sys.exit(0)

signal.signal(signal.SIGTERM, graceful_shutdown)
signal.signal(signal.SIGINT, graceful_shutdown)

# Application main loop
while True:
    process_request()
```

---

## /proc: The Kernel's Live Interface

`/proc` is a virtual filesystem — it does not exist on disk. The kernel generates it on the fly. It exposes every running process's internal state.

```bash
# Inspect your own process (PID $$)
cat /proc/$$/status          # name, state, PID, memory usage
cat /proc/$$/environ         # environment variables (null-separated)
cat /proc/$$/cmdline         # how the process was started
cat /proc/$$/fd/             # open file descriptors
cat /proc/$$/maps            # memory-mapped regions

# System-wide
cat /proc/meminfo            # RAM usage
cat /proc/cpuinfo            # CPU details
cat /proc/net/dev            # network interface stats
cat /proc/mounts             # all active mounts
```

**Inside a container:** `/proc` reflects the container's PID namespace, not the host. PID 1 is your app. You won't see host processes. This is the namespace working correctly.

```bash
# Kubernetes — exec into container and inspect
kubectl exec -it pod-name -- cat /proc/1/environ | tr '\0' '\n'
# ← shows exactly what env vars your app received
```

---

## cgroups: Resource Limits That Are Actually Enforced

cgroups (control groups) limit how much CPU, memory, and I/O a process and its children can use. Kubernetes translates `resources.requests` and `resources.limits` directly into cgroup settings.

```yaml
# Pod spec
resources:
  requests:
    cpu: "250m"        # 250 millicores = 0.25 CPU — used for scheduling
    memory: "256Mi"    # 256 MiB — minimum guaranteed
  limits:
    cpu: "500m"        # hard CPU throttle at 0.5 CPU
    memory: "512Mi"    # hard memory limit — exceed this = OOMKilled
```

```
Kubernetes translation:
  resources.limits.cpu=500m    → cgroup cpu.max = 50000 100000
                                  (50ms out of every 100ms)
  resources.limits.memory=512Mi → cgroup memory.max = 536870912
```

**OOMKilled:** When a container exceeds its memory limit, the kernel OOM killer sends SIGKILL immediately — no grace period, no SIGTERM. You see `OOMKilled: true` in `kubectl describe pod`. The fix is either increase the memory limit or find the memory leak.

```bash
# Check if a pod was OOMKilled
kubectl describe pod pod-name | grep -A5 OOMKilled
kubectl get pod pod-name -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
```

**CPU throttling:** Unlike memory, exceeding the CPU limit does not kill the process. The kernel throttles it — the process gets less CPU time and slows down. A container that is CPU-throttled shows high latency but stays alive.

---

## Namespaces: Isolation Layers

Each namespace type isolates one aspect of the OS view.

```bash
# See namespaces of a process
ls -la /proc/$$/ns/

# Output:
# ipc  -> ipc:[4026531839]
# mnt  -> mnt:[4026531840]
# net  -> net:[4026531993]
# pid  -> pid:[4026531836]
# uts  -> uts:[4026531838]
# user -> user:[4026531837]
```

| Namespace | Isolates | Container implication |
|---|---|---|
| `pid` | Process IDs | Container sees PID 1 as own init |
| `net` | Network interfaces, routing tables | Each pod gets its own `eth0` |
| `mnt` | Mount points | Container's `/` is its own filesystem |
| `uts` | Hostname, NIS domain | Container has its own hostname |
| `ipc` | SysV IPC, POSIX message queues | Containers can't IPC across namespaces by default |
| `user` | UID/GID mappings | UID 0 inside maps to unprivileged UID outside |

**Kubernetes pod = shared namespaces:** All containers in the same pod share:
- `net` namespace → same network interface, same IP, same port space
- `ipc` namespace → can communicate via shared memory
- `pid` namespace → optional (`shareProcessNamespace: true`) — enables one container to inspect another's processes

---

## File Descriptors and stdin/stdout/stderr

Every process has a file descriptor table. Three are always open by default:

```
FD 0 → stdin  (reading input)
FD 1 → stdout (normal output)
FD 2 → stderr (error output)
```

**Kubernetes logging** is built on this: anything your container writes to stdout/stderr is captured by the kubelet and stored at `/var/log/pods/` on the node. `kubectl logs` reads from there.

```python
# Python — stdout vs stderr
import sys

print("Normal log line")                      # → stdout → kubectl logs
print("Error occurred", file=sys.stderr)     # → stderr → kubectl logs (same stream)
sys.stdout.flush()                            # ← important in containers: disable buffering
```

**stdout buffering:** Python buffers stdout by default. In a container, this means lines are not written until the buffer fills. If the container crashes, the buffer is lost. Fix:

```dockerfile
ENV PYTHONUNBUFFERED=1   # ← disables Python's stdout buffering
# or run: python -u app.py
```

---

## The /etc/hosts and DNS Inside a Container

Each pod gets its own `/etc/hosts` (managed by kubelet) and DNS resolver pointing to the cluster DNS (CoreDNS):

```
/etc/hosts (inside pod):
  127.0.0.1   localhost
  10.244.1.5  my-pod-name my-pod-name.my-namespace.pod.cluster.local

/etc/resolv.conf (inside pod):
  nameserver 10.96.0.10        ← CoreDNS service IP
  search my-namespace.svc.cluster.local svc.cluster.local cluster.local
  options ndots:5
```

**ndots:5** means: if a hostname has fewer than 5 dots, DNS tries appending the search domains first before trying the hostname as-is. This is why `db-service` resolves to `db-service.my-namespace.svc.cluster.local`.

```bash
# Debug DNS inside a container
kubectl exec -it pod-name -- cat /etc/resolv.conf
kubectl exec -it pod-name -- nslookup db-service
kubectl exec -it pod-name -- nslookup db-service.production.svc.cluster.local
```

---

## Common OS-Level Debugging Commands (Inside a Running Container)

```bash
# Which process is PID 1?
ps -p 1

# All processes (if ps is available)
ps aux

# Environment of PID 1
cat /proc/1/environ | tr '\0' '\n'

# What files are open?
ls -la /proc/1/fd/

# What's mounted?
cat /proc/mounts

# Memory usage
cat /proc/meminfo | head -20

# Network interfaces
ip addr
ip route

# Who am I?
id              # UID, GID, groups
whoami

# Filesystem check
df -h           # disk space
mount           # all mounts

# Test DNS
nslookup kubernetes.default.svc.cluster.local

# Test connectivity
curl -v http://other-service:8080/health
wget -qO- http://other-service:8080/health
```

---

## Practical Checklist: OS Issues in Production Containers

| Symptom | Likely OS cause | Investigation |
|---|---|---|
| Container OOMKilled | Memory limit exceeded | `kubectl describe pod` → `OOMKilled`. Increase limit or fix leak |
| High latency spikes | CPU throttling | `kubectl top pod` + check if CPU limit << CPU request |
| Graceful shutdown not working | Signal not reaching app | Ensure `exec` in shell scripts; use `tini` |
| Zombie processes accumulating | No PID 1 init | Add `tini` as init; or `shareProcessNamespace` |
| Log lines missing or delayed | stdout buffering | Set `PYTHONUNBUFFERED=1` or use `-u` flag |
| Permission denied on mounted volume | UID/GID mismatch | Set `fsGroup` in `securityContext` to match app's GID |
| Can't write to filesystem | `readOnlyRootFilesystem: true` | Mount an `emptyDir` for writable paths like `/tmp` |
| DNS not resolving service names | ndots/search domain issue | Use FQDN: `service.namespace.svc.cluster.local` |
| Container starts then immediately exits | App exits with non-zero code | `kubectl logs --previous pod-name` to see last output |
| `exec: format error` on startup | Wrong CPU architecture | Image built for amd64, running on arm64 (Apple Silicon nodes) |

---

## Navigation

**Related:**
- [Signals](./05_processes/signals.md) — Signal handling deep dive
- [Process Management](./05_processes/process_management.md) — fork, exec, jobs
- [Filesystem](./02_filesystem/directory_structure.md) — Linux filesystem structure
- [Users and Permissions](./04_users_permissions/users_and_groups.md) — UID/GID
- [Variable Flow: Terraform → Pod](../04_Terraform/04_variables_outputs/terraform_to_k8s_variable_flow.md) — How config reaches containers
- [EKS](../03_AWS/10_containers/eks.md) — Kubernetes on AWS
