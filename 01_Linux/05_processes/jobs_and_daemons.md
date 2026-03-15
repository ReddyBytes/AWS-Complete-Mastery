# Linux — Jobs and Daemons

> Running commands in the background, keeping them alive after logout, and managing long-running services — the skills that separate beginners from confident Linux users.

---

## 1. Foreground vs Background

Every command you run starts in the **foreground** — it holds your terminal until it finishes.

```bash
# Foreground: terminal is blocked until the download finishes
wget https://example.com/large-file.tar.gz

# Background: terminal returns immediately, download continues
wget https://example.com/large-file.tar.gz &
# [1] 4821  ← job number and PID
```

The `&` at the end sends a process to the background.

---

## 2. Job Control

### Sending to Background

```bash
# Start in background
python3 server.py &

# Suspend running process (Ctrl+Z) then send to background
python3 server.py
# Press Ctrl+Z
# [1]+ Stopped    python3 server.py
bg                  # resume in background
bg %1               # resume job 1 specifically
```

### Bringing Back to Foreground

```bash
# Bring most recent background job to foreground
fg

# Bring specific job to foreground
fg %1               # job 1
fg %2               # job 2
```

### Listing Jobs

```bash
jobs                # list all jobs in current shell
jobs -l             # include PIDs

# Output:
# [1]- Running    wget https://... &
# [2]+ Stopped    vim config.yaml
```

---

## 3. The Problem — Background Jobs Die When You Log Out

```bash
ssh user@server
python3 long_script.py &   # starts fine
exit                        # you log out
# The script DIES. SIGHUP was sent to the whole session.
```

When you close your SSH connection, Linux sends SIGHUP to your shell, and your shell sends it to all your background jobs. They all stop.

**Three solutions:**

---

## 4. Solution 1: `nohup` — Ignore the Hangup

```bash
# Run and ignore SIGHUP
nohup python3 long_script.py &

# Output and errors go to nohup.out by default
nohup python3 long_script.py > /var/log/myapp.log 2>&1 &

# The & sends it to background; nohup makes it survive logout
```

When you log back in, the process is still running. Check with:
```bash
ps aux | grep long_script
```

---

## 5. Solution 2: `screen` — Virtual Terminal Sessions

`screen` creates a virtual terminal that persists. You can detach, log out, come back, and reattach.

```bash
# Install
sudo apt install screen

# Start a new named session
screen -S deployment

# You're now inside screen. Run your command:
./long_deploy.sh

# Detach (leave it running): Ctrl+A then D
# You're back to your normal terminal. Process still runs.

# Log out, come back, reattach:
screen -ls                          # list sessions
screen -r deployment                # reattach by name
screen -r 4821.deployment           # by ID

# Kill a session from inside
exit
# Or from outside:
screen -X -S deployment quit
```

### Common screen shortcuts

```
Ctrl+A D        Detach (leave running)
Ctrl+A c        Create new window
Ctrl+A n        Next window
Ctrl+A p        Previous window
Ctrl+A "        List windows
Ctrl+A k        Kill current window
```

---

## 6. Solution 3: `tmux` — Modern Screen (Preferred)

`tmux` is the modern replacement for screen. More features, better UI.

```bash
# Install
sudo apt install tmux

# Start a named session
tmux new -s deployment

# Inside tmux, run your command
./deploy.sh

# Detach: Ctrl+B then D

# List sessions
tmux ls

# Reattach
tmux attach -t deployment

# Kill a session
tmux kill-session -t deployment
```

### Common tmux shortcuts

```
Ctrl+B D        Detach
Ctrl+B c        New window
Ctrl+B n/p      Next/previous window
Ctrl+B %        Split pane vertically
Ctrl+B "        Split pane horizontally
Ctrl+B arrow    Move between panes
Ctrl+B [        Enter scroll mode (q to exit)
```

---

## 7. Daemons — Background Services

A **daemon** is a long-running background process that provides a service. It:
- Runs continuously without a terminal
- Starts at boot
- Has no parent interactive shell
- Usually has a name ending in `d`: `nginx`, `sshd`, `systemd`, `cron d`

```
Examples of daemons:
──────────────────────────────────────────────────────────
  sshd        SSH server (handles your SSH connections)
  nginx       Web server
  mysqld      MySQL database
  cron        Task scheduler
  systemd     Init system (PID 1, parent of everything)
  dockerd     Docker engine
  journald    Log collection
──────────────────────────────────────────────────────────
```

---

## 8. systemd — Managing Daemons

Modern Linux systems use `systemd` to manage daemons.

```bash
# Start / Stop / Restart
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx

# Reload config without restart (sends SIGHUP)
sudo systemctl reload nginx

# Enable/disable on boot
sudo systemctl enable nginx       # start on boot
sudo systemctl disable nginx      # don't start on boot

# Status
sudo systemctl status nginx

# List all running services
systemctl list-units --type=service --state=running

# List all services (including stopped)
systemctl list-units --type=service --all
```

### Writing a Simple systemd Service

Turn your Python script into a managed daemon:

```bash
sudo nano /etc/systemd/system/myapp.service
```

```ini
[Unit]
Description=My Python Application
After=network.target

[Service]
Type=simple
User=myapp
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/python3 /opt/myapp/server.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Reload systemd to see the new service
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable myapp
sudo systemctl start myapp

# Check it's running
sudo systemctl status myapp

# See its logs
sudo journalctl -u myapp -f
```

Now your app starts on boot, restarts if it crashes, and logs to journald.

---

## 9. Real World Scenarios

**Long database migration — can't lose the session:**
```bash
# Create tmux session
tmux new -s migration

# Run migration
python3 migrate.py --production

# Detach safely
# Ctrl+B D

# Check back later
tmux attach -t migration
```

**Keep a monitoring script running after SSH logout:**
```bash
nohup python3 monitor.py > /var/log/monitor.log 2>&1 &
echo "Monitor PID: $!"
```

**Deploy an app as a proper service:**
```bash
# 1. Create systemd service file (see above)
# 2. Enable it
sudo systemctl enable myapp

# 3. Start it
sudo systemctl start myapp

# 4. It will now start automatically on server reboot
# 5. And restart automatically if it crashes
```

---

## 10. Summary

```
Job control:
  command &         run in background
  Ctrl+Z            suspend foreground process
  bg                resume suspended job in background
  fg                bring background job to foreground
  jobs              list current jobs

Survive logout:
  nohup cmd &       immune to SIGHUP
  screen -S name    virtual session (Ctrl+A D to detach)
  tmux new -s name  modern virtual session (Ctrl+B D to detach)

Daemons:
  systemctl start/stop/restart service
  systemctl enable/disable service
  systemctl status service
  journalctl -u service -f    follow service logs

Turn script into service:
  Create /etc/systemd/system/myapp.service
  sudo systemctl daemon-reload
  sudo systemctl enable --now myapp
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Signals](./signals.md) &nbsp;|&nbsp; **Next:** [Network Commands →](../06_networking/network_commands.md)

**Related Topics:** [Process Management](./process_management.md) · [Signals](./signals.md)
