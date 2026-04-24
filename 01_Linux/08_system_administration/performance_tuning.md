# Linux — Performance Tuning

> Before you touch a single knob, you need to know which knob matters. Performance tuning without measurement is guessing with root access.

---

## 1. Mental Model — Four Bottlenecks

Every Linux performance problem lives in one of four places: **CPU**, **memory**, **disk I/O**, or **network**. The system can only go as fast as its slowest component.

Think of it like a car mechanic. A car that won't start could have a dead battery, a flat tire, no fuel, or a seized engine. A good mechanic measures first — they don't replace the engine when the tires are flat.

```
The Four Bottlenecks:

  ┌─────────────────────────────────────────────────────────┐
  │                  Linux Performance                       │
  │                                                          │
  │   CPU          Memory         Disk I/O       Network    │
  │  (compute)   (data staging)  (persistence)  (transfer)  │
  │                                                          │
  │   Load avg    swap usage      await ms       retrans     │
  │   %steal      page faults     util%          dropped     │
  │   iowait      OOM events      queue depth    backlog     │
  └─────────────────────────────────────────────────────────┘
```

The workflow is always: **measure → identify bottleneck → tune that specific layer → measure again**.

Never tune blindly. A change that helps a database server can destroy a web server.

---

## 2. Measuring Before Tuning

### top / htop — Instant Overview

`top` gives you a live dashboard of CPU and memory consumption across all processes.

```bash
top           # default live view, refreshes every 3s
htop          # color version, mouse support, easier to read
```

Key fields in `top` output:

```
top - 14:23:01 up 42 days,  3:12,  2 users,  load average: 1.45, 1.20, 0.98
Tasks: 212 total,   1 running, 211 sleeping
%Cpu(s): 12.3 us,  2.1 sy,  0.0 ni, 84.1 id,  1.4 wa,  0.0 hi,  0.1 si
MiB Mem :  15987.6 total,   2341.2 free,   9876.4 used,   3770.0 buff/cache

  us  ← user-space CPU (your apps)
  sy  ← kernel CPU (syscalls, I/O handling)
  wa  ← I/O wait — CPU idle waiting for disk  (high = disk bottleneck)
  id  ← idle (want this high when not busy)
  si  ← software interrupt (high = network bottleneck)
```

**Rule of thumb:** if `wa` is consistently above 5-10%, you have a disk I/O bottleneck.

### vmstat 1 — The Single Most Useful Command

`vmstat` shows CPU, memory, swap, and I/O in one line. The `1` makes it refresh every second.

```bash
vmstat 1
```

```
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 2  0      0 241288 102400 8388608    0    0     0   512 1200 3400 12  2 85  1  0

r   ← processes waiting for CPU (runqueue). >nCPUs = CPU-bound
b   ← processes blocked on I/O. >0 = I/O-bound
swpd ← swap in use. Non-zero = memory pressure
si/so ← swap in/out per second. Non-zero = actively swapping (bad)
bi/bo ← blocks read/written per second from/to disk
in   ← interrupts per second
cs   ← context switches per second. Very high = too many threads or syscalls
us/sy/id/wa ← same as top
st   ← steal time (virtualised host stealing your CPU cycles)
```

### iostat -xz 1 — Disk I/O Per Device

```bash
iostat -xz 1
```

```
Device  r/s   w/s  rkB/s  wkB/s  await  r_await  w_await  util%
sda     5.2  45.0  200.0 1800.0   2.50     1.20     2.60   18.0

await  ← average I/O wait time in ms. >20ms on SSD = problem. >50ms on HDD = normal
util%  ← how busy the device is. 100% = saturated (bottleneck)
r/s    ← reads per second
w/s    ← writes per second
```

Use `-z` to suppress devices with zero activity (keeps output clean).

### sar — Historical Performance Data

`sar` (System Activity Reporter) records performance snapshots over time. Unlike `top`, it shows you what happened an hour ago.

```bash
sar -u 1 5          # CPU utilization, 1s interval, 5 samples
sar -r 1 5          # memory utilization
sar -b 1 5          # I/O stats
sar -n DEV 1 5      # network device stats

# Review history from today's log
sar -u -f /var/log/sa/sa$(date +%d)
```

