# Linux — Distributions (Distros)

> Linux is not one thing. It's a kernel that dozens of organisations have packaged differently. Pick the right one for the job.

---

## 1. What Is a Distro?

Think of the Linux kernel as a car engine. It works, but on its own it's not driveable. A **distribution (distro)** takes that engine and adds:

- A body (desktop environment or server tools)
- A dashboard (package manager, system settings)
- Pre-installed parts (default apps, libraries)
- A warranty (long-term support, security updates)

Different companies and communities build different cars from the same engine.

```
Linux Kernel (the engine)
       ↓
  Packaged with:
  ┌──────────────────────────────────────────┐
  │  Package manager  (apt, yum, dnf, pacman) │
  │  Default shell    (bash, zsh)             │
  │  Init system      (systemd, OpenRC)       │
  │  Desktop (optional) (GNOME, KDE, none)    │
  │  Pre-installed tools                      │
  └──────────────────────────────────────────┘
       ↓
  = A Linux Distribution
```

---

## 2. The Major Distro Families

All Linux distros come from a small number of family trees:

```
                        Linux Kernel
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
        Debian             Red Hat             Arch
          │                  │                  │
    ┌─────┴──────┐      ┌────┴─────┐        ┌──┴───┐
  Ubuntu       Mint   RHEL       Fedora   Arch   Manjaro
    │                   │
  ┌─┴──────────┐     CentOS
 Ubuntu      Ubuntu    Amazon
 Server      LTS       Linux
```

The family you use determines which package manager you use — the single biggest day-to-day difference.

---

## 3. The Distros You'll Actually Use

### Ubuntu — The Beginner's Best Friend

```
Who uses it:   Developers, startups, personal projects
Package mgr:   apt (apt install nginx)
Support:       LTS versions supported 5 years
AWS AMI:       Ubuntu 22.04 LTS — very commonly used
Best for:      Learning, development, small-medium servers
```

Ubuntu is the most popular Linux distro for developers. If someone says "spin up a Linux server", they probably mean Ubuntu.

```bash
# Ubuntu package management
sudo apt update               # refresh package list
sudo apt install nginx        # install nginx
sudo apt upgrade              # upgrade all packages
sudo apt remove nginx         # remove nginx
```

---

### Amazon Linux — The AWS Native

```
Who uses it:   AWS users, production workloads on EC2
Package mgr:   yum (Amazon Linux 2) / dnf (Amazon Linux 2023)
Support:       Maintained by AWS, optimised for EC2
AWS AMI:       Default option when launching EC2
Best for:      Production AWS workloads
```

Amazon Linux is based on RHEL/CentOS but tuned for AWS. It comes pre-configured with AWS tools (CLI, SSM agent) and gets AWS-specific kernel patches.

```bash
# Amazon Linux 2 package management
sudo yum update
sudo yum install nginx
sudo yum remove nginx

# Amazon Linux 2023
sudo dnf update
sudo dnf install nginx
```

---

### Red Hat Enterprise Linux (RHEL) — The Enterprise Standard

```
Who uses it:   Large enterprises, banks, telecoms
Package mgr:   dnf / yum
Support:       10 years of paid support from Red Hat
Best for:      Enterprise production, regulated industries
Cost:          Paid subscription
```

RHEL is the enterprise gold standard. If you're working at a bank or large corporation, you'll likely see RHEL. IBM bought Red Hat in 2019.

---

### CentOS / Rocky Linux / AlmaLinux — Free RHEL Clones

CentOS was a free version of RHEL. In 2020, Red Hat changed its direction. The community created two replacements:

- **Rocky Linux** — most popular RHEL replacement, led by original CentOS founder
- **AlmaLinux** — another RHEL clone, backed by CloudLinux

```bash
# All three use dnf/yum
sudo dnf install nginx
sudo dnf update
```

---

### Debian — The Stable Grandparent

```
Who uses it:   Sysadmins who prioritise stability
Package mgr:   apt
Support:       Very long release cycles, extremely stable
Best for:      Servers where stability > new features
```

Ubuntu is based on Debian. Debian is older, more conservative, and preferred by sysadmins who want rock-solid stability.

---

### Arch Linux — For the Curious

```
Who uses it:   Developers who want full control
Package mgr:   pacman
Philosophy:    Install only what you need (starts minimal)
Best for:      Learning Linux deeply, personal machines
```

Arch is not for beginners, but if you want to understand Linux inside-out, building an Arch system from scratch teaches you more than years of using Ubuntu.

---

## 4. Choosing the Right Distro

```
Your situation                   →  Use this
─────────────────────────────────────────────────────────────
Learning Linux for the first time   Ubuntu 22.04 LTS
Deploying on AWS EC2                Amazon Linux 2023
Working at an enterprise/bank       RHEL or Rocky Linux
Need free RHEL replacement          Rocky Linux or AlmaLinux
Want rock-solid stability           Debian
Want to learn Linux deeply          Arch Linux
Running Docker containers           Any (kernel is shared)
─────────────────────────────────────────────────────────────
```

**For this course:** Most examples work on Ubuntu or Amazon Linux. Commands will be noted when they differ.

---

## 5. Package Managers — The Key Difference

The biggest day-to-day difference between distros is the package manager:

| Family | Distros | Command | Package format |
|--------|---------|---------|----------------|
| Debian | Ubuntu, Debian, Mint | `apt` | `.deb` |
| Red Hat | RHEL, CentOS, Amazon Linux | `yum` / `dnf` | `.rpm` |
| Arch | Arch, Manjaro | `pacman` | `.pkg.tar.zst` |

```bash
# Same task — install nginx:

# On Ubuntu / Debian
sudo apt install nginx

# On Amazon Linux / RHEL / CentOS
sudo yum install nginx
# or
sudo dnf install nginx

# On Arch
sudo pacman -S nginx
```

The concept is identical — only the syntax changes.

---

## 6. Linux on the Cloud — What You'll See in the Real World

```
AWS EC2 AMIs most commonly used:
─────────────────────────────────────────────────────────────
  Amazon Linux 2023      AWS's own, free, optimised for EC2
  Ubuntu 22.04 LTS       Most popular community choice
  Ubuntu 20.04 LTS       Older but still widely deployed
  Red Hat Enterprise     Enterprise/regulated workloads
  Debian 12              Stability-focused teams
─────────────────────────────────────────────────────────────
```

In practice, you'll mostly work with **Ubuntu** or **Amazon Linux**. The commands in this course cover both.

---

## 7. Summary

```
Distro families:
  Debian family    Ubuntu, Debian, Mint — uses apt
  Red Hat family   RHEL, CentOS, Amazon Linux — uses yum/dnf
  Arch family      Arch, Manjaro — uses pacman

Pick for your situation:
  ✓ Learning          →  Ubuntu 22.04 LTS
  ✓ AWS production    →  Amazon Linux 2023
  ✓ Enterprise        →  RHEL / Rocky Linux
  ✓ Deep learning     →  Arch Linux

Key insight: The kernel is the same across all distros.
The tools, packaging, and defaults are different.
Once you know one distro, learning another takes days not months.
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Architecture](./architecture.md) &nbsp;|&nbsp; **Next:** [Directory Structure →](../02_filesystem/directory_structure.md)

**Related Topics:** [Overview](./overview.md) · [Architecture](./architecture.md)

---

## 📝 Practice Questions

- 📝 [Q2 · linux-distros](../linux_practice_questions_100.md#q2--normal--linux-distros)

