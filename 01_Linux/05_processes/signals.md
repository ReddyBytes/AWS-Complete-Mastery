# Linux — Signals

> Signals are how you communicate with running processes. `Ctrl+C` sends a signal. `kill` sends a signal. Understanding signals means you can stop, pause, reload, and debug any process.

---

## 1. The Analogy — Tapping Someone on the Shoulder

A signal is like tapping a running process on the shoulder and saying something:

- "Stop what you're doing" — SIGTERM
- "Stop RIGHT NOW" — SIGKILL
- "Pause for a moment" — SIGSTOP
- "Your config file changed, reload it" — SIGHUP
- "Hey, I just pressed Ctrl+C" — SIGINT

The process receives the tap and decides how to respond (except SIGKILL — that one can't be ignored).

---

## 2. The Most Important Signals

| Number | Name | Meaning | Can be caught? |
|--------|------|---------|----------------|
| 1 | SIGHUP | Hangup — reload config | Yes |
| 2 | SIGINT | Interrupt (Ctrl+C) | Yes |
| 3 | SIGQUIT | Quit + core dump | Yes |
| 9 | SIGKILL | Kill immediately | **No** |
| 15 | SIGTERM | Terminate gracefully | Yes |
| 18 | SIGCONT | Continue (resume stopped) | No |
| 19 | SIGSTOP | Stop (pause) | **No** |
| 20 | SIGTSTP | Terminal stop (Ctrl+Z) | Yes |

**SIGKILL (9) and SIGSTOP (19) cannot be caught, blocked, or ignored.** The kernel handles them directly.

---

## 3. Sending Signals with `kill`

Despite the name, `kill` sends ANY signal — not just "kill":

```bash
# Send SIGTERM (graceful shutdown) — DEFAULT
kill 4821
kill -15 4821
kill -TERM 4821

# Send SIGKILL (force kill — no cleanup)
kill -9 4821
kill -KILL 4821

# Send SIGHUP (reload configuration)
kill -1 4821
kill -HUP 4821

# Send SIGSTOP (pause a process)
kill -19 4821
kill -STOP 4821

# Send SIGCONT (resume a paused process)
kill -18 4821
kill -CONT 4821

# Kill by name
killall nginx              # sends SIGTERM to all nginx processes
killall -HUP nginx         # reload nginx config
pkill -HUP nginx           # same with pkill
```

---

## 4. SIGTERM vs SIGKILL — Always Try SIGTERM First

```
SIGTERM (15):                    SIGKILL (9):
─────────────────────────        ─────────────────────────
"Please stop when you're ready"  "Stop RIGHT NOW"

Process can:                     Process cannot:
  - Finish current request         - Finish anything
  - Save state to disk             - Save state
  - Close connections gracefully   - Close connections
  - Write final log entries        - Write logs
  - Release database connections   - Release DB connections

Use for:                         Use for:
  Normal shutdown                  Hung/frozen process
  Graceful restart                 After SIGTERM didn't work
```

**Best practice:**
```bash
# Step 1: Try graceful shutdown
kill -15 <PID>

# Wait a few seconds
sleep 5

# Step 2: Check if it stopped
ps aux | grep <PID>

# Step 3: If still running, force kill
kill -9 <PID>
```

---

## 5. SIGHUP — The Reload Signal

Originally meant "the terminal hung up." Modern services use it to mean **"reload your configuration without restarting."**

```bash
# Reload nginx config without dropping connections
sudo kill -HUP $(pgrep nginx)

# Or using systemctl (recommended)
sudo systemctl reload nginx

# Reload sshd config
sudo kill -HUP $(pgrep sshd)

# Why this matters:
# nginx -s reload        → sends SIGHUP to nginx master
# Nginx reads new config → starts new workers with new config
# Old workers finish their requests then exit
# Zero dropped connections!
```

---

## 6. Keyboard Shortcuts That Send Signals

| Shortcut | Signal | What it does |
|----------|--------|-------------|
| `Ctrl+C` | SIGINT (2) | Interrupt — stop the program |
| `Ctrl+Z` | SIGTSTP (20) | Pause — suspend to background |
| `Ctrl+\` | SIGQUIT (3) | Quit with core dump |
| `Ctrl+D` | Not a signal | EOF — close stdin |

---

## 7. Signal Handling in Scripts

Bash scripts can catch signals and run cleanup code:

```bash
#!/bin/bash

# Clean up temp files even if script is killed with Ctrl+C
cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/myapp_*.tmp
    echo "Done."
}

# Register the cleanup function for these signals
trap cleanup EXIT        # runs on any exit
trap cleanup INT TERM    # runs on Ctrl+C or kill

echo "Starting work..."
# Create temp file
touch /tmp/myapp_$$.tmp

# Do some long work
sleep 100

# If Ctrl+C pressed during sleep, cleanup() runs
```

```bash
# Ignore a signal (useful to prevent accidental Ctrl+C)
trap '' INT

# Reset signal to default behavior
trap - INT
```

---

## 8. Real World Signal Uses

**Zero-downtime nginx config reload:**
```bash
# Test new config first
nginx -t

# If OK, reload (SIGHUP) — no dropped connections
sudo systemctl reload nginx
# Internally: kill -HUP $(cat /var/run/nginx.pid)
```

**Gracefully restart a Python application:**
```bash
# PID stored in file
PID=$(cat /var/run/myapp.pid)

# Graceful stop
kill -TERM $PID

# Wait for it to stop
while kill -0 $PID 2>/dev/null; do
    sleep 1
done

# Start fresh
python3 /opt/myapp/server.py &
```

**Pause and resume a process (useful for debugging):**
```bash
# Pause a running process (it freezes, CPU drops to 0)
kill -STOP 4821

# Do your debugging...
strace -p 4821 &    # won't work while stopped, so resume first

# Resume the process
kill -CONT 4821
```

---

## 9. Viewing Signal Information

```bash
# List all signals
kill -l

# Output:
# 1) SIGHUP  2) SIGINT  3) SIGQUIT  4) SIGILL  5) SIGTRAP
# 6) SIGABRT 7) SIGBUS  8) SIGFPE   9) SIGKILL 10) SIGUSR1
# ...

# Check if a process exists (signal 0 = just check, don't send)
kill -0 4821 && echo "Process exists" || echo "Process not found"
```

---

## 10. Summary

```
Key signals:
  SIGTERM (15)   Graceful shutdown — try this first
  SIGKILL (9)    Force kill — use when SIGTERM doesn't work
  SIGHUP (1)     Reload config — zero-downtime config update
  SIGINT (2)     Ctrl+C — interrupt
  SIGSTOP (19)   Pause — cannot be blocked
  SIGCONT (18)   Resume a stopped process

Sending signals:
  kill -15 PID       graceful
  kill -9 PID        force
  kill -HUP PID      reload
  killall nginx      by name (SIGTERM)
  pkill -HUP nginx   by name (SIGHUP)

In scripts:
  trap cleanup EXIT     run cleanup on exit
  trap '' INT           ignore Ctrl+C
  kill -0 PID           check if process exists
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Process Management](./process_management.md) &nbsp;|&nbsp; **Next:** [Jobs and Daemons →](./jobs_and_daemons.md)

**Related Topics:** [Process Management](./process_management.md) · [Jobs and Daemons](./jobs_and_daemons.md)
