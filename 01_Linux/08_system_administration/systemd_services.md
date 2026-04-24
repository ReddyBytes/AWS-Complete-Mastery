# Linux — systemd and Services

> systemd is how modern Linux manages everything that runs on the system. Master it and you control every service, startup sequence, and background process.

---

## 1. What Is systemd?

`systemd` is **PID 1** — the very first process that starts when Linux boots. It's the parent of everything.

```
Boot sequence:
  Kernel loads → systemd starts (PID 1) → everything else starts
```

Before systemd (2010 and earlier), Linux used `init` and shell scripts. systemd replaced all of that with a faster, parallel, feature-rich system.

Think of systemd as the **city manager** of your Linux system:
- Starts services in the right order
- Restarts crashed services automatically
- Logs everything through journald
- Manages sockets, timers, mounts, and devices

---

## 2. Units — The Building Blocks

systemd manages things called **units**. Each unit is described by a file.

```
Unit types:
──────────────────────────────────────────────────────────
  .service    A daemon or process (nginx.service, sshd.service)
  .timer      Scheduled tasks (replacement for cron)
  .socket     Socket activation (start service on connection)
  .mount      Filesystem mount points
  .target     Group of units (multi-user.target = "server mode")
  .path       Watch filesystem path for changes
──────────────────────────────────────────────────────────
```

Unit files live in:
```bash
/lib/systemd/system/        # system packages put their units here
/etc/systemd/system/        # your custom units go here (overrides)
```

---

## 3. `systemctl` — The Control Command

```bash
# Start / Stop / Restart a service
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# Reload config without full restart (if service supports it)
sudo systemctl reload nginx

# Try reload, fall back to restart if reload not supported
sudo systemctl reload-or-restart nginx

# Check status (running? errors? last log lines)
sudo systemctl status nginx

# Enable/disable on boot
sudo systemctl enable nginx         # auto-start on boot
sudo systemctl disable nginx        # don't auto-start

# Enable AND start in one command
sudo systemctl enable --now nginx

# Is it currently running?
systemctl is-active nginx           # prints "active" or "inactive"
systemctl is-enabled nginx          # prints "enabled" or "disabled"
systemctl is-failed nginx           # prints "failed" or "inactive"

# List all running services
systemctl list-units --type=service --state=running

# List all units (running + stopped)
systemctl list-units --type=service

# List failed services (quick health check)
systemctl --failed
```

---

## 4. Reading `systemctl status` Output

```bash
sudo systemctl status nginx
```

```
● nginx.service - A high performance web server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
     Active: active (running) since Tue 2024-01-15 09:30:00 UTC; 2h ago
   Main PID: 1234 (nginx)
    CGroup: /system.slice/nginx.service
            ├─1234 nginx: master process /usr/sbin/nginx
            └─1235 nginx: worker process

Jan 15 09:30:00 server systemd[1]: Started nginx.
Jan 15 09:30:00 server nginx[1234]: nginx: the configuration file test is OK
```

Key things to check:
- `active (running)` — service is up
- `failed` — service crashed
- `enabled` — will start on boot
- `disabled` — won't start on boot
- The log lines at the bottom show recent activity

---

## 5. Writing a systemd Service File

Turn your own application into a managed service:

```bash
sudo nano /etc/systemd/system/myapp.service
```

```ini
[Unit]
Description=My Python Web Application
Documentation=https://github.com/mycompany/myapp
# Start after network is ready
After=network.target
# Start after database (if you have one)
After=postgresql.service
Requires=postgresql.service

[Service]
# Service type
Type=simple           # process stays in foreground (most common)
# Type=forking        # process forks to background (old-style daemons)
# Type=notify         # process signals systemd when ready

# Run as this user (not root!)
User=myapp
Group=myapp

# Working directory
WorkingDirectory=/opt/myapp

# Environment variables
Environment=APP_ENV=production
Environment=PORT=8080
EnvironmentFile=/etc/myapp/env    # or load from a file

# The command to start
ExecStart=/usr/bin/python3 /opt/myapp/server.py

# Optional: run before start (e.g., migrations)
ExecStartPre=/usr/bin/python3 /opt/myapp/migrate.py

# Restart policy
Restart=always              # always restart if it exits
# Restart=on-failure        # only restart on non-zero exit
RestartSec=5                # wait 5 seconds before restarting

# Logging (sends to journald)
StandardOutput=journal
StandardError=journal

# Optional limits
LimitNOFILE=65535           # max open files

[Install]
WantedBy=multi-user.target  # start in normal server mode
```

