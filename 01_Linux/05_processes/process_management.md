# Linux — Process Management

> Every running program is a process. Managing processes — finding them, monitoring them, stopping them — is a daily DevOps skill.

---

## 1. The Analogy — Restaurant Orders

Think of a Linux server as a restaurant kitchen:

- Each **order** being prepared = a **process**
- The **head chef** = the CPU, executing one order at a time (very fast)
- The **kitchen board** = the process table, tracking every active order
- Each order has a **ticket number** = the **PID** (Process ID)
- The **expeditor** = the kernel scheduler, deciding which order gets cooked next

When too many orders pile up, the kitchen slows down. When an order gets stuck, the chef cancels it.

---

## 2. What Is a Process?

When you run a command, Linux creates a **process**:

```
You type: python3 server.py
              ↓
Linux creates process PID=4821
  - Loads python3 into memory
  - Gives it CPU time to run
  - Assigns it stdin/stdout/stderr
  - Tracks memory usage
  - Links it to parent (your shell, PID=4700)
```

Every process has:

| Property | Description |
|----------|-------------|
| **PID** | Unique Process ID |
| **PPID** | Parent Process ID |
| **UID** | User who owns it |
| **CPU%** | CPU usage percentage |
| **MEM%** | Memory usage percentage |
| **STATE** | Running, Sleeping, Zombie, Stopped |
| **CMD** | The command that started it |

---

## 3. Viewing Processes

### `ps` — Process Snapshot

```bash
# Your current processes
ps

# ALL processes, all users (most common)
ps aux

# ps aux columns: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME CMD

# Find a specific process
ps aux | grep nginx
ps aux | grep python

# Show process tree (parent-child relationships)
ps auxf
pstree
```

### `top` — Live Process Monitor

```bash
top
```

```
top - 10:23:41 up 5 days, load average: 0.52, 0.45, 0.41
Tasks: 142 total, 1 running, 141 sleeping, 0 stopped
%Cpu(s):  2.3 us, 0.7 sy, 0.0 ni, 96.5 id
MiB Mem:   3936.0 total,    231.0 free,   2156.0 used
MiB Swap:      0.0 total,      0.0 free,      0.0 used

PID   USER  PR  NI  VIRT   RES  SHR  S  %CPU  %MEM  TIME+    COMMAND
1234  nginx  20   0  56124  3924 2876  S   0.3   0.1  0:00.45  nginx
5678  alice  20   0 532148 45224 8976  S   1.2   1.1  0:05.12  python3
```

**`top` keyboard shortcuts:**
```
q         quit
k         kill a process (enter PID)
M         sort by memory usage
P         sort by CPU usage
u alice   show only alice's processes
1         toggle per-CPU stats
h         help
```

### `htop` — Better top (install separately)

```bash
sudo apt install htop
htop
# Color-coded, mouse support, easier to read
```

---

## 4. Process States

```
Process States:
──────────────────────────────────────────────────────────
  R  Running     Currently executing on CPU
  S  Sleeping    Waiting for something (I/O, timer, signal)
  D  Uninterruptible Sleep  Waiting for disk I/O (cannot be killed)
  Z  Zombie      Process finished but parent hasn't cleaned it up
  T  Stopped     Paused (Ctrl+Z or SIGSTOP)
──────────────────────────────────────────────────────────
```

**Zombie processes** are harmless (no CPU/memory) but indicate a parent process isn't handling its children properly. They show up as `<defunct>` in ps output.

---

## 5. Finding Processes

```bash
# Find by name
pgrep nginx            # returns PIDs
pgrep -l nginx         # returns PIDs + names
pgrep -u alice         # all alice's processes

# Find process using a specific port
ss -tlnp | grep :80
lsof -i :80            # list open files on port 80

# Find process using a file
lsof /var/log/app.log  # what process has this file open?
fuser /var/log/app.log # same but simpler output

# Find process consuming most CPU
ps aux --sort=-%cpu | head -5

# Find process consuming most memory
ps aux --sort=-%mem | head -5
```

---

## 6. Killing Processes

```bash
# Kill by PID (sends SIGTERM — graceful shutdown)
kill 4821

# Force kill (SIGKILL — immediate, no cleanup)
kill -9 4821

# Kill by name (kills all matching)
killall nginx

# Kill by name (safer — asks before killing)
killall -i nginx

# Kill by name using pkill
pkill nginx
pkill -f "python server.py"   # match full command line

# Kill all processes of a user
pkill -u alice
```

---

## 7. Process Priority (nice)

The **nice value** tells the kernel how much CPU priority to give a process. Range: -20 (highest priority) to 19 (lowest priority). Default is 0.

```bash
# Start a process with lower priority (nicer to other processes)
nice -n 10 python3 heavy_script.py

# Start with higher priority (requires root for negative values)
sudo nice -n -5 critical_service

# Change priority of running process
renice 10 -p 4821       # lower priority of PID 4821
renice -5 -p 4821       # higher priority (needs root)
sudo renice -10 -p 4821

# Check nice values in top: NI column
```

---

## 8. Monitoring System Load

```bash
# Current load averages
uptime
# 10:23:41 up 5 days, load average: 0.52, 0.45, 0.41
#                                    1min  5min  15min

# Load average interpretation:
# On a single-core system:
#   0.5  = 50% busy (fine)
#   1.0  = 100% busy (running at capacity)
#   2.0  = 200% load (processes waiting for CPU)
#
# On a 4-core system: load of 4.0 = 100% capacity

# Check number of cores
nproc
cat /proc/cpuinfo | grep "processor" | wc -l

# Real-time CPU and memory summary
vmstat 1          # update every 1 second
iostat 1          # disk I/O statistics
```

---

## 9. Real World Scenarios

**Server is slow — diagnose:**
```bash
top                           # what's using CPU?
ps aux --sort=-%cpu | head    # top CPU consumers
ps aux --sort=-%mem | head    # top memory consumers
df -h                         # disk full?
free -h                       # out of RAM?
iostat -x 1                   # disk I/O bottleneck?
```

**Application stopped responding:**
```bash
ps aux | grep myapp           # is it running?
pgrep -l myapp                # quick check
lsof -p $(pgrep myapp)        # what files/ports does it have open?
strace -p $(pgrep myapp)      # what system calls is it making? (advanced)
```

**Runaway process eating 100% CPU:**
```bash
top                           # identify the PID
kill -9 <PID>                 # force kill it
# Then investigate: check logs, fix the code
```

---

## 10. Summary

```
Viewing:
  ps aux              list all processes
  top / htop          live view
  pgrep nginx         find PID by name
  ps auxf             process tree

Killing:
  kill <PID>          graceful (SIGTERM)
  kill -9 <PID>       force (SIGKILL)
  killall nginx       kill all by name
  pkill -f "pattern"  kill by command pattern

Priority:
  nice -n 10 cmd      start with lower priority
  renice 10 -p PID    change running process priority

Load:
  uptime              load averages (1/5/15 min)
  nproc               number of CPU cores
  free -h             RAM usage
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Sudo and Root](../04_users_permissions/sudo_and_root.md) &nbsp;|&nbsp; **Next:** [Signals →](./signals.md)

**Related Topics:** [Signals](./signals.md) · [Jobs and Daemons](./jobs_and_daemons.md)
