# Linux — Architecture

> You don't need to memorise kernel internals. You need the mental model — what happens between you typing a command and the hardware doing something.

---

## 1. The Analogy — A Restaurant

Think of Linux as a restaurant:

```
┌─────────────────────────────────────────────────────────────┐
│                     LINUX AS A RESTAURANT                   │
│                                                             │
│  You (customer)          →   User / Application            │
│  Waiter (takes order)    →   Shell (bash, zsh)             │
│  Kitchen manager         →   Kernel                        │
│  Kitchen equipment       →   Hardware (CPU, RAM, Disk)     │
│                                                             │
│  You tell the waiter what you want.                         │
│  The waiter translates and tells the kitchen.               │
│  The kitchen manager decides what equipment to use.         │
│  You never touch the stove yourself.                        │
└─────────────────────────────────────────────────────────────┘
```

You (the user) never talk directly to the hardware. Every request goes through layers.

---

## 2. The Four Layers of Linux

```
┌─────────────────────────────────────────────────────────────┐
│                         APPLICATIONS                        │
│         nginx, python, mysql, your code, vim, etc.          │
├─────────────────────────────────────────────────────────────┤
│                           SHELL                             │
│              bash, zsh — your command interface             │
├─────────────────────────────────────────────────────────────┤
│                          KERNEL                             │
│     process mgmt · memory mgmt · file system · networking   │
├─────────────────────────────────────────────────────────────┤
│                         HARDWARE                            │
│              CPU · RAM · Disk · Network card                │
└─────────────────────────────────────────────────────────────┘
```

Each layer only talks to the layer directly above and below it. This separation is what makes Linux so stable and secure.

---

## 3. Layer 1 — Hardware

The physical components:

| Component | What it does |
|-----------|-------------|
| **CPU** | Executes instructions — does the actual work |
| **RAM** | Stores data actively being used (fast, temporary) |
| **Disk** | Stores data permanently (slow, persistent) |
| **Network card** | Sends and receives data over networks |
| **GPU** | Graphics processing (and now, AI/ML workloads) |

The hardware doesn't understand your Python code. It only understands low-level machine instructions. That's the kernel's job — translate.

---

## 4. Layer 2 — The Kernel

The kernel is the **core of Linux**. It's the first thing that loads when you boot the machine, and it stays running until you shut down.

Think of it as the **master controller** that manages everything:

```
What the kernel does:
─────────────────────────────────────────────────────────────
  Process Management    Create, schedule, kill processes
                        Decide which process runs on CPU now
                        Give each process fair CPU time

  Memory Management     Allocate RAM to processes
                        Prevent process A reading process B's memory
                        Swap to disk when RAM is full

  File System           Read/write files on disk
                        Manage directories and permissions
                        Support ext4, xfs, btrfs formats

  Device Drivers        Talk to hardware (keyboard, disk, GPU)
                        Translate general commands to device-specific

  Networking            Send/receive network packets
                        Manage TCP/IP connections
                        Firewall rules (iptables)
─────────────────────────────────────────────────────────────
```

**You never interact with the kernel directly.** You go through the shell or system calls.

---

## 5. Layer 3 — The Shell

The shell is your **command-line interface** — the waiter in our restaurant analogy.

When you type:
```bash
ls -la /home/user
```

Here's what happens step by step:

```
1. You type "ls -la /home/user" and press Enter
        ↓
2. Shell (bash) reads your input
        ↓
3. Shell finds the "ls" program at /bin/ls
        ↓
4. Shell asks the kernel to run /bin/ls with arguments "-la /home/user"
        ↓
5. Kernel creates a new process for ls
        ↓
6. ls reads directory contents via kernel's file system calls
        ↓
7. ls sends output back to your terminal
        ↓
8. You see the result
```

Common shells:

| Shell | Description |
|-------|-------------|
| **bash** | Default on most Linux systems. Most scripts use bash. |
| **zsh** | Default on macOS. More features, plugins. |
| **sh** | Original POSIX shell. Very basic but universal. |
| **fish** | User-friendly, good autocomplete. Less common on servers. |

On servers, you'll almost always use **bash**.

---

## 6. Layer 4 — Applications

Everything you actually use lives here: your web server (nginx), database (postgres), application code (Python, Node), editor (vim, nano), and tools like `curl`, `git`, `docker`.

Applications talk to the kernel through **system calls** (syscalls) — a defined set of functions the kernel exposes:

```
Common syscalls (you never call these directly, but they happen):
─────────────────────────────────────────────────────────────
  open()      Open a file
  read()      Read data from a file or socket
  write()     Write data to a file or socket
  fork()      Create a new process
  exec()      Replace current process with a new program
  kill()      Send a signal to a process
  socket()    Create a network connection
─────────────────────────────────────────────────────────────
```

When your Python script opens a file with `open("data.txt")`, Python calls the kernel's `open()` syscall underneath. You never see it, but it's always there.

---

## 7. What Happens When You Boot Linux

```
Power ON
    ↓
BIOS / UEFI runs
(checks hardware, finds boot device)
    ↓
Bootloader (GRUB) runs
(lets you choose which OS or kernel version)
    ↓
Linux Kernel loads into RAM
(initialises hardware, mounts root filesystem)
    ↓
init / systemd starts
(the first process, PID 1 — starts all other services)
    ↓
Services start
(networking, SSH, web server, database...)
    ↓
Login prompt / Desktop appears
```

`systemd` (PID 1) is the parent of all processes. If it dies, the system crashes.

---

## 8. Kernel Space vs User Space

This is an important distinction:

```
┌─────────────────────────────────────────────────────────────┐
│                        USER SPACE                           │
│   Your apps, shell, tools — run here                        │
│   LIMITED access to hardware                                │
│   If your app crashes, only that app dies                   │
├─────────────────────────────────────────────────────────────┤
│                       KERNEL SPACE                          │
│   The kernel runs here — full hardware access               │
│   If something crashes here, the whole system crashes       │
│   (kernel panic = "blue screen" equivalent for Linux)       │
└─────────────────────────────────────────────────────────────┘
```

This separation is a security feature. Your buggy Python script can't corrupt kernel memory.

---

## 9. Summary

```
Linux Architecture:
  Hardware    →  physical components (CPU, RAM, Disk, Network)
  Kernel      →  master controller, manages all hardware access
  Shell       →  your interface to the kernel (bash, zsh)
  Apps        →  everything you actually use

Key ideas:
  ✓ You never talk to hardware directly — always through the kernel
  ✓ The kernel is the only software with full hardware access
  ✓ systemd (PID 1) starts everything else on boot
  ✓ Kernel space crash = system down. User space crash = one app down.
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Overview](./overview.md) &nbsp;|&nbsp; **Next:** [Distros →](./distros.md)

**Related Topics:** [Overview](./overview.md) · [Distros](./distros.md)
