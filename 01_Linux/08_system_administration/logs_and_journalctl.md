# Linux — Logs and journalctl

> Logs are the black box recorder of your server. When something breaks at 3am, logs tell you exactly what happened and why.

---

## 1. The Analogy — A Flight Data Recorder

Every commercial plane has a black box that records everything: altitude, speed, engine status, cockpit conversations. If something goes wrong, investigators replay the recording to find out why.

**Server logs are your black box.**

- Application crashed at 2:47am? The logs recorded the last 50 events before it died.
- Someone logged in with your password? `auth.log` recorded the IP address.
- Disk filled up? The logs show which process wrote 50GB of files.

---

## 2. Two Logging Systems

Modern Linux has two logging systems running side by side:

```
Traditional:                    Modern:
  /var/log/*.log                  journald (systemd's logger)
  Text files on disk              Binary format, queryable
  rsyslog/syslog manages it       journalctl reads it
  Persists after reboot           Persists (configurable)
```

In practice, most services log to journald AND write to `/var/log`. You'll use both.

---

## 3. Traditional Log Files — `/var/log`

```bash
# Key log files:
/var/log/syslog          ← general system messages (Ubuntu)
/var/log/messages         ← general system messages (RHEL/CentOS)
/var/log/auth.log         ← authentication: logins, sudo, SSH
/var/log/kern.log         ← kernel messages
/var/log/dmesg            ← boot and hardware messages
/var/log/nginx/access.log ← every HTTP request
/var/log/nginx/error.log  ← nginx errors
/var/log/mysql/error.log  ← database errors
/var/log/cron             ← cron job execution
/var/log/dpkg.log         ← package installs/removes (Ubuntu)
```

### Reading Log Files

```bash
# Print entire log
cat /var/log/syslog

# Last 50 lines
tail -50 /var/log/syslog

# Follow in real time (most useful for debugging)
tail -f /var/log/nginx/error.log

# Follow multiple files simultaneously
tail -f /var/log/nginx/error.log /var/log/app/error.log

# Search for errors
grep "ERROR" /var/log/app.log
grep -i "critical\|error\|fatal" /var/log/syslog

# Show errors from today
grep "$(date +%b %e)" /var/log/syslog | grep -i error

# Count error occurrences
grep -c "ERROR" /var/log/app.log
```

---

## 4. `journalctl` — systemd's Journal

`journalctl` queries the systemd journal — structured, indexed, filterable.

```bash
# View all logs (oldest first, use arrow keys or page up/down)
journalctl

# View logs in reverse (newest first)
journalctl -r

# Follow new log entries in real time (like tail -f)
journalctl -f

# Last 50 entries
journalctl -n 50

# Last 100 lines of a specific service
journalctl -u nginx -n 100

# Follow a specific service
journalctl -u nginx -f
journalctl -u myapp -f

# View logs since boot
journalctl -b

# Previous boot (useful after a crash)
journalctl -b -1

# Logs from specific time range
journalctl --since "2024-01-15 09:00:00"
journalctl --since "1 hour ago"
journalctl --since "2024-01-15 08:00" --until "2024-01-15 10:00"
journalctl --since today

# Filter by priority (0=emergency, 3=error, 6=info, 7=debug)
journalctl -p err            # errors and above
journalctl -p warning..err   # warnings to errors
journalctl -u nginx -p err   # nginx errors only
```

---

## 5. Filtering journalctl Like a Pro

```bash
# Filter by unit (service)
journalctl -u sshd
journalctl -u nginx
journalctl -u myapp

# Multiple services
journalctl -u nginx -u myapp

# Filter by process ID
journalctl _PID=1234

# Filter by user
journalctl _UID=1001
journalctl _COMM=python3       # by executable name

# Kernel messages only
journalctl -k
# Equivalent to:
dmesg

# Output formats
journalctl -u nginx -o json          # JSON format
journalctl -u nginx -o json-pretty   # pretty JSON
journalctl -u nginx -o short         # default
journalctl -u nginx -o verbose       # all fields

# Export logs for sharing/archiving
journalctl -u myapp --since "2024-01-15" > /tmp/myapp_logs.txt
```

---

## 6. Log Rotation — Keeping Logs from Filling Your Disk

