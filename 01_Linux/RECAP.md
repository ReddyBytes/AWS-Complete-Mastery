# Linux — Topic Recap

> One-line summary of every module. Use this to quickly find which module covers the concept you need.

---

## Core System

| Module | Topics Covered |
|--------|----------------|
| [01_fundamentals](./01_fundamentals/) | What Linux is, kernel/shell/userspace architecture, distro families (Debian vs Red Hat), the Linux history from Unix to today, why Linux dominates servers and cloud |
| [02_filesystem](./02_filesystem/) | The unified `/` directory tree, every standard directory explained (`/etc`, `/var`, `/proc`, `/usr`, `/tmp`), file operations (create/copy/move/delete), hard links vs soft links, inodes |

## Shell and Files

| Module | Topics Covered |
|--------|----------------|
| [03_shell_basics](./03_shell_basics/) | Navigation (`pwd`, `cd`, `ls`), viewing files (`cat`, `head`, `tail`, `less`), text processing (`grep`, `awk`, `sed`, `sort`, `uniq`), pipes and redirection (`\|`, `>`, `>>`, `2>&1`) |
| [04_users_permissions](./04_users_permissions/) | User types (root, system, regular), UIDs/GIDs, `/etc/passwd` and `/etc/shadow`, `useradd`/`usermod`/`userdel`, groups, `chmod`/`chown`/`chgrp`, permission bits (rwx), `sudo` and `/etc/sudoers` |

## Processes and Networking

| Module | Topics Covered |
|--------|----------------|
| [05_processes](./05_processes/) | What a process is (PID, PPID, state), `ps aux` and `top`/`htop`, `kill` and signals (SIGTERM, SIGKILL, SIGHUP, SIGINT), foreground vs background jobs (`&`, `fg`, `bg`, `jobs`), daemons |
| [06_networking](./06_networking/) | Checking interfaces (`ip addr`, `ifconfig`), `ping`, `curl`, `wget`, `netstat`/`ss` for open ports, `traceroute`, SSH (key pairs, `~/.ssh/config`, port forwarding, `scp`/`rsync`), firewall basics (`ufw`, `iptables`) |

## Software and Administration

| Module | Topics Covered |
|--------|----------------|
| [07_package_management](./07_package_management/) | apt (Debian/Ubuntu) vs yum/dnf (Red Hat/Amazon Linux), install/remove/update/search commands, package repositories, building from source (`./configure`, `make`, `make install`) |
| [08_system_administration](./08_system_administration/) | systemd and units (`.service`, `.timer`, `.socket`, `.target`), `systemctl` (start/stop/enable/status), `journalctl` log querying, disk management (`df`, `du`, `lsblk`, `mount`, partitioning), log files and `/var/log` |

## Interview Prep

| Module | Topics Covered |
|--------|----------------|
| [99_interview_master](./99_interview_master/) | Beginner to advanced DevOps/SRE interview questions: permissions, paths, process management, signals, networking, `find`/`grep`, troubleshooting scenarios, scripting on the spot |

---

*Total modules: 8 + interview · Last updated: 2026-04-21*
