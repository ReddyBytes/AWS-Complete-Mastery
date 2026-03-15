# Linux — Interview Questions

> Real questions from DevOps, SRE, and backend engineering interviews. Grouped by experience level.

---

## Beginner Level (0–1 Years)

**Q: What is Linux and why is it used for servers?**

Linux is a free, open-source operating system kernel. It dominates servers because it's free, stable, secure, open-source, and runs efficiently on any hardware. 96% of the top 1 million web servers run Linux.

---

**Q: What is the difference between absolute and relative paths?**

- Absolute path starts from root `/`: `/home/alice/projects/app.py` — works from anywhere
- Relative path is relative to your current directory: `./projects/app.py` or `../config.yaml`

---

**Q: What does `ls -la` show that `ls` doesn't?**

`-l` shows long format: permissions, owner, group, size, modified date.
`-a` shows hidden files (files starting with `.` like `.bashrc`, `.ssh/`).

---

**Q: What is the difference between `>` and `>>`?**

- `>` redirects output to a file, **overwriting** any existing content
- `>>` redirects output to a file, **appending** to the end

```bash
echo "first" > file.txt     # file has: "first"
echo "second" > file.txt    # file has: "second" (overwritten!)
echo "third" >> file.txt    # file has: "second\nthird"
```

---

**Q: What do the permissions `rwxr-xr--` mean?**

```
rwx   r-x   r--
Owner Group Others
rw- = read + write
r-x = read + execute
r-- = read only

Owner: read, write, execute
Group: read, execute (cannot write)
Others: read only
```

Numeric equivalent: 754

---

**Q: How do you find a file on Linux?**

```bash
find /etc -name "nginx.conf"       # find by name
find /var -name "*.log" -mtime -1  # log files changed today
find / -size +100M                  # files larger than 100MB
```

---

**Q: What is a process and what is a PID?**

A process is a running instance of a program. PID (Process ID) is a unique number assigned by the kernel to identify it. View with `ps aux` or `top`.

---

## Intermediate Level (1–3 Years)

**Q: What is the difference between SIGTERM and SIGKILL?**

- `SIGTERM (15)`: Politely asks process to terminate. Process can catch it, finish current work, save state, close connections gracefully. **Try this first.**
- `SIGKILL (9)`: Kills immediately. Cannot be caught or ignored. No cleanup. Data may be lost. **Use only when SIGTERM doesn't work.**

```bash
kill -15 1234    # graceful
kill -9 1234     # force
```

---

**Q: What does SIGHUP do and why do services use it?**

Originally meant "terminal hung up." Modern services use it to mean "reload your configuration without restarting."

```bash
sudo kill -HUP $(pgrep nginx)
# nginx reads the new config, starts new workers, gracefully drains old ones
# Zero dropped connections
```

---

**Q: How does `sudo` work?**