### perf top — CPU Hotspots by Function

`perf top` shows which functions are consuming the most CPU cycles. It's like a stack profiler for the entire system.

```bash
sudo perf top           # live CPU hotspot view
sudo perf top -p 1234   # scope to a single PID
```

### Quick Triage Checklist

```
1. Run vmstat 1 for 30 seconds
   - r > nCPUs?       → CPU bottleneck
   - b > 0 constantly? → I/O bottleneck
   - si/so > 0?        → memory pressure / swapping

2. Check load average vs CPU count
   - load > nCPUs for sustained period → CPU or I/O bound

3. Run iostat -xz 1
   - util% near 100%? → disk is the bottleneck
   - await > 20ms on SSD? → investigate queue depth

4. Check free -h
   - Swap used > 0?   → memory pressure
   - Available < 10%? → possible OOM risk

5. Check ss -s or netstat -s
   - High retransmits? → network bottleneck or packet loss
```

---

## 3. CPU Tuning

### CPU Governors

The **CPU governor** controls how the kernel scales CPU frequency. On a laptop, you want efficiency. On a database server, you want maximum consistent performance.

```bash
# View current governor for all CPUs
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Set performance mode (no frequency scaling, full speed)
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Via cpupower (preferred)
sudo cpupower frequency-set -g performance
```

```
Governors:
  performance   ← always max frequency (production servers, databases)
  powersave     ← always minimum frequency (laptops, idle hosts)
  ondemand      ← scale up on load, scale down on idle (default on many distros)
  schedutil     ← newer, tighter kernel scheduler integration
```

For **production servers under consistent load**, set `performance`. The latency spikes from frequency scaling can cause tail latency problems in databases and APIs.

### taskset — Pin a Process to a CPU Core

**NUMA** (Non-Uniform Memory Access) means CPUs have faster access to memory physically close to them. Pinning a process to specific cores avoids cross-NUMA memory penalties.

```bash
# Run a new process pinned to CPU 0 and 1
taskset -c 0,1 ./my-app

# Pin an existing process (PID 1234) to core 2
taskset -cp 2 1234

# View current CPU affinity of a process
taskset -p 1234

# Show NUMA topology
numactl --hardware
lscpu | grep NUMA
```

### Nice and ionice — Scheduling Priority

**Nice** values control how the CPU scheduler prioritises processes. Range: -20 (highest priority) to +19 (lowest priority). Default is 0.

```bash
# Start a process at low priority (nice +15)
nice -n 15 ./backup-script.sh

# Change priority of running process (PID 1234)
renice -n 10 -p 1234

# Run a process with low I/O priority (class 3 = idle)
ionice -c 3 ./big-scan.sh

# ionice classes:
#   1 = realtime (highest, use with caution)
#   2 = best-effort (default, takes a priority level 0-7)
#   3 = idle (only gets I/O when nothing else needs it)
```

### Context Switches

When `cs` in `vmstat` is very high (hundreds of thousands per second), the kernel is spending time swapping processes in and out rather than doing work. Common causes:

- Too many threads competing for too few CPUs
- Lots of short-lived syscalls
- Locks causing frequent blocking and unblocking

```bash
# View context switches per process
pidstat -w 1

# For a specific PID
cat /proc/1234/status | grep ctxt
```

### CPU Topology

```bash
nproc               # how many logical CPUs are available to the current process
lscpu               # full CPU topology: sockets, cores, threads, NUMA nodes
lscpu | grep -E 'CPU\(s\)|Thread|Core|Socket|NUMA'
```

---

## 4. Memory Tuning

### vm.swappiness

**Swappiness** controls how aggressively the kernel moves memory pages to swap. Range: 0-100.

```bash
# View current value
sysctl vm.swappiness

# Set temporarily
sysctl -w vm.swappiness=1

# Set permanently
echo 'vm.swappiness=1' >> /etc/sysctl.d/99-production.conf
```

```
vm.swappiness values:
  60    ← default (too aggressive for databases)
  10    ← good for general-purpose servers
  1     ← prefer OOM kill over swapping (ideal for databases, Redis)
  0     ← avoid swap unless system is out of memory entirely
          Note: 0 does NOT disable swap — it just avoids it until critical
```

