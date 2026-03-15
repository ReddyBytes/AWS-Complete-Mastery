<div align="center">

<img src="../docs/assets/linux_banner.svg" alt="Linux Mastery" width="100%"/>

# 🐧 Linux Mastery

[![Linux](https://img.shields.io/badge/Linux-22C55E?style=for-the-badge&logo=linux&logoColor=white)](#)
[![Shell](https://img.shields.io/badge/Shell-16A34A?style=for-the-badge&logo=gnubash&logoColor=white)](#)
[![DevOps](https://img.shields.io/badge/DevOps_Foundation-15803D?style=for-the-badge)](#)

[![Sections](https://img.shields.io/badge/Sections-8-4ADE80?style=flat-square)](#curriculum)
[![Files](https://img.shields.io/badge/Files-24-86EFAC?style=flat-square)](#curriculum)
[![Level](https://img.shields.io/badge/Level-Beginner_to_Advanced-22C55E?style=flat-square)](#)

**Everything you need to work confidently on Linux servers — from first login to production system administration.**

</div>

---

## Why Learn Linux First?

Before AWS, before Docker, before Kubernetes — there is Linux.

- 96% of the top 1 million web servers run Linux
- Every EC2 instance, every container, every cloud VM runs Linux underneath
- SSH, systemd, file permissions, processes — you'll use these every single day as a DevOps/SRE/Cloud engineer

**You cannot skip Linux.** This section teaches it from zero, with real-world analogies that make it actually stick.

---

## 🗺️ Learning Order

```
01 Fundamentals  ──►  02 Filesystem  ──►  03 Shell Basics  ──►  04 Users/Permissions
                                                                         │
08 System Admin  ◄──  07 Packages   ◄──  06 Networking   ◄──  05 Processes
```

Follow this order. Each section builds on the previous one.

---

## 📚 Curriculum

### [01 — Fundamentals](./01_fundamentals/)

What Linux is, why it exists, and how it works under the hood.

| File | What You Learn |
|------|---------------|
| [overview.md](./01_fundamentals/overview.md) | What is Linux, history, why servers use it, daily commands overview |
| [architecture.md](./01_fundamentals/architecture.md) | 4-layer architecture: hardware, kernel, shell, applications |
| [distros.md](./01_fundamentals/distros.md) | Ubuntu vs Amazon Linux vs RHEL vs Rocky — which to use and when |

---

### [02 — Filesystem](./02_filesystem/)

Linux stores everything as files. Understanding the filesystem is understanding Linux.

| File | What You Learn |
|------|---------------|
| [directory_structure.md](./02_filesystem/directory_structure.md) | `/etc`, `/var`, `/home`, `/tmp`, `/proc` — what lives where and why |
| [file_operations.md](./02_filesystem/file_operations.md) | `ls`, `cp`, `mv`, `rm`, `find`, `wc`, `diff` — work with files confidently |
| [links_and_inodes.md](./02_filesystem/links_and_inodes.md) | Hard links vs symlinks, what an inode is, why it matters for DevOps |

---

### [03 — Shell Basics](./03_shell_basics/)

The command line is your interface to every Linux server you'll ever manage.

| File | What You Learn |
|------|---------------|
| [commands.md](./03_shell_basics/commands.md) | Navigation, viewing files, searching, system info, keyboard shortcuts |
| [pipes_and_redirection.md](./03_shell_basics/pipes_and_redirection.md) | `\|`, `>`, `>>`, `2>&1`, `tee` — chain commands and redirect output |
| [text_processing.md](./03_shell_basics/text_processing.md) | `grep`, `awk`, `sed`, `sort`, `uniq`, `cut` — analyze logs like a pro |

---

### [04 — Users & Permissions](./04_users_permissions/)

Linux is a multi-user system. Permissions control what every process and person can do.

| File | What You Learn |
|------|---------------|
| [users_and_groups.md](./04_users_permissions/users_and_groups.md) | `useradd`, `usermod`, `groupadd`, `/etc/passwd`, `/etc/shadow` |
| [file_permissions.md](./04_users_permissions/file_permissions.md) | `rwxr-xr--`, `chmod`, `chown`, octal notation, special bits (SUID/SGID) |
| [sudo_and_root.md](./04_users_permissions/sudo_and_root.md) | How sudo works, `/etc/sudoers`, `visudo`, security best practices |

---

### [05 — Processes](./05_processes/)

A running program is a process. Understanding processes lets you diagnose and fix anything.

| File | What You Learn |
|------|---------------|
| [process_management.md](./05_processes/process_management.md) | `ps`, `top`, `htop`, `pgrep`, `pkill`, `nice`, `renice` — find and control processes |
| [signals.md](./05_processes/signals.md) | SIGTERM vs SIGKILL vs SIGHUP — the right way to stop and reload processes |
| [jobs_and_daemons.md](./05_processes/jobs_and_daemons.md) | `fg`, `bg`, `nohup`, `screen`, `tmux`, turning scripts into background daemons |

---

### [06 — Networking](./06_networking/)

Every server communicates over a network. Know how to inspect, debug, and secure it.

| File | What You Learn |
|------|---------------|
| [network_commands.md](./06_networking/network_commands.md) | `ip`, `ping`, `ss`, `curl`, `wget`, `traceroute`, `dig`, `netstat` |
| [ssh.md](./06_networking/ssh.md) | SSH keys, `~/.ssh/config`, tunneling, port forwarding, hardening |
| [firewall.md](./06_networking/firewall.md) | `ufw`, `firewalld`, `iptables` — allow/deny traffic by port and IP |

---

### [07 — Package Management](./07_package_management/)

Install, update, and remove software on Linux systems.

| File | What You Learn |
|------|---------------|
| [apt_and_yum.md](./07_package_management/apt_and_yum.md) | `apt` (Ubuntu/Debian) vs `yum`/`dnf` (RHEL/Amazon Linux) |
| [build_from_source.md](./07_package_management/build_from_source.md) | `./configure && make && make install` — when and how to compile from source |

---

### [08 — System Administration](./08_system_administration/)

Keep production servers healthy, debuggable, and running.

| File | What You Learn |
|------|---------------|
| [systemd_services.md](./08_system_administration/systemd_services.md) | `systemctl`, writing `.service` files, timers, auto-restart |
| [logs_and_journalctl.md](./08_system_administration/logs_and_journalctl.md) | `journalctl`, `/var/log`, logrotate — find any error in any service |
| [disk_management.md](./08_system_administration/disk_management.md) | `df`, `du`, `lsblk`, `mount`, expanding EBS volumes on AWS |

---

### [99 — Interview Master](./99_interview_master/)

Real questions from DevOps, SRE, and backend engineering interviews.

| File | What You Learn |
|------|---------------|
| [linux_questions.md](./99_interview_master/linux_questions.md) | Beginner → Intermediate → Advanced → Scenario Q&A |

---

## 🔑 Key Commands Cheat Sheet

```bash
# Filesystem
ls -la          # list all files with permissions
find / -name "file.txt"   # find files
du -sh /var/log/*         # see what's using disk space
df -h                     # disk usage per filesystem

# Processes
ps aux | grep nginx       # find a process
kill -15 PID              # graceful stop
kill -9 PID               # force kill
top                       # real-time process monitor

# Permissions
chmod 755 script.sh       # rwxr-xr-x
chown user:group file     # change ownership
sudo systemctl restart nginx   # restart a service

# Logs
journalctl -u nginx -f    # follow nginx logs
journalctl -p err         # errors only
tail -f /var/log/syslog   # follow system log
```

---

<div align="center">

[![Back to Root](https://img.shields.io/badge/←_Back_to_Root-14B8A6?style=for-the-badge)](../README.md)
[![Next: Bash Scripting](https://img.shields.io/badge/Next:_Bash_Scripting_→-F59E0B?style=for-the-badge&logo=gnubash&logoColor=white)](../02_Bash-Scripting/README.md)

**Start:** [01 Fundamentals →](./01_fundamentals/overview.md)

</div>
