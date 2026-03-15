# Linux — Overview

> Before you run a single command, understand WHY Linux exists and WHY every developer, DevOps engineer, and cloud architect needs to know it.

---

## 1. What Is Linux? (The Simple Explanation)

Imagine your computer as a building.

- The **hardware** (CPU, RAM, disk) is the foundation and walls
- The **operating system** is the building manager — it controls who gets access to what room, when the lights turn on, and how resources are shared
- Your **apps** (browser, code editor, web server) are the tenants living inside

**Linux is that building manager.**

It's an operating system — just like Windows or macOS — but it runs on everything: your laptop, web servers, cloud VMs, Android phones, smart TVs, NASA spacecraft, and the supercomputers that train AI models.

---

## 2. Why Does Linux Dominate Servers?

```
Where Linux runs today:
─────────────────────────────────────────────────────────────
  Web Servers      96.3% of the top 1 million websites
  Cloud            AWS, GCP, Azure — all run Linux VMs
  Android phones   Built on the Linux kernel
  Supercomputers   500 out of top 500 run Linux
  Embedded devices Routers, smart TVs, IoT sensors
  Docker           Every container runs on a Linux kernel
─────────────────────────────────────────────────────────────
```

When you deploy code to AWS, your EC2 instance runs Linux.
When you run a Docker container, it runs on a Linux kernel.
When you SSH into any server, you're talking to Linux.

**You cannot be a backend developer, DevOps engineer, or cloud architect without knowing Linux.**

---

## 3. The Story of Linux in 2 Minutes

**1969 — Unix is born at Bell Labs**
Engineers Ken Thompson and Dennis Ritchie build Unix — the grandfather of all modern operating systems. They introduced a powerful idea: *"everything is a file."*

**1984 — The GNU Project starts**
Richard Stallman wants a free, open-source Unix-like OS. He builds all the tools (compiler, editor, shell) but never finishes the core engine — the kernel.

**1991 — Linus Torvalds fills the gap**
A 21-year-old Finnish student posts on a newsgroup:

> *"I'm doing a (free) operating system (just a hobby, won't be big and professional like gnu)..."*

That "hobby" became the Linux kernel — the missing piece that plugged into GNU's tools. Together, they became a complete, free operating system.

**Today — Linux runs the world**
Red Hat, Ubuntu, Android, Docker, Kubernetes — all built on Linux. Google, Netflix, Amazon — all run on Linux.

---

## 4. The Problem It Solves

### Before Linux (Windows Server Era)

```
┌─────────────────────────────────────────────────────────────┐
│  Company wants to run a web server                          │
│                                                             │
│  Cost:    Windows Server license = $3,000+ per year         │
│  Source:  Closed — can't see or change how it works         │
│  Control: Vendor lock-in, updates on Microsoft's schedule   │
│  Scale:   Limited to what Microsoft supports                │
└─────────────────────────────────────────────────────────────┘
```

### With Linux

```
┌─────────────────────────────────────────────────────────────┐
│  Company wants to run a web server                          │
│                                                             │
│  Cost:    $0 — completely free                              │
│  Source:  Open source — read, modify, contribute            │
│  Control: Full control — customize everything               │
│  Scale:   Google, Netflix, Amazon run millions of servers   │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Real World — Your Daily Linux Commands

As a developer or DevOps engineer, here's what a typical day looks like:

```bash
# Morning — connect to a remote AWS server
ssh ubuntu@my-server.amazonaws.com

# Watch live application logs (like tail on a log file)
tail -f /var/log/app.log

# Debugging — find a runaway process eating CPU
ps aux | grep python

# Check if the disk is full (very common production issue)
df -h

# See what ports are open on the server
netstat -tlnp

# Deployment — restart your service after a new release
systemctl restart myapp

# Check last 50 log lines for errors
journalctl -u myapp -n 50

# Run a deployment script
chmod +x deploy.sh && ./deploy.sh
```

Every single one of these is a Linux command. You will use them every day in your career.

---

## 6. Linux vs Windows vs macOS

```
                Linux           Windows         macOS
─────────────────────────────────────────────────────────────
Cost            Free            $100–$200       Free (Mac only)
Source code     Open            Closed          Mostly closed
Server share    96%             3%              <1%
Customizable    Fully           Limited         Moderate
Package mgr     apt / yum       Winget          Homebrew
Shell           bash / zsh      PowerShell      zsh (Unix-based)
─────────────────────────────────────────────────────────────
```

macOS is actually Unix-based (a cousin of Linux) — which is why Mac terminals feel so similar. Windows is the odd one out on servers.

---

## 7. The Core Mental Model — Everything Is a File

The single most important Linux idea:

**In Linux, everything is a file.**

| Thing | Location |
|-------|----------|
| A text document | `/home/user/notes.txt` |
| A directory | a special type of file |
| Your hard disk | `/dev/sda` |
| Your keyboard | `/dev/input/event0` |
| A running process | `/proc/1234/status` |
| System config | `/etc/nginx/nginx.conf` |

This unified model is why Linux is so powerful. One set of tools (`cat`, `grep`, `pipe`) works on ALL of them.

```bash
# Read a normal file
cat /etc/hostname

# Read CPU info — it's a file too!
cat /proc/cpuinfo

# Read memory usage
cat /proc/meminfo

# See running processes listed as files
ls /proc/
```

---

## 8. Summary

```
Linux is:
  ✓ A free, open-source operating system (born 1991)
  ✓ Running on 96%+ of all web servers and every major cloud
  ✓ Built on the principle that "everything is a file"
  ✓ Non-negotiable knowledge for developers and DevOps engineers

You will use Linux for:
  ✓ Managing servers and cloud VMs (AWS EC2, GCP, Azure)
  ✓ Running Docker containers and Kubernetes clusters
  ✓ Debugging production issues live
  ✓ Automating deployments with bash scripts
  ✓ Provisioning infrastructure with Terraform
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** — &nbsp;|&nbsp; **Next:** [Architecture →](./architecture.md)

**Related Topics:** [Architecture](./architecture.md) · [Distros](./distros.md)