Never set `vm.swappiness=0` on a production database. When under memory pressure, the kernel will prefer to OOM-kill processes rather than swap, which is usually worse than a brief swap episode.

### vm.dirty_ratio and vm.dirty_background_ratio

**Dirty pages** are memory pages that have been written to but not yet flushed to disk. These two settings control how much dirty data is buffered.

```bash
sysctl vm.dirty_ratio                   # view current
sysctl vm.dirty_background_ratio        # view current
```

```
vm.dirty_background_ratio = 5   ← background flush starts at 5% of RAM dirty
vm.dirty_ratio = 10             ← hard limit: writes block at 10% of RAM dirty

For write-heavy workloads (logging, streaming):
  vm.dirty_ratio = 20           ← allow larger write buffer
  vm.dirty_background_ratio = 10

For databases (want predictable fsync latency):
  vm.dirty_ratio = 5
  vm.dirty_background_ratio = 2
```

### Huge Pages

By default, Linux uses 4KB memory pages. **Huge pages** (2MB or 1GB) reduce the overhead of the TLB (Translation Lookaside Buffer), which maps virtual to physical addresses.

```bash
# View huge page status
cat /proc/meminfo | grep -i huge

# View transparent huge pages setting
cat /sys/kernel/mm/transparent_hugepage/enabled
# [always] madvise never
```

```
Transparent Huge Pages (THP):
  always    ← OS decides automatically (default)
  madvise   ← only when app explicitly requests it
  never     ← disabled

When to DISABLE THP (set to madvise or never):
  - Java applications: THP causes unpredictable GC pauses
  - Redis: documented latency spikes with THP enabled
  - Oracle DB: explicitly recommends disabling
```

```bash
# Disable THP (temporary)
echo madvise > /sys/kernel/mm/transparent_hugepage/enabled

# Disable THP (permanent, via rc.local or systemd)
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

### OOM Killer

When the system runs out of memory, the **OOM killer** (Out-of-Memory killer) selects a process and kills it to free memory.

```bash
# View OOM score of a process (higher = more likely to be killed)
cat /proc/1234/oom_score

# Protect a critical process from OOM kill (-1000 = never kill)
echo -1000 > /proc/1234/oom_score_adj

# Make OOM panic instead of kill (for systems where any kill is catastrophic)
sysctl -w vm.panic_on_oom=1

# Disable memory overcommit (OS won't promise memory it can't back)
sysctl -w vm.overcommit_memory=2
```

```
vm.overcommit_memory values:
  0   ← heuristic overcommit (default) — usually fine
  1   ← always allow overcommit (useful for some fork-heavy apps)
  2   ← never overcommit beyond physical + swap (strict, prevents OOM but can reject allocations)
```

### Interpreting free -h

```bash
free -h
```

```
              total        used        free      shared  buff/cache   available
Mem:           15Gi        9.8Gi       230Mi       1.2Gi       5.0Gi       4.5Gi

total       ← total physical RAM
used        ← RAM actively used by processes
free        ← truly unused RAM (usually small — Linux fills this with cache)
buff/cache  ← disk cache (reusable — Linux will reclaim it if needed)
available   ← realistic estimate of free + reclaimable cache
              USE THIS NUMBER, not "free", to know if memory is tight
```

The `available` column is what matters. A server with 230Mi "free" but 4.5Gi "available" is fine.

---

## 5. ulimits — Per-Process Resource Limits

`ulimit` is the per-process **resource fence**. It prevents any single process from consuming all system resources and starving others.

Think of it like a restaurant with a per-table drink limit. No single table can drain the bar, even if they want to.

### Viewing and Setting Limits

```bash
ulimit -a                   # show all current limits for this shell session

ulimit -n 65536             # set max open file descriptors (current session only)
ulimit -u 4096              # set max user processes
ulimit -s unlimited         # set stack size to unlimited
```

### Critical Limits for Production

```
Open file descriptors (-n):
  Default: 1024
  Problem: Nginx, Node.js, and PostgreSQL each open a file descriptor
           per connection. 1024 means ~1000 max connections.
  Fix:     ulimit -n 65536

