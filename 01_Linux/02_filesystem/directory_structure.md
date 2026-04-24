# Linux — Directory Structure

> Linux organises everything into one unified tree. Once you understand the layout, you'll know exactly where everything lives on any Linux system.

---

## 1. The Analogy — One Filing Cabinet for Everything

Windows has separate drives: `C:\`, `D:\`, `E:\`
Linux has **one tree** that starts at `/` (root) and everything hangs off it.

```
Windows:                        Linux:
  C:\Users\john\                  /home/john/
  C:\Program Files\               /usr/
  D:\Data\                        /mnt/data/   ← mounted drive
```

Even external hard drives, USB sticks, and network shares get "mounted" into this single tree — they become folders, not separate drives.

---

## 2. The Full Linux Directory Tree

```
/                   ← root of everything (like the trunk of a tree)
├── bin/            ← essential user commands (ls, cp, cat, grep)
├── sbin/           ← system admin commands (fdisk, reboot, ifconfig)
├── etc/            ← system-wide configuration files
├── home/           ← users' personal directories
│   ├── alice/
│   └── bob/
├── root/           ← home directory for root user
├── var/            ← variable data — logs, databases, mail, pid files
│   └── log/        ← system and application logs
├── tmp/            ← temporary files (wiped on reboot)
├── usr/            ← user applications and libraries
│   ├── bin/        ← most user commands live here
│   ├── lib/        ← shared libraries
│   └── local/      ← locally installed software
├── lib/            ← shared libraries needed to boot
├── proc/           ← virtual filesystem — running processes and kernel info
├── sys/            ← virtual filesystem — kernel and device info
├── dev/            ← device files (disks, terminals, random)
├── mnt/            ← temporary mount point for drives
├── media/          ← auto-mounted removable media (USB, CD)
├── opt/            ← optional/third-party software
├── boot/           ← bootloader and kernel files
└── srv/            ← service data (web server files, FTP)
```

---

## 3. The Directories You'll Use Every Day

### `/etc` — The Configuration Drawer

Everything that configures how the system and services behave lives in `/etc`.

```bash
/etc/
├── nginx/nginx.conf        ← nginx web server config
├── ssh/sshd_config         ← SSH server settings
├── hosts                   ← local DNS override
├── passwd                  ← user accounts (not passwords!)
├── group                   ← group definitions
├── crontab                 ← scheduled tasks
├── fstab                   ← filesystems to mount on boot
└── environment             ← system-wide environment variables
```

Real world example — change the SSH port:
```bash
sudo nano /etc/ssh/sshd_config
# Change: Port 22 → Port 2222
sudo systemctl restart sshd
```

---

### `/var/log` — The Event Log Book

All logs land here. This is your first stop when something breaks.

```bash
/var/log/
├── syslog              ← general system messages (Ubuntu)
├── messages            ← general system messages (RHEL/CentOS)
├── auth.log            ← login attempts, sudo usage
├── nginx/
│   ├── access.log      ← every HTTP request to nginx
│   └── error.log       ← nginx errors
├── mysql/error.log     ← database errors
└── kern.log            ← kernel messages
```

```bash
# Watch live application errors
tail -f /var/log/nginx/error.log

# Find all failed login attempts
grep "Failed password" /var/log/auth.log

# Last 100 system messages
tail -100 /var/log/syslog
```

---

### `/home` — User Personal Space

Every user gets their own directory under `/home`:

```bash
/home/
├── alice/
│   ├── .bashrc         ← bash config (hidden — starts with .)
│   ├── .ssh/           ← SSH keys
│   └── projects/
└── bob/
    └── ...
```

**Hidden files** start with a `.` — that's why `.bashrc`, `.ssh`, `.gitconfig` are invisible to `ls` but visible with `ls -a`.

The `~` symbol is a shortcut for your home directory:
```bash
cd ~            # go to /home/yourname
cd ~/projects   # go to /home/yourname/projects
echo $HOME      # prints /home/yourname
```

---

### `/tmp` — Scratch Paper

Temporary files live here. **Wiped on reboot.** Don't store anything important here.

```bash
# Safe place to download and test files
cd /tmp
wget https://example.com/test-file.tar.gz
tar -xf test-file.tar.gz
```

---

### `/proc` — The System's Live Dashboard

`/proc` is a **virtual filesystem** — the files don't exist on disk. The kernel creates them in memory in real time.

```bash
# What CPU do you have?
cat /proc/cpuinfo

# How much memory is available?
cat /proc/meminfo

# See info for process ID 1234
ls /proc/1234/

# System uptime
cat /proc/uptime

# Kernel version
cat /proc/version
```

---

### `/dev` — Device Files

Every device attached to the system has a file here:

```bash
/dev/
├── sda             ← first hard disk
├── sda1            ← first partition of first hard disk
├── sdb             ← second hard disk (e.g., attached EBS volume)
├── tty0            ← first terminal
├── null            ← the "black hole" (discard anything written here)
├── zero            ← infinite stream of zero bytes
└── random          ← random data generator
```

```bash
# Discard output (the black hole trick)
some_noisy_command > /dev/null 2>&1

# Check disk size
lsblk                     # list all block devices
fdisk -l /dev/sda         # partition table of disk
```

---

## 4. Absolute vs Relative Paths

**Absolute path** — starts from root `/`, works from anywhere:
```bash
cd /home/alice/projects    # always goes to the same place
cat /etc/nginx/nginx.conf
```

**Relative path** — relative to where you currently are:
```bash
cd projects          # goes to ./projects from current directory
cd ../logs           # go up one level, then into logs
cat ./config.yaml    # file in current directory
```

Special path symbols:
```bash
.     ← current directory
..    ← parent directory
~     ← your home directory (/home/yourname)
-     ← previous directory (cd - goes back)
/     ← root directory
```

---

## 5. Navigating Efficiently

```bash
# Where am I?
pwd

# Go home
cd ~

# Go to previous directory (toggle between two dirs)
cd -

# List directory contents
ls                  # basic list
ls -l               # long format (permissions, size, date)
ls -la              # include hidden files
ls -lh              # human-readable file sizes

# Find a file by name
find /etc -name "nginx.conf"

# Find a file containing text
grep -r "ServerName" /etc/apache2/
```

---

## 6. Summary

```
Key directories:
  /           Root — the top of everything
  /etc        Configuration files for system and apps
  /var/log    Logs — first stop when debugging
  /home       User home directories
  /tmp        Temporary files, wiped on reboot
  /proc       Live kernel and process info (virtual)
  /dev        Device files (disks, terminals)
  /usr/bin    Most executable programs live here
  /bin        Essential commands needed to boot

Golden rules:
  ✓ Config lives in /etc
  ✓ Logs live in /var/log
  ✓ ~ means your home directory
  ✓ . is current dir, .. is parent dir
  ✓ Hidden files start with a dot (.)
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Distros](../01_fundamentals/distros.md) &nbsp;|&nbsp; **Next:** [File Operations →](./file_operations.md)

**Related Topics:** [File Operations](./file_operations.md) · [Links and Inodes](./links_and_inodes.md)

---

## 📝 Practice Questions

- 📝 [Q4 · filesystem-hierarchy](../linux_practice_questions_100.md#q4--normal--filesystem-hierarchy)
- 📝 [Q5 · absolute-vs-relative-path](../linux_practice_questions_100.md#q5--normal--absolute-vs-relative-path)
- 📝 [Q6 · directory-navigation](../linux_practice_questions_100.md#q6--normal--directory-navigation)