1. Checks `/etc/sudoers` — is this user allowed?
2. Prompts for **your** password (not root's)
3. Logs the command to `/var/log/auth.log`
4. Runs the command as root
5. Returns you to your normal user after

Always edit `/etc/sudoers` with `sudo visudo` — it validates syntax before saving.

---

**Q: What is a hard link vs a symbolic link?**

- **Hard link**: Another directory entry pointing to the same inode (same data on disk). Deleting the original doesn't delete the data. Cannot cross filesystems or link directories.
- **Symbolic link**: A file containing a path to another file. If the target is deleted, the symlink breaks. Can cross filesystems.

```bash
ln source target          # hard link
ln -s source target       # symbolic link
```

---

**Q: How do you check what process is using port 80?**

```bash
ss -tlnp | grep :80
lsof -i :80
```

---

**Q: What is the difference between `su` and `sudo`?**

- `su username`: Switch to another user for the whole session. Needs **that user's** password.
- `sudo command`: Run one command as root. Needs **your** password. Every command is logged. Safer and auditable.

---

**Q: How do you make a service start automatically on boot?**

```bash
sudo systemctl enable nginx      # enable on boot
sudo systemctl enable --now nginx  # enable AND start now
```

`enable` creates a symlink in `/etc/systemd/system/multi-user.target.wants/`.

---

**Q: How would you find all files changed in the last 24 hours?**

```bash
find /etc -mtime -1              # modified in last 24 hours
find /var/log -newer /tmp/marker # modified since marker file
```

---

## Advanced Level (3+ Years)

**Q: Explain the Linux boot process.**

```
1. Power on → BIOS/UEFI runs (hardware check)
2. GRUB bootloader runs (choose kernel)
3. Kernel loads into memory
4. Kernel mounts root filesystem (initramfs)
5. systemd starts as PID 1
6. systemd starts all services (parallel where possible)
7. Targets reached: multi-user.target (server ready)
```

---

**Q: What is the OOM killer and when does it trigger?**

When RAM is exhausted and no swap is available, the kernel's Out-Of-Memory killer selects a process to kill to free memory. It picks based on memory usage and a "badness" score.

```bash
dmesg | grep -i "oom\|killed"           # see if it fired
journalctl -k | grep "oom"
cat /proc/1234/oom_score                # check a process's OOM score
echo -17 > /proc/1234/oom_score_adj    # protect a process from OOM kill
```

---

**Q: How do you investigate a server that's suddenly slow?**

Systematic approach:
```bash
# 1. What's using CPU?
top                              # sort by %CPU with 'P'
ps aux --sort=-%cpu | head -5

# 2. What's using memory?
free -h
ps aux --sort=-%mem | head -5

# 3. Is the disk full?
df -h

# 4. Is there a disk I/O bottleneck?
iostat -x 1                      # check %util column
iotop                            # per-process I/O

# 5. Network bottleneck?
iftop
ss -s                            # connection stats

# 6. Check system load
uptime                           # load averages (compare to nproc)
```

---

**Q: What happens when you run `rm -rf /` and how do you protect against it?**

It would try to delete every file on the system, rendering it unbootable. Modern Linux has `--no-preserve-root` as a safeguard — `rm -rf /` requires this flag explicitly.

Protection:
- Never run as root unless necessary
- Use `sudo` with specific commands instead of running a root shell
- Implement immutable backups (EBS snapshots, off-site backups)
- Use tools like `safe-rm` that refuse to delete protected paths

---

**Q: How does Linux decide which process gets CPU time?**

The Linux kernel uses the **CFS (Completely Fair Scheduler)**. Each process gets a fair share of CPU time weighted by its nice value. Processes get time slices proportional to their priority. The scheduler tracks "virtual runtime" and always picks the process with the least virtual runtime next.

```bash
nice -n 10 cmd        # lower priority (higher nice = less CPU)
nice -n -5 cmd        # higher priority (requires root for negative)
renice 10 -p PID      # change running process priority
```

---

**Q: How would you set up a zero-downtime deployment on nginx?**

```bash
# 1. Test new config
nginx -t

# 2. Reload (sends SIGHUP) — workers finish existing connections, new workers use new config
sudo systemctl reload nginx

# Or with upstream symlink swap:
ln -sfn /var/www/app_v2 /var/www/current    # atomic swap
sudo systemctl reload nginx                  # nginx sees new root immediately
```

---

**Q: What is the difference between `fork()` and `exec()`?**

- `fork()`: Creates an exact copy of the current process (child process). Same code, same memory. Child gets a new PID.
- `exec()`: Replaces the current process image with a new program. Same PID, new code.

When you type a command in bash:
1. Bash calls `fork()` → creates a child process
2. Child calls `exec()` → replaces itself with the command
3. Parent (bash) waits for the child to finish

---

## Scenario Questions

**Q: Disk is 100% full on a production server. What do you do?**

```bash
# 1. Find the culprit fast
du -sh /* 2>/dev/null | sort -rh | head

# 2. Common quick fixes:
sudo journalctl --vacuum-size=100M   # clear old journal
sudo apt clean                        # clear apt cache
find /var/log -name "*.gz" -delete   # delete rotated compressed logs

# 3. Check for deleted files still held open
lsof | grep deleted | sort -k7 -rn | head
# If nginx/app is holding a deleted log open:
sudo systemctl restart nginx          # frees the file handle immediately

# 4. Long term: add logrotate, add more disk, archive old data
```

---

**Q: Your application crashed. How do you find out why?**

```bash
# 1. Check if it's still running
systemctl status myapp

# 2. Read recent logs
journalctl -u myapp -n 100
journalctl -u myapp -p err

# 3. What was happening just before it crashed?
journalctl -u myapp --since "30 min ago"

# 4. Check system-level issues
journalctl -k | grep -i "oom\|error" # OOM kill? hardware error?
dmesg | tail -20

# 5. Check disk and memory at time of crash
journalctl --since "2024-01-15 14:00" --until "2024-01-15 14:05"
```

---

**Q: SSH connection is refused. How do you debug?**

```bash
# From the server (if you have console access):
sudo systemctl status sshd          # is sshd running?
ss -tlnp | grep :22                  # is it listening?
sudo ufw status                      # firewall blocking?
sudo tail /var/log/auth.log          # any error messages?

# From your machine:
ssh -vvv user@server                 # verbose output
nc -zv server-ip 22                  # is port 22 reachable?
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Disk Management](../08_system_administration/disk_management.md) &nbsp;|&nbsp; **Next:** —

**Related Topics:** [Shell Commands](../03_shell_basics/commands.md) · [Process Management](../05_processes/process_management.md) · [File Permissions](../04_users_permissions/file_permissions.md) · [systemd Services](../08_system_administration/systemd_services.md)