Max processes (-u):
  Default: varies (~1024-4096)
  Problem: Forking servers (Apache, uWSGI) spawn a process per request.
           Hitting the limit causes "fork: Resource temporarily unavailable"
  Fix:     ulimit -u 65536

Stack size (-s):
  Default: 8192 KB
  Problem: Deep recursion or large stack frames (some Java apps) can stack overflow.
  Fix:     ulimit -s unlimited  (or increase to 65536)
```

### Persisting Limits — /etc/security/limits.conf

Session-level `ulimit` changes disappear on logout. Persist them here:

```bash
# /etc/security/limits.conf

# Format: <domain> <type> <item> <value>
# domain: username, @groupname, or * (all users)
# type:   soft (warning), hard (enforced ceiling)

*           soft    nofile      65536   # ← all users, soft limit for open files
*           hard    nofile      65536   # ← all users, hard limit for open files
nginx       soft    nofile      200000  # ← nginx user specifically
postgres    soft    nofile      65536
postgres    hard    nofile      65536
postgres    soft    nproc       65536
```

For limits to apply on login, `/etc/pam.d/common-session` (or `system-auth` on RHEL) must include:

```
session required pam_limits.so
```

### Limits for systemd Services

`/etc/security/limits.conf` does not apply to systemd-managed services. You must set limits in the unit file:

```ini
# /etc/systemd/system/myservice.service
[Service]
LimitNOFILE=65536       # ← open files
LimitNPROC=65536        # ← max processes
LimitSTACK=infinity     # ← stack size
```

```bash
# After editing the unit file:
systemctl daemon-reload
systemctl restart myservice

# Verify the limits were applied to the running service:
cat /proc/$(pidof myservice)/limits
```

---

## 6. Network Stack Tuning

### The Listen Backlog

When a client connects to a server, the connection sits in a queue while the application calls `accept()`. If the queue fills up, new connections are dropped silently.

```bash
# Maximum size of the accept queue (connections waiting for accept())
sysctl -w net.core.somaxconn=65535

# Maximum size of the SYN queue (half-open connections during handshake)
sysctl -w net.ipv4.tcp_max_syn_backlog=65535
```

For Nginx and similar servers, also set `listen 80 backlog=65535` in the config.

### NIC Receive Queue

```bash
# How many packets the NIC queues before the kernel processes them
sysctl -w net.core.netdev_max_backlog=50000  # ← default 1000, increase for 10G+ NICs
```

High packet loss at the NIC layer (`ifconfig` shows dropped packets) is a sign this is too low.

### TIME_WAIT and Ephemeral Ports

After a TCP connection closes, it lingers in **TIME_WAIT** state for 2x the Maximum Segment Lifetime. Under high connection volume, this exhausts ephemeral ports.

```bash
# Reduce TIME_WAIT duration (default: 60s)
sysctl -w net.ipv4.tcp_fin_timeout=15

# Expand the ephemeral port range (default: 32768-60999)
sysctl -w net.ipv4.ip_local_port_range="1024 65535"   # ← ~64K ports available

# Allow TIME_WAIT sockets to be reused for new connections
sysctl -w net.ipv4.tcp_tw_reuse=1
```

**Note:** `tcp_tw_reuse` is safe for outbound connections (clients). Do not enable `tcp_tw_recycle` — it was removed in kernel 4.12 because it broke connections behind NAT.

### Production sysctl.conf Network Block

```bash
# /etc/sysctl.d/99-production.conf — network section

net.core.somaxconn = 65535              # ← accept queue size
net.ipv4.tcp_max_syn_backlog = 65535   # ← SYN queue size
net.core.netdev_max_backlog = 50000    # ← NIC receive queue

net.ipv4.tcp_fin_timeout = 15          # ← TIME_WAIT timeout (seconds)
net.ipv4.ip_local_port_range = 1024 65535   # ← more ephemeral ports
net.ipv4.tcp_tw_reuse = 1              # ← reuse TIME_WAIT sockets

net.ipv4.tcp_keepalive_time = 300      # ← start keepalive after 5 min idle
net.ipv4.tcp_keepalive_intvl = 30      # ← send keepalive every 30s
net.ipv4.tcp_keepalive_probes = 5      # ← 5 missed keepalives = connection dead