```bash
# After creating the file:
sudo systemctl daemon-reload          # reload systemd config
sudo systemctl enable myapp           # enable on boot
sudo systemctl start myapp            # start now
sudo systemctl status myapp           # check it's running
```

---

## 6. Override a Service Without Editing the Original

Instead of modifying `/lib/systemd/system/nginx.service` (which gets overwritten on updates), use an override:

```bash
# Create an override directory and file
sudo systemctl edit nginx

# This opens /etc/systemd/system/nginx.service.d/override.conf
# Add only the parts you want to change:
[Service]
LimitNOFILE=100000
Environment=EXTRA_OPTION=value

# Save and reload
sudo systemctl daemon-reload
sudo systemctl restart nginx
```

---

## 7. systemd Timers — Modern Cron

Replace cron jobs with systemd timers (better logging, dependency handling):

```bash
# Create the service that does the work
sudo nano /etc/systemd/system/backup.service
```

```ini
[Unit]
Description=Daily Backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
User=backup
```

```bash
# Create the timer
sudo nano /etc/systemd/system/backup.timer
```

```ini
[Unit]
Description=Run backup daily at 2am

[Timer]
OnCalendar=*-*-* 02:00:00    # daily at 2am
# OnCalendar=Mon *-*-* 03:00  # every Monday at 3am
# OnBootSec=10min             # 10 minutes after boot
# OnUnitActiveSec=1h          # every hour after last run
Persistent=true               # run immediately if missed (e.g., server was off)

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer
systemctl list-timers                    # see all timers and next run times
```

---

## 8. Real World Scenarios

**App keeps crashing — check and fix:**
```bash
sudo systemctl status myapp            # what happened?
sudo journalctl -u myapp -n 50         # last 50 log lines
sudo journalctl -u myapp --since "1 hour ago"

# Fix the bug, then:
sudo systemctl restart myapp
```

**Server rebooted — why didn't my app start?**
```bash
systemctl is-enabled myapp             # is it enabled?
# If disabled:
sudo systemctl enable myapp
```

**Deploy new version without downtime:**
```bash
# Copy new code
sudo rsync -avz new_code/ /opt/myapp/

# Reload (if app supports graceful reload)
sudo systemctl reload myapp

# Or restart (brief downtime)
sudo systemctl restart myapp
```

---

## 9. Summary

```
Core commands:
  systemctl start/stop/restart service    control a service
  systemctl enable/disable service        boot behaviour
  systemctl status service                see status + recent logs
  systemctl --failed                      what's broken?
  systemctl list-units --type=service     all services

Service file location:
  /etc/systemd/system/myapp.service       your custom services

After creating/editing a service file:
  sudo systemctl daemon-reload
  sudo systemctl enable --now myapp

Key service file sections:
  [Unit]    description, ordering (After=, Requires=)
  [Service] how to run it (ExecStart, User, Restart)
  [Install] when to start (WantedBy=multi-user.target)

Restart policies:
  Restart=always        always restart
  Restart=on-failure    only on crashes
  RestartSec=5          wait before restarting
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Build from Source](../07_package_management/build_from_source.md) &nbsp;|&nbsp; **Next:** [Logs and journalctl →](./logs_and_journalctl.md)

**Related Topics:** [Logs and journalctl](./logs_and_journalctl.md) · [Disk Management](./disk_management.md)

---

## 📝 Practice Questions

- 📝 [Q38 · systemd-basics](../linux_practice_questions_100.md#q38--normal--systemd-basics)
- 📝 [Q39 · systemd-units](../linux_practice_questions_100.md#q39--normal--systemd-units)
- 📝 [Q41 · cron-jobs](../linux_practice_questions_100.md#q41--normal--cron-jobs)
- 📝 [Q64 · sysctl](../linux_practice_questions_100.md#q64--normal--sysctl)
- 📝 [Q85 · scenario-cron-not-running](../linux_practice_questions_100.md#q85--design--scenario-cron-not-running)
- 📝 [Q86 · compare-sysv-systemd](../linux_practice_questions_100.md#q86--interview--compare-sysv-systemd)
- 📝 [Q96 · debug-cron-env](../linux_practice_questions_100.md#q96--debug--debug-cron-env)