Logs grow forever if you don't rotate them. `logrotate` handles this automatically.

```bash
# Check logrotate config
cat /etc/logrotate.conf
ls /etc/logrotate.d/          # per-application config

# Example logrotate config for your app
sudo nano /etc/logrotate.d/myapp
```

```
/var/log/myapp/*.log {
    daily               # rotate daily
    rotate 14           # keep 14 days of logs
    compress            # gzip old logs
    delaycompress       # compress yesterday's log (not today's)
    missingok           # don't error if log file is missing
    notifempty          # don't rotate empty files
    sharedscripts
    postrotate
        systemctl reload myapp   # signal app to reopen log files
    endscript
}
```

```bash
# Test logrotate config (dry run)
sudo logrotate -d /etc/logrotate.d/myapp

# Force rotation now (for testing)
sudo logrotate -f /etc/logrotate.d/myapp

# View logrotate status
cat /var/lib/logrotate/status
```

---

## 7. Managing Journal Size

```bash
# Check how much disk space the journal uses
journalctl --disk-usage

# Vacuum old logs (keep last 2 weeks)
sudo journalctl --vacuum-time=2weeks

# Vacuum by size (keep max 500MB)
sudo journalctl --vacuum-size=500M

# Configure permanent limits
sudo nano /etc/systemd/journald.conf
```

```ini
[Journal]
SystemMaxUse=500M        # max total journal size
MaxRetentionSec=2weeks   # delete logs older than 2 weeks
```

```bash
sudo systemctl restart systemd-journald
```

---

## 8. Real World Log Analysis

**Find what crashed the server last night:**
```bash
# Boot previous (after a crash/reboot)
journalctl -b -1 -p err

# What happened just before the crash?
journalctl -b -1 --since "22:00" --until "23:00"

# Did the OOM killer kill something? (Out of Memory)
journalctl -k | grep -i "oom\|killed"
dmesg | grep -i "oom\|killed"
```

**Investigate a security incident:**
```bash
# Failed login attempts
grep "Failed password" /var/log/auth.log | tail -50

# Successful logins
grep "Accepted password\|Accepted publickey" /var/log/auth.log

# Who used sudo?
grep "sudo:" /var/log/auth.log

# Login attempts from a specific IP
grep "192.168.1.100" /var/log/auth.log
```

**Application is slow — find the slow requests:**
```bash
# nginx access log: find requests taking > 1 second
# (requires $request_time in log format)
awk '$NF > 1' /var/log/nginx/access.log

# Count errors per minute
awk '{print $4}' /var/log/nginx/access.log \
  | cut -d: -f2 \
  | sort | uniq -c
```

---

## 9. Summary

```
Key log files:
  /var/log/syslog           system messages
  /var/log/auth.log         logins, sudo, SSH
  /var/log/nginx/error.log  web server errors
  tail -f /var/log/...      follow a file live

journalctl:
  journalctl -u service     logs for a service
  journalctl -u service -f  follow in real time
  journalctl -p err         errors only
  journalctl --since "1h ago"
  journalctl -b -1          previous boot (after crash)
  journalctl -n 50          last 50 lines

Disk management:
  journalctl --disk-usage   how big is the journal?
  journalctl --vacuum-size=500M   trim journal
  logrotate                 rotates /var/log files automatically

Debug workflow:
  1. journalctl -u service -n 100    what happened?
  2. journalctl -p err               any errors?
  3. journalctl -b -1               what happened last boot?
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← systemd Services](./systemd_services.md) &nbsp;|&nbsp; **Next:** [Disk Management →](./disk_management.md)

**Related Topics:** [systemd Services](./systemd_services.md) · [Disk Management](./disk_management.md)

---

## 📝 Practice Questions

- 📝 [Q40 · journalctl](../linux_practice_questions_100.md#q40--normal--journalctl)
- 📝 [Q70 · log-rotation](../linux_practice_questions_100.md#q70--thinking--log-rotation)
- 📝 [Q88 · scenario-log-analysis](../linux_practice_questions_100.md#q88--design--scenario-log-analysis)
- 📝 [Q97 · design-log-pipeline](../linux_practice_questions_100.md#q97--design--design-log-pipeline)