net.core.rmem_max = 134217728          # ← max socket receive buffer (128MB)
net.core.wmem_max = 134217728          # ← max socket send buffer (128MB)
net.ipv4.tcp_rmem = 4096 87380 67108864    # ← TCP receive buffer: min/default/max
net.ipv4.tcp_wmem = 4096 65536 67108864   # ← TCP send buffer: min/default/max
```

---

## 7. Disk I/O Tuning

### I/O Schedulers

The **I/O scheduler** determines the order in which the kernel submits requests to the storage device.

```bash
# Check current scheduler for a device
cat /sys/block/sda/queue/scheduler
# [mq-deadline] kyber bfq none

# Change scheduler (temporary)
echo mq-deadline > /sys/block/sda/queue/scheduler
```

```
Schedulers and when to use them:
  none / noop   ← NVMe SSDs — let the hardware handle ordering
  mq-deadline   ← SATA SSDs, general-purpose servers — low latency, prevents starvation
  bfq           ← desktop, HDD, mixed workloads — fair bandwidth per process
  kyber         ← NVMe with heavy parallelism — latency-focused
```

For **cloud instances with NVMe** (AWS NVMe EBS, instance store), use `none`. The NVMe controller has its own internal queue optimisation. Adding a software scheduler adds latency with no benefit.

For **HDDs**, `mq-deadline` or `bfq` prevents one process from monopolising the drive.

### Readahead

**Readahead** prefetches data from disk before it is requested. Good for sequential reads (log streaming, large file scans). Bad for random I/O (databases doing random lookups).

```bash
# View current readahead (in 512-byte sectors)
blockdev --getra /dev/sda

# Set readahead to 256 KB (512 sectors × 512 bytes)
blockdev --setra 512 /dev/sda

# Disable readahead for database volumes doing random I/O
blockdev --setra 0 /dev/sda
```

### Mount Options

```bash
# /etc/fstab — performance mount options
/dev/sda1  /data  ext4  defaults,noatime,nodiratime  0 2

# noatime      ← don't update file access time on every read
#                Without this: every `cat file.txt` causes a metadata write
# nodiratime   ← don't update directory access time
#                Redundant if noatime is set, but safe to include
```

`noatime` alone can reduce disk writes by 5-15% on read-heavy workloads.

---

## 8. File Descriptor Limits — System-Wide

The per-process `ulimit` settings are bounded by system-wide kernel parameters.

```bash
# Maximum total open files across ALL processes on the system
sysctl fs.file-max
# Set: sysctl -w fs.file-max=2097152

# Per-process maximum (ceiling for ulimit -n)
sysctl fs.nr_open
# Set: sysctl -w fs.nr_open=1048576

# inotify watches per user (Docker/Kubernetes watchers hit this)
sysctl fs.inotify.max_user_watches
# Set: sysctl -w fs.inotify.max_user_watches=524288

# inotify instances per user
sysctl fs.inotify.max_user_instances
# Set: sysctl -w fs.inotify.max_user_instances=512
```

**Kubernetes nodes** frequently hit `fs.inotify.max_user_watches` when running many pods with file watchers. The symptom is pods failing with "too many open files" or inotify errors in container logs.

---

## 9. sysctl — Applying and Persisting Changes

`sysctl` is the interface for reading and writing kernel parameters at runtime.

```bash
# Read a single parameter
sysctl net.core.somaxconn

# Read all parameters
sysctl -a

# Set a parameter temporarily (lost on reboot)
sysctl -w net.core.somaxconn=65535

# Apply all settings from a specific file
sysctl -p /etc/sysctl.d/99-production.conf

# Apply all files in the sysctl.d directory
sysctl --system
```

### Persisting Changes

```bash
# /etc/sysctl.d/99-production.conf
# Naming: 99- prefix ensures this loads last (overrides distro defaults)

# --- File Descriptors ---
fs.file-max = 2097152
fs.nr_open = 1048576
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512

# --- Virtual Memory ---
vm.swappiness = 1
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.overcommit_memory = 0

# --- Network ---
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 50000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_tw_reuse = 1

# Apply after editing:
# sysctl -p /etc/sysctl.d/99-production.conf
```

---

## 10. Profiling Tools

### strace — System Call Tracing

`strace` intercepts every system call a process makes. Useful for understanding what a process is actually doing when it appears stuck.

```bash
strace -p 1234              # attach to running process
strace -p 1234 -e trace=file  # filter to file-related syscalls only
strace -c ./my-app          # summary: count and time per syscall type
```

Warning: `strace` adds significant overhead. Use briefly in production, not as a long-running monitor.

### lsof — Open Files and Connections

```bash
lsof -p 1234                # all open files and sockets for PID 1234
lsof -i :8080               # which process is using port 8080
lsof -u nginx               # all files opened by the nginx user
lsof | wc -l                # total open file descriptors system-wide
```

### perf stat — Hardware Counters

```bash
perf stat ./my-app          # run and measure hardware counters
perf stat -p 1234           # attach to running process for 5 seconds, then Ctrl-C
```

```
Output shows:
  cache-misses    ← L1/L2/L3 cache efficiency
  branch-misses   ← CPU branch predictor accuracy
  instructions    ← actual compute work done
  cycles          ← clock cycles consumed
```

High `cache-misses` with low `instructions/cycle` indicates memory-bound workload.

---

## 11. Production Tuning Checklist

Apply these to every new production Linux server:

```
[ ] Set CPU governor to performance
    cpupower frequency-set -g performance

[ ] Disable Transparent Huge Pages (for Redis, Java, Oracle)
    echo madvise > /sys/kernel/mm/transparent_hugepage/enabled

[ ] Set vm.swappiness = 1
[ ] Set vm.dirty_ratio and vm.dirty_background_ratio for workload

[ ] Set ulimits for service users in /etc/security/limits.conf
    nofile = 65536 (minimum), 200000 for high-connection services

[ ] Set systemd LimitNOFILE in unit file for all managed services

[ ] Apply network sysctl block:
    net.core.somaxconn = 65535
    net.ipv4.tcp_max_syn_backlog = 65535
    net.ipv4.tcp_fin_timeout = 15
    net.ipv4.ip_local_port_range = 1024 65535
    net.ipv4.tcp_tw_reuse = 1

[ ] Set fs.file-max = 2097152
[ ] Set fs.inotify.max_user_watches = 524288 (Kubernetes nodes)

[ ] Add noatime to /etc/fstab mount options for data volumes

[ ] Set I/O scheduler to none for NVMe, mq-deadline for SATA SSD

[ ] Write all sysctl changes to /etc/sysctl.d/99-production.conf
    and run: sysctl -p /etc/sysctl.d/99-production.conf

[ ] Verify changes survived after reboot
```

---

## 12. Common Mistakes

| Mistake | Why it's wrong | Fix |
|---|---|---|
| `vm.swappiness=0` | Does not disable swap — under memory pressure the kernel may OOM-kill instead, which is often worse than a brief swap | Set to `1` for databases, `10` for general servers |
| Allocating too many static huge pages | Huge pages are non-reclaimable — over-allocation starves normal allocations | Use `vm.nr_hugepages` conservatively; prefer THP with `madvise` |
| Forgetting to persist sysctl changes | `sysctl -w` is runtime-only — a reboot reverts all changes | Always write to `/etc/sysctl.d/99-production.conf` |
| Setting ulimits in limits.conf for systemd services | limits.conf only applies to PAM login sessions, not systemd units | Set `LimitNOFILE` in the systemd unit file |
| Enabling `tcp_tw_recycle` | Removed in kernel 4.12; broke NAT connections | Use `tcp_tw_reuse` instead |
| Tuning before measuring | Without a baseline, you can't tell if tuning helped | Always run `vmstat`, `iostat`, `free` before and after |
| Using `noatime` on / (root) | Can cause subtle issues with some package managers | Apply `noatime` to data volumes, be cautious on root |

---

## Navigation

- Back to: [README](../../../README.md)
- Previous: [Process Management](./process_management.md)
- Next: [Logs and journalctl](./logs_and_journalctl.md)
- Related: [Disk Management](./disk_management.md) | [Linux OS for Containers](./linux_os_for_containers.md)
