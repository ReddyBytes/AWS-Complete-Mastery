# Linux Practice Questions — 100 Questions from Basics to Mastery

> Test yourself across the full Linux curriculum. Answers hidden until clicked.

---

## How to Use This File

1. **Read the question** — attempt your answer before opening the hint
2. **Use the framework** — run through the 5-step thinking process first
3. **Check your answer** — click "Show Answer" only after you've tried

---

## How to Think: 5-Step Framework

1. **Restate** — what is this question actually asking?
2. **Identify the concept** — which Linux feature/concept is being tested?
3. **Recall the rule** — what is the exact behaviour or rule?
4. **Apply to the case** — trace through the scenario step by step
5. **Sanity check** — does the result make sense? What edge cases exist?

---

## Progress Tracker

- [ ] **Tier 1 — Basics** (Q1–Q33): Fundamentals and core commands
- [ ] **Tier 2 — Intermediate** (Q34–Q66): Advanced features and real patterns
- [ ] **Tier 3 — Advanced** (Q67–Q75): Deep internals and edge cases
- [ ] **Tier 4 — Interview / Scenario** (Q76–Q90): Explain-it, compare-it, real-world problems
- [ ] **Tier 5 — Critical Thinking** (Q91–Q100): Predict output, debug, design decisions

---

## Question Type Legend

| Tag | Meaning |
|---|---|
| `[Normal]` | Recall + apply — straightforward concept check |
| `[Thinking]` | Requires reasoning about internals |
| `[Logical]` | Predict output or trace execution |
| `[Critical]` | Tricky gotcha or edge case |
| `[Interview]` | Explain or compare in interview style |
| `[Debug]` | Find and fix the broken code/config |
| `[Design]` | Architecture or approach decision |

---

## 🟢 Tier 1 — Basics

---

### Q1 · [Normal] · `linux-vs-windows`

> **What is Linux and why do engineers prefer it for servers over Windows?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Linux is an open-source, Unix-like operating system kernel first created by Linus Torvalds in 1991. Engineers prefer it for servers because it is free, stable, highly configurable, and dominates cloud and server infrastructure.

**How to think through this:**
1. Linux is the kernel — the core that manages hardware, memory, and processes. Distributions bundle it with tools to make a full OS.
2. On servers, Linux wins on cost (free licensing), stability (runs for years without reboots), and control (no forced updates, full root access, CLI-first).
3. Windows Server carries licensing costs, a heavier resource footprint, and a GUI-first design that wastes memory on servers that only need a shell.

**Key takeaway:** Linux dominates servers because it is free, stable, scriptable, and built for headless operation — everything Windows Server is not optimized for.

</details>

📖 **Theory:** [linux-vs-windows](./01_fundamentals/overview.md#6-linux-vs-windows-vs-macos)


---

### Q2 · [Normal] · `linux-distros`

> **Name 3 popular Linux distributions. What are the differences between Debian-based and RedHat-based distros?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Three popular distros: Ubuntu, CentOS/RHEL, and Arch Linux. Debian-based distros use `apt` and `.deb` packages; RedHat-based distros use `yum`/`dnf` and `.rpm` packages.

**How to think through this:**
1. Debian-based: Ubuntu, Debian, Linux Mint. Package manager is `apt`. Package format is `.deb`. Common in developer workstations and cloud VMs (AWS Ubuntu AMIs).
2. RedHat-based: RHEL, CentOS, Fedora, Amazon Linux. Package manager is `yum` or `dnf`. Package format is `.rpm`. Common in enterprise and AWS environments.
3. The core kernel is the same — the differences are in package management, default configs, support model, and release cycles.

**Key takeaway:** Debian vs RedHat is mostly a package manager and ecosystem difference — `apt`/`.deb` vs `yum`/`.rpm` — the Linux kernel underneath is the same.

</details>

📖 **Theory:** [linux-distros](./01_fundamentals/distros.md#linux--distributions-distros)


---

### Q3 · [Normal] · `linux-architecture`

> **Describe the Linux architecture: kernel, shell, user space. What role does each play?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The kernel manages hardware and system resources. The shell is the interface between users and the kernel. User space is where applications and processes run.

**How to think through this:**
1. **Kernel** — the innermost layer. Handles CPU scheduling, memory management, device drivers, and system calls. Users never interact with it directly.
2. **Shell** — a command interpreter (bash, zsh, sh) that translates user commands into system calls the kernel can execute. It sits between the user and the kernel.
3. **User space** — everything that runs as a user process: your applications, daemons, utilities (`ls`, `grep`, `nginx`). These communicate with the kernel via system calls (read, write, fork, exec).

**Key takeaway:** Think of it as concentric rings — kernel at the center touching hardware, shell as the translator, user space as where all visible work happens.

</details>

📖 **Theory:** [linux-architecture](./01_fundamentals/architecture.md#linux--architecture)


---

### Q4 · [Normal] · `filesystem-hierarchy`

> **What does FHS stand for? What is stored in `/etc`, `/var`, `/tmp`, `/home`, `/usr`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
FHS stands for Filesystem Hierarchy Standard. It defines where files live on any Linux system so tools and admins can find them predictably.

**How to think through this:**
1. `/etc` — system-wide configuration files. Think "editable text configs." Examples: `/etc/nginx/nginx.conf`, `/etc/passwd`, `/etc/hosts`.
2. `/var` — variable data that changes at runtime. Logs (`/var/log`), mail spools, databases, PID files. "Varies" while the system runs.
3. `/tmp` — temporary files. Wiped on reboot. Safe scratch space for short-lived data.
4. `/home` — user home directories. `/home/alice`, `/home/bob`. Each user's personal files live here.
5. `/usr` — user binaries and read-only data. `/usr/bin` has most user commands, `/usr/lib` has libraries. Not user-writable at runtime.

**Key takeaway:** FHS gives every Linux system a predictable map — configs in `/etc`, logs in `/var/log`, temp data in `/tmp`, user files in `/home`.

</details>

📖 **Theory:** [filesystem-hierarchy](./02_filesystem/directory_structure.md#linux--directory-structure)


---

### Q5 · [Normal] · `absolute-vs-relative-path`

> **What is the difference between `/home/user/file.txt` and `./file.txt`? When would you use each?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`/home/user/file.txt` is an absolute path — it starts from root `/` and is always unambiguous. `./file.txt` is a relative path — it means "file.txt in the current directory."

**How to think through this:**
1. Absolute paths start with `/`. They work from any directory, any script, any context. Use them in cron jobs, systemd units, and scripts that may run from unpredictable locations.
2. Relative paths depend on your current working directory (`pwd`). `./file.txt` means the same directory you are in right now. `../file.txt` means one directory up.
3. In scripts run by automation (cron, CI), always use absolute paths — you cannot guarantee what the working directory will be at runtime.

**Key takeaway:** Use absolute paths in scripts and automation for reliability; use relative paths interactively when you know where you are.

</details>

📖 **Theory:** [absolute-vs-relative-path](./02_filesystem/directory_structure.md#4-absolute-vs-relative-paths)


---

### Q6 · [Normal] · `directory-navigation`

> **What do `cd ~`, `cd -`, and `cd ..` do? What is `pwd` for?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`cd ~` goes to your home directory, `cd -` toggles back to the previous directory, `cd ..` moves up one level. `pwd` prints the current working directory.

**How to think through this:**
1. `cd ~` expands `~` to `$HOME` (e.g., `/home/alice`). Shortcut to return home from anywhere.
2. `cd -` is like the "back" button. It switches to `$OLDPWD` — the directory you were in before the last `cd`. Run it again to toggle back.
3. `cd ..` navigates to the parent directory. `/home/alice/projects` becomes `/home/alice`.
4. `pwd` (print working directory) outputs your exact current location. Useful in scripts and when you are lost in a deep directory tree.

**Key takeaway:** `cd -` is the fastest way to switch between two directories; `pwd` tells you exactly where you are when in doubt.

</details>

📖 **Theory:** [directory-navigation](./02_filesystem/directory_structure.md#linux--directory-structure)


---

### Q7 · [Normal] · `ls-command`

> **How do `ls -la`, `ls -lh`, and `ls -lt` differ? What does each flag add?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`-l` gives long format. `-a` adds hidden files (dotfiles). `-h` makes sizes human-readable. `-t` sorts by modification time newest first.

**How to think through this:**
1. `ls -la` = long format (`-l`) + all files including hidden (`-a`). You see permissions, owner, group, size, timestamp, and files starting with `.` like `.bashrc`.
2. `ls -lh` = long format + human-readable sizes (`-h`). Instead of `1048576`, you see `1.0M`. Essential when scanning disk usage.
3. `ls -lt` = long format + sort by time (`-t`). The most recently modified file appears first. Add `-r` to reverse: `ls -ltr` shows oldest first, newest last — great for log files.

**Key takeaway:** `-a` reveals hidden files, `-h` makes sizes readable, `-t` sorts by time — combine them freely: `ls -lahtr` is a power move.

</details>

📖 **Theory:** [ls-command](./02_filesystem/file_operations.md#create-nested-directories-all-in-one-command)


---

### Q8 · [Normal] · `file-operations`

> **What commands copy, move, rename, and delete files? What is the difference between `rm` and `rm -rf`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`cp` copies, `mv` moves and renames, `rm` deletes files. `rm -rf` recursively force-deletes entire directory trees with no confirmation.

**How to think through this:**
1. Copy: `cp source.txt dest.txt` — creates a duplicate. `cp -r dir1/ dir2/` copies a directory recursively.
2. Move/rename: `mv old.txt new.txt` renames in place. `mv file.txt /tmp/` moves it to another directory. `mv` is atomic on the same filesystem.
3. Delete: `rm file.txt` deletes a file. `rm -r dir/` removes a directory recursively. `rm -f` suppresses errors and prompts (force). `rm -rf` combines both — it will delete everything without asking, including non-empty directories.
4. `rm -rf /` or `rm -rf /*` are catastrophic — they delete the entire filesystem. Always double-check the path before running `rm -rf`.

**Key takeaway:** `rm -rf` has no undo — it is the most dangerous command a new admin can run; always verify your path before executing it.

</details>

📖 **Theory:** [file-operations](./02_filesystem/file_operations.md#linux--file-operations)


---

### Q9 · [Thinking] · `find-command`

> **Write a `find` command that finds all `.log` files in `/var/log` modified in the last 7 days.**

```bash
find /var/log -name "*.log" -mtime -7
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`find /var/log -name "*.log" -mtime -7`

**How to think through this:**
1. `find /var/log` — start the search from `/var/log` recursively.
2. `-name "*.log"` — match files whose name ends in `.log`. The `*` is a glob wildcard. Quote it to prevent shell expansion before `find` sees it.
3. `-mtime -7` — modified time less than 7 days ago. `-7` means "within the last 7 days." `+7` would mean "older than 7 days." `7` (no sign) means exactly 7 days.
4. To also act on results: `find /var/log -name "*.log" -mtime -7 -exec ls -lh {} \;`

**Key takeaway:** In `find`, `-mtime -N` means "newer than N days," `+N` means "older than N days" — the sign direction is easy to mix up.

</details>

📖 **Theory:** [find-command](./02_filesystem/file_operations.md#create-nested-directories-all-in-one-command)


---

### Q10 · [Normal] · `file-permissions-read`

> **What does `-rwxr-xr--` mean? Which users can execute this file?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`-rwxr-xr--` means: regular file, owner has read/write/execute, group has read/execute, others have read only. Owner and group members can execute it; others cannot.

**How to think through this:**
1. The first character `-` means regular file (`d` = directory, `l` = symlink).
2. Next 9 characters are 3 triplets of `rwx`: owner | group | others.
3. `rwx` = owner can read, write, execute.
4. `r-x` = group can read and execute, but not write.
5. `r--` = others can only read. No execute bit (`x`) for others.
6. So: owner (always), group members (yes), others (no execute).

**Key takeaway:** Read the 9 permission characters as three groups of three — owner, group, others — and check each `x` position for execute access.

</details>

📖 **Theory:** [file-permissions-read](./04_users_permissions/file_permissions.md#linux--file-permissions)


---

### Q11 · [Normal] · `chmod`

> **What does `chmod 755 script.sh` do? Why is 755 a common permission for scripts?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`chmod 755 script.sh` sets: owner = rwx (7), group = r-x (5), others = r-x (5). Everyone can read and execute; only the owner can write.

**How to think through this:**
1. Octal notation: each digit maps to a triplet. r=4, w=2, x=1. Add them: rwx=7, r-x=5, r--=4, ---=0.
2. `7` = 4+2+1 = rwx (owner gets full control).
3. `5` = 4+0+1 = r-x (group and others can read and run, but not modify).
4. 755 is the standard for scripts and executables you want to share: anyone can run it, only you can edit it. Prevents accidental modification by other users.
5. Compare with 644 (no execute — good for config files) and 700 (private scripts only owner can run).

**Key takeaway:** 755 = "I own it, everyone can run it" — the standard permission for deployed scripts and binaries.

</details>

📖 **Theory:** [chmod](./04_users_permissions/file_permissions.md#5-chmod--change-permissions)


---

### Q12 · [Normal] · `chown`

> **What does `chown alice:developers file.txt` do? What is the difference between user owner and group owner?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`chown alice:developers file.txt` sets the user owner to `alice` and the group owner to `developers`. User owner controls who gets the "owner" permission triplet; group owner determines who gets the "group" permission triplet.

**How to think through this:**
1. Every file has two ownership fields: a user (UID) and a group (GID).
2. `chown user:group file` sets both at once. `chown alice file.txt` sets only the user owner. `chown :developers file.txt` sets only the group.
3. User owner: the single user who gets the first `rwx` triplet in `ls -l`. Typically the file creator.
4. Group owner: any user who is a member of `developers` gets the second `rwx` triplet. This enables team sharing — one file, multiple people with group-level access.
5. `chown -R alice:developers /project/` applies recursively to a directory tree.

**Key takeaway:** Group ownership is how Linux enables team file sharing — set the group owner and grant group-level permissions so all team members share the same access level.

</details>

📖 **Theory:** [chown](./04_users_permissions/file_permissions.md#6-chown--change-owner)


---

### Q13 · [Thinking] · `pipes`

> **What does `cat /etc/passwd | grep root | cut -d: -f1` do? Trace each pipe step.**

```bash
cat /etc/passwd | grep root | cut -d: -f1
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
It prints the username field of every line in `/etc/passwd` that contains the word "root."

**How to think through this:**
1. `cat /etc/passwd` — reads the entire passwd file and sends it to stdout. Each line looks like: `root:x:0:0:root:/root:/bin/bash`.
2. `| grep root` — filters stdin, passing only lines that contain the string "root". Drops all other user lines.
3. `| cut -d: -f1` — cuts each line using `:` as the delimiter (`-d:`) and prints only field 1 (`-f1`). For `root:x:0:0:...`, field 1 is `root`.
4. Final output: just the username(s) containing "root" — typically just `root` itself.

**Key takeaway:** Pipes chain single-purpose tools — cat feeds, grep filters, cut extracts — each doing one thing cleanly. This is the Unix philosophy.

</details>

📖 **Theory:** [pipes](./03_shell_basics/pipes_and_redirection.md#linux--pipes-and-redirection)


---

### Q14 · [Normal] · `redirection`

> **What is the difference between `>`, `>>`, `2>`, and `2>&1`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`>` redirects stdout and overwrites the file. `>>` appends stdout to the file. `2>` redirects stderr to a file. `2>&1` merges stderr into stdout so both go to the same destination.

**How to think through this:**
1. `>` — stdout redirection, destructive. `echo "hello" > file.txt` creates or truncates `file.txt`.
2. `>>` — stdout append. `echo "hello" >> file.txt` adds a line without wiping existing content. Safe for log appending.
3. `2>` — stderr redirection. File descriptor 2 is stderr. `command 2> errors.log` captures error messages separately from normal output.
4. `2>&1` — redirect fd 2 to wherever fd 1 currently points. In `command > out.txt 2>&1`, stdout goes to `out.txt`, then stderr is redirected to join stdout there. Order matters: write `> file 2>&1`, not `2>&1 > file`.

**Key takeaway:** `2>&1` means "send stderr to the same place as stdout" — essential for capturing all output in scripts and cron jobs.

</details>

📖 **Theory:** [redirection](./03_shell_basics/pipes_and_redirection.md#linux--pipes-and-redirection)


---

### Q15 · [Critical] · `stdin-stdout-stderr`

> **When you run `./script.sh > out.txt 2>&1 &`, what happens to stdout, stderr, and where does the process run?**

```bash
./script.sh > out.txt 2>&1 &
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
stdout goes to `out.txt`, stderr is merged into stdout (also goes to `out.txt`), and the `&` at the end runs the process in the background of the current shell session.

**How to think through this:**
1. `> out.txt` — redirects stdout (fd 1) to `out.txt`.
2. `2>&1` — redirects stderr (fd 2) to wherever fd 1 currently points, which is now `out.txt`. Both streams land in the same file.
3. `&` — runs the command as a background job. The shell returns your prompt immediately and prints a job number like `[1] 12345`. The process runs concurrently.
4. If you close the terminal, the background job receives SIGHUP and typically dies — unless you used `nohup` or `disown`.

**Key takeaway:** `> file 2>&1 &` is the classic "run and log everything in the background" pattern — but it dies when the terminal closes; use `nohup` to survive logout.

</details>

📖 **Theory:** [stdin-stdout-stderr](./03_shell_basics/pipes_and_redirection.md#redirect-both-stdout-and-stderr-to-a-file)


---

### Q16 · [Normal] · `grep-basics`

> **How do `grep -i`, `grep -r`, `grep -v`, and `grep -n` differ?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`-i` is case-insensitive, `-r` searches recursively through directories, `-v` inverts the match (shows non-matching lines), `-n` shows line numbers.

**How to think through this:**
1. `grep -i "error" app.log` — matches "error", "Error", "ERROR". Case insensitive. Useful when log formats vary.
2. `grep -r "TODO" /src/` — walks every file under `/src/` recursively. Like `find` + `grep` combined. Use `-rl` to show only filenames.
3. `grep -v "DEBUG" app.log` — inverts: shows every line that does NOT contain "DEBUG". Great for filtering noise.
4. `grep -n "fail" app.log` — prefixes each matching line with its line number. Useful when you need to jump to that line in an editor.
5. These flags compose: `grep -rni "error" /var/log/` searches recursively, case-insensitively, with line numbers.

**Key takeaway:** `-v` is the "exclude" flag — often more useful than searching for what you want when you need to filter out noise.

</details>

📖 **Theory:** [grep-basics](./03_shell_basics/text_processing.md#2-grep--find-lines-matching-a-pattern)


---

### Q17 · [Normal] · `sed-basics`

> **What does `sed 's/foo/bar/g' file.txt` do? How is it different from `sed -i`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`sed 's/foo/bar/g' file.txt` prints the file with all occurrences of "foo" replaced by "bar" — to stdout only, not modifying the file. `sed -i` edits the file in place.

**How to think through this:**
1. `s/foo/bar/` is the substitution command: replace first occurrence of `foo` with `bar` per line.
2. The trailing `g` flag means global — replace ALL occurrences on each line, not just the first.
3. Without `-i`, sed reads the file and writes the result to stdout. The original file is untouched. Pipe to a new file: `sed 's/foo/bar/g' file.txt > new.txt`.
4. `sed -i 's/foo/bar/g' file.txt` modifies the file in place. On macOS, use `sed -i '' 's/foo/bar/g' file.txt` (requires empty string argument).
5. For safety, use `sed -i.bak` to create a backup before in-place editing.

**Key takeaway:** Without `-i`, sed is read-only (output goes to stdout); with `-i`, it rewrites the file — always consider a backup with `-i.bak` in production scripts.

</details>

📖 **Theory:** [sed-basics](./03_shell_basics/text_processing.md#4-sed--find-and-replace-in-text-streams)


---

### Q18 · [Thinking] · `awk-basics`

> **What does `awk '{print $1, $3}' file.txt` do? When would you use `awk` over `cut`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
It prints the first and third whitespace-delimited fields of each line. Use `awk` over `cut` when the delimiter is inconsistent whitespace, when you need math/logic, or when field counts vary per line.

**How to think through this:**
1. `awk` splits each line on whitespace by default. `$1` is the first field, `$3` is the third. `$0` is the whole line.
2. `cut` requires a consistent single-character delimiter (`-d:`). It struggles with multiple spaces or tabs used as separators. `awk` handles any whitespace natively.
3. `awk` can do arithmetic: `awk '{sum += $2} END {print sum}' file.txt` sums a column. `cut` cannot.
4. `awk` can filter: `awk '$3 > 100 {print $1}' file.txt` — print field 1 only when field 3 exceeds 100.
5. `cut` is simpler and faster for fixed delimiters. `awk` is a full programming language.

**Key takeaway:** Use `cut` for simple fixed-delimiter extraction; reach for `awk` when fields are whitespace-separated, you need conditional logic, or arithmetic on columns.

</details>

📖 **Theory:** [awk-basics](./03_shell_basics/text_processing.md#3-awk--process-columns-of-data)


---

### Q19 · [Normal] · `process-list`

> **What is the difference between `ps aux` and `top`? What does the `Z` state in `ps` mean?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`ps aux` is a static snapshot of all running processes. `top` is a live, auto-refreshing view of processes sorted by CPU usage. `Z` state means zombie — the process has exited but its parent has not yet called `wait()` to collect its exit status.

**How to think through this:**
1. `ps aux` — `a` shows processes from all users, `u` gives user-oriented format (shows username, CPU%, MEM%), `x` includes processes not attached to a terminal. One-time snapshot, great for scripting.
2. `top` — interactive, refreshes every few seconds, shows CPU and memory in real time. Press `q` to quit, `k` to kill a process by PID, `M` to sort by memory.
3. Process states in `ps`: `R` = running, `S` = sleeping (interruptible), `D` = uninterruptible sleep (usually I/O), `T` = stopped, `Z` = zombie.
4. A zombie process holds a PID and an entry in the process table but consumes no CPU or memory. It disappears when the parent process reaps it or the parent dies.

**Key takeaway:** `Z` (zombie) processes are not dangerous by themselves, but many zombies indicate a buggy parent process that is not reaping its children.

</details>

📖 **Theory:** [process-list](./05_processes/process_management.md#linux--process-management)


---

### Q20 · [Normal] · `kill-signals`

> **What is the difference between `kill -9` (SIGKILL) and `kill -15` (SIGTERM)?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
SIGTERM (15) is a polite request to terminate — the process can catch it and clean up. SIGKILL (9) is an immediate, unconditional kill sent by the kernel — the process cannot ignore or handle it.

**How to think through this:**
1. `kill -15 PID` (or just `kill PID`) sends SIGTERM. Well-written applications listen for SIGTERM to flush buffers, close connections, write state, and exit gracefully.
2. `kill -9 PID` sends SIGKILL. The kernel terminates the process immediately. No cleanup, no handlers, no chance to flush. Can leave locked files, incomplete writes, or dangling sockets.
3. Protocol: always try SIGTERM first. Give the process a few seconds. If it does not exit, escalate to SIGKILL.
4. `kill -l` lists all available signals. Common others: SIGHUP (1) = reload config, SIGINT (2) = Ctrl+C, SIGSTOP (19) = pause (cannot be caught).

**Key takeaway:** SIGTERM = "please stop" (process cooperates); SIGKILL = "stop now" (kernel forces it) — always try 15 before 9.

</details>

📖 **Theory:** [kill-signals](./05_processes/signals.md#3-sending-signals-with-kill)


---

### Q21 · [Normal] · `background-jobs`

> **What do `&`, `jobs`, `fg`, `bg`, and `nohup` do? How do you run a process that survives logout?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`&` starts a process in the background. `jobs` lists background jobs in the current shell. `fg` brings a job to the foreground. `bg` resumes a stopped job in the background. `nohup` makes a process immune to SIGHUP so it survives terminal logout.

**How to think through this:**
1. `./script.sh &` — runs the script as a background job, returns your prompt immediately. The shell prints `[1] 12345` (job number and PID).
2. `jobs` — lists all current shell's background and stopped jobs with their job numbers.
3. `fg %1` — brings job 1 to the foreground. `bg %1` — resumes a stopped (Ctrl+Z) job in the background.
4. `Ctrl+Z` — suspends the foreground process (sends SIGSTOP). Then use `bg` to continue it in the background.
5. `nohup ./script.sh &` — `nohup` redirects stdout/stderr to `nohup.out` and ignores SIGHUP. The process continues even after you log out. For more control, use `screen` or `tmux`.

**Key takeaway:** `nohup command &` is the minimal way to fire-and-forget a long-running process that must survive your session ending.

</details>

📖 **Theory:** [background-jobs](./05_processes/jobs_and_daemons.md#3-the-problem--background-jobs-die-when-you-log-out)


---

### Q22 · [Normal] · `users-groups`

> **How do `adduser`, `useradd`, and `usermod` differ? How do you add a user to a group?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`adduser` is a high-level interactive script (Debian/Ubuntu) that creates a user with home directory and prompts for a password. `useradd` is the low-level binary available on all distros — minimal defaults, no prompts. `usermod` modifies an existing user's attributes.

**How to think through this:**
1. `adduser alice` (Debian/Ubuntu) — creates the user, home directory, sets password interactively, adds to default group. Friendly and safe for manual use.
2. `useradd -m -s /bin/bash alice` — creates the user but you must specify flags explicitly: `-m` for home dir, `-s` for shell. Preferred in scripts for portability.
3. `usermod -aG developers alice` — adds alice to the `developers` group. `-a` means append (do NOT omit it — without `-a`, it replaces all groups). `-G` specifies the supplementary group.
4. To verify: `groups alice` or `id alice`.

**Key takeaway:** Always use `usermod -aG` (not just `-G`) when adding a user to a group — omitting `-a` removes the user from all their other groups.

</details>

📖 **Theory:** [users-groups](./04_users_permissions/users_and_groups.md#linux--users-and-groups)


---

### Q23 · [Normal] · `sudo`

> **What is the difference between `sudo` and `su`? What file controls sudo permissions?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`sudo` runs a single command as root (or another user) using your own password and logs the action. `su` switches you to another user's full session using that user's password. `sudo` permissions are controlled by `/etc/sudoers`.

**How to think through this:**
1. `sudo apt update` — runs just that one command as root. You authenticate with your own password. The action is logged in `/var/log/auth.log`. You return to your shell after.
2. `su - root` — opens a full login shell as root. Requires root's password. The `-` means load root's full environment. Exit to return.
3. `su alice` — switches to user alice. Requires alice's password (or root running it needs no password).
4. `/etc/sudoers` — defines who can run what as whom. Edit only with `visudo` (validates syntax before saving). A broken sudoers file can lock you out of root access.
5. `%sudo ALL=(ALL:ALL) ALL` — grants all members of the `sudo` group full sudo access.

**Key takeaway:** Prefer `sudo` over `su` in production — it limits blast radius to one command, requires no root password sharing, and leaves an audit trail.

</details>

📖 **Theory:** [sudo](./04_users_permissions/sudo_and_root.md#linux--sudo-and-root)


---

### Q24 · [Normal] · `etc-passwd-shadow`

> **What is stored in `/etc/passwd` vs `/etc/shadow`? Why are they separate files?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`/etc/passwd` stores user account info (username, UID, GID, home dir, shell) and is readable by all users. `/etc/shadow` stores hashed passwords and password policy and is readable only by root. They are separate to prevent unprivileged users from accessing password hashes.

**How to think through this:**
1. `/etc/passwd` format: `alice:x:1001:1001:Alice:/home/alice:/bin/bash`. The `x` in field 2 means the password is in `/etc/shadow`. This file must be world-readable so programs can look up UIDs.
2. `/etc/shadow` format: `alice:$6$hash...:18000:0:99999:7:::`. Contains the hashed password, last change date, min/max age, warning period.
3. If passwords were in `/etc/passwd`, any local user could read the hashes and attempt offline brute-force attacks.
4. `/etc/shadow` is owned by root with permissions `640` or `000`, accessible only by root and sometimes the `shadow` group.

**Key takeaway:** The passwd/shadow split is a security boundary — public user metadata in passwd, secret password hashes locked away in shadow.

</details>

📖 **Theory:** [etc-passwd-shadow](./04_users_permissions/users_and_groups.md#etcpasswd--user-accounts-not-passwords)


---

### Q25 · [Critical] · `file-ownership`

> **A script owned by root with `chmod 4755` (setuid bit). What happens when a non-root user runs it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The script runs with root's effective UID regardless of who invoked it. The non-root user's process temporarily gains root privileges for the duration of that script's execution.

**How to think through this:**
1. `chmod 4755` — the `4` sets the setuid (SUID) bit. `ls -l` shows it as `rwsr-xr-x` (an `s` replaces the owner's `x`).
2. Normally, a process inherits the UID of the user who launched it. With SUID set, the process inherits the file owner's UID (root in this case) as the effective UID.
3. Real-world example: `/usr/bin/passwd` has SUID root so ordinary users can update their own password entry in `/etc/shadow` (which only root can write).
4. Security risk: a SUID root script with a vulnerability (e.g., path injection) can be exploited for privilege escalation. This is why SUID on shell scripts is disabled by Linux and only works reliably on compiled binaries.

**Key takeaway:** SUID on a root-owned file is a privilege escalation vector — it runs as root no matter who calls it, so audit and minimize SUID binaries on any system.

</details>

📖 **Theory:** [file-ownership](./04_users_permissions/file_permissions.md#linux--file-permissions)


---

### Q26 · [Normal] · `package-managers`

> **What is the difference between `apt`, `apt-get`, and `dpkg`? When would you use `dpkg -i`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`apt` is the modern high-level interface (resolves dependencies, manages repos). `apt-get` is the older scripting-stable equivalent of `apt`. `dpkg` is the low-level package tool that installs `.deb` files directly with no dependency resolution.

**How to think through this:**
1. `apt install nginx` — downloads the package and all dependencies from configured repositories, installs everything. Best for interactive use; has a progress bar and cleaner output.
2. `apt-get install nginx` — same as apt but older, more stable output format. Preferred in scripts (output is predictable and unlikely to change between Ubuntu releases).
3. `dpkg -i package.deb` — installs a local `.deb` file you already have. Does NOT resolve dependencies — if deps are missing, it errors. Use when you have a specific `.deb` not in any repo.
4. After a `dpkg -i` with missing deps, run `apt-get install -f` to fix (install missing dependencies).

**Key takeaway:** `dpkg` is the primitive tool for raw `.deb` files; `apt`/`apt-get` wrap it with dependency resolution and repo management — use dpkg only when installing offline or custom packages.

</details>

📖 **Theory:** [package-managers](./07_package_management/apt_and_yum.md#linux--package-management-apt--yumdnf)


---

### Q27 · [Thinking] · `apt-workflow`

> **What is the order of `apt update` → `apt upgrade` → `apt install`? What does each step actually do?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`apt update` refreshes the local package index from repositories. `apt upgrade` installs newer versions of all currently installed packages. `apt install` installs a specific new package.

**How to think through this:**
1. `apt update` — downloads the package lists from all sources in `/etc/apt/sources.list`. Updates the local database of available package versions. Does NOT install anything. Without this step, apt works from a stale index and may install outdated versions.
2. `apt upgrade` — compares installed packages against the refreshed index and upgrades any that have newer versions available. Safe upgrade: will not remove packages or install new dependencies that weren't there before.
3. `apt install nginx` — installs nginx and all its dependencies. If nginx is already installed, it upgrades to the latest version in the index.
4. `apt full-upgrade` (formerly `dist-upgrade`) — like upgrade but will also remove packages or install new dependencies if required to complete the upgrade.

**Key takeaway:** Always `apt update` before `apt install` — without it, you install from a stale index and may miss security patches or get version conflicts.

</details>

📖 **Theory:** [apt-workflow](./07_package_management/apt_and_yum.md#linux--package-management-apt--yumdnf)


---

### Q28 · [Normal] · `yum-dnf`

> **How does `yum` or `dnf` differ from `apt`? Name the RedHat equivalent of `apt update`.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`yum`/`dnf` are the RedHat/CentOS/Fedora package managers using `.rpm` packages and `.repo` files, equivalent in purpose to `apt` for Debian systems. The RedHat equivalent of `apt update` is `yum check-update` or `dnf check-update`.

**How to think through this:**
1. `apt` = Debian ecosystem (`.deb` packages, `/etc/apt/sources.list`). `yum`/`dnf` = RedHat ecosystem (`.rpm` packages, `/etc/yum.repos.d/*.repo`).
2. `dnf` is the modern replacement for `yum` (Fedora 22+, RHEL 8+). Same syntax for most commands.
3. Key equivalents:
   - `apt update` → `yum check-update` / `dnf check-update`
   - `apt install nginx` → `yum install nginx` / `dnf install nginx`
   - `apt remove nginx` → `yum remove nginx`
   - `dpkg -l` → `rpm -qa` (list all installed packages)
4. `yum update` (no package name) updates all packages — closer to `apt upgrade` than `apt update`.

**Key takeaway:** `apt update` only refreshes the index; `yum update` actually performs upgrades — the naming difference trips up people switching between ecosystems.

</details>

📖 **Theory:** [yum-dnf](./07_package_management/apt_and_yum.md#linux--package-management-apt--yumdnf)


---

### Q29 · [Normal] · `ssh-basics`

> **How do `ssh user@host`, `ssh -i key.pem user@host`, and `ssh-copy-id` differ?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`ssh user@host` connects using password or default key. `ssh -i key.pem user@host` specifies an explicit private key file. `ssh-copy-id` copies your public key to a remote server's `~/.ssh/authorized_keys` to enable key-based login.

**How to think through this:**
1. `ssh user@host` — connects to the remote host as `user`. SSH tries keys in `~/.ssh/` (id_rsa, id_ed25519, etc.) first, then falls back to password if configured.
2. `ssh -i ~/.ssh/mykey.pem ec2-user@54.1.2.3` — explicitly specifies the private key. Required for AWS EC2 instances that use downloaded `.pem` key pairs not in your default `~/.ssh/`.
3. `ssh-copy-id user@host` — appends your public key (`~/.ssh/id_rsa.pub` by default) to the remote user's `~/.ssh/authorized_keys`. After this, you can SSH without a password. Use `ssh-copy-id -i key.pub user@host` to specify a key.
4. The key pair: private key stays on your machine, public key goes on the server in `authorized_keys`.

**Key takeaway:** `ssh-copy-id` is the one-time setup step for passwordless SSH — copy your public key to the server once, then connect with just `ssh user@host`.

</details>

📖 **Theory:** [ssh-basics](./06_networking/ssh.md#linux--ssh)


---

### Q30 · [Thinking] · `ssh-config`

> **What is `~/.ssh/config` used for? Write an entry that connects to `myserver` using a specific key and port.**

```
Host myserver
    HostName 54.10.20.30
    User ec2-user
    IdentityFile ~/.ssh/mykey.pem
    Port 2222
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`~/.ssh/config` stores named SSH connection profiles so you can replace long `ssh -i key.pem -p 2222 ec2-user@54.10.20.30` commands with just `ssh myserver`.

**How to think through this:**
1. Each `Host` block defines an alias. `Host myserver` means running `ssh myserver` triggers this profile.
2. `HostName` is the actual IP or FQDN. `User` sets the remote username. `IdentityFile` points to the private key. `Port` overrides the default 22.
3. After saving, `ssh myserver` expands to the full connection automatically. Also works with `scp myserver:/path` and `rsync`.
4. Permissions matter: `chmod 600 ~/.ssh/config` — SSH will refuse to use the config if it is world-readable.
5. `Host *` at the end of the file sets defaults for all connections (e.g., `ServerAliveInterval 60`).

**Key takeaway:** `~/.ssh/config` is a force multiplier — turn complex SSH commands into short aliases and never type IP addresses or key paths again.

</details>

📖 **Theory:** [ssh-config](./06_networking/ssh.md#5-ssh-config-file--stop-typing-long-commands)


---

### Q31 · [Normal] · `scp-rsync`

> **What is the difference between `scp` and `rsync`? When would you use `rsync --delete`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`scp` copies files over SSH unconditionally — always transfers the full file. `rsync` is a delta-sync tool that transfers only changed blocks, preserves metadata, and can mirror directory trees. Use `rsync --delete` to remove files from the destination that no longer exist at the source.

**How to think through this:**
1. `scp file.txt user@host:/tmp/` — simple, always copies the entire file. Good for one-off transfers of a few files.
2. `rsync -avz /src/ user@host:/dst/` — syncs a directory: `-a` preserves permissions/timestamps/symlinks, `-v` verbose, `-z` compress in transit. Only transmits differences — fast for repeated syncs of large directories.
3. `rsync --delete` — deletes files at the destination that have been deleted at the source. Makes the destination an exact mirror. Dangerous if you accidentally swap source and destination.
4. `rsync --dry-run` (or `-n`) — shows what would be transferred without actually doing it. Always use this first when using `--delete`.

**Key takeaway:** Use `scp` for simple one-off copies; use `rsync` for directory mirroring, large files, or repeated syncs — and always `--dry-run` before `--delete`.

</details>

📖 **Theory:** [scp-rsync](./06_networking/ssh.md#copy-files-with-scp-secure-copy)


---

### Q32 · [Normal] · `networking-commands`

> **What do `ifconfig`, `ip addr`, `netstat -tulpn`, and `ss -tulpn` show?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`ifconfig` and `ip addr` show network interfaces and IP addresses. `netstat -tulpn` and `ss -tulpn` show which ports are listening and which processes own them.

**How to think through this:**
1. `ifconfig` — older tool (from `net-tools` package, deprecated on modern Linux). Shows interfaces (eth0, lo), IP addresses, MAC addresses, RX/TX stats. May not be installed by default.
2. `ip addr` (or `ip a`) — modern replacement. Part of `iproute2`, always available. Shows same info plus more. `ip route` shows routing table; `ip link` shows layer-2 state.
3. `netstat -tulpn` — `t`=TCP, `u`=UDP, `l`=listening only, `p`=show process/PID, `n`=numeric (no DNS lookup). Shows every open port and which process is listening.
4. `ss -tulpn` — modern replacement for `netstat`. Faster (reads from kernel directly), same flags. Preferred on modern systems where `netstat` may not be installed.

**Key takeaway:** For "what is listening on port 8080?", use `ss -tulpn | grep 8080` — it is the modern, fast, always-available answer.

</details>

📖 **Theory:** [networking-commands](./06_networking/network_commands.md#linux--network-commands)


---

### Q33 · [Critical] · `dns-resolution`

> **Trace what happens when you run `curl https://example.com`. List the steps from DNS lookup to TCP connection.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The OS resolves the hostname to an IP via DNS, then curl opens a TCP connection to port 443, performs a TLS handshake, sends an HTTP GET request, and receives the response.

**How to think through this:**
1. **DNS resolution** — curl calls `getaddrinfo("example.com")`. The OS checks `/etc/hosts` first (fast local override), then queries the DNS resolver configured in `/etc/resolv.conf` (usually your router or a service like 8.8.8.8). The resolver returns an IP (e.g., `93.184.216.34`).
2. **TCP handshake** — curl opens a TCP socket to `93.184.216.34:443`. Three-way handshake: SYN → SYN-ACK → ACK. Connection established.
3. **TLS handshake** — since it is HTTPS, curl negotiates TLS. Client hello → server certificate → key exchange → session keys agreed. The connection is now encrypted.
4. **HTTP request** — curl sends `GET / HTTP/1.1` with headers (Host, User-Agent, etc.) over the encrypted channel.
5. **HTTP response** — the server sends back status code, headers, and body. curl outputs the body to stdout.
6. Tools to inspect each step: `dig example.com` (DNS), `tcpdump` (TCP), `openssl s_client -connect example.com:443` (TLS), `curl -v` (full verbose trace of all steps).

**Key takeaway:** Every `curl https://` is at least 3 round trips before you see data — DNS lookup, TCP handshake, TLS handshake — which is why DNS and TCP latency matter so much in distributed systems.

</details>

📖 **Theory:** [dns-resolution](./06_networking/network_commands.md#6-dns-lookups)


---

## 🟡 Tier 2 — Intermediate

### Q34 · [Normal] · `umask`

> **What is `umask` and how does it affect new file permissions? If umask is `022`, what permissions does a new file get?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`umask` is a mask that subtracts permissions from the default. With umask `022`, new files get `644` (rw-r--r--) and new directories get `755` (rwxr-xr-x).

**How to think through this:**
1. The system default for new files is `666` (no execute by default); for directories it is `777`
2. umask is subtracted (bitwise AND with the complement): `666 - 022 = 644`, `777 - 022 = 755`
3. To check your current umask: run `umask`. To set it: `umask 027` (no access for others)

**Key takeaway:** umask removes permissions — it never adds them — so a higher umask value means more restrictive files.

</details>

📖 **Theory:** [umask](./04_users_permissions/file_permissions.md#9-umask--default-permissions)


---

### Q35 · [Normal] · `special-permissions`

> **Explain setuid (4), setgid (2), and sticky bit (1). Give a real-world example of each.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These are the three special permission bits that sit above the standard rwx triplet.

**How to think through this:**
1. **Setuid (4)** — when set on an executable, the process runs as the file's owner, not the caller. Example: `/usr/bin/passwd` is owned by root with setuid so any user can change their own password without being root. You see it as an `s` in the owner execute position: `-rwsr-xr-x`
2. **Setgid (2)** — on an executable, the process runs with the file's group. On a directory, new files created inside inherit the directory's group instead of the creator's primary group. Example: a shared project directory where all files should belong to the `devteam` group
3. **Sticky bit (1)** — on a directory, users can only delete files they own, even if they have write permission to the directory. Example: `/tmp` has the sticky bit set so users can't delete each other's temp files. Shown as `t` in the others execute position: `drwxrwxrwt`

**Key takeaway:** Setuid/setgid escalate privilege during execution; sticky bit restricts deletion in shared directories.

</details>

📖 **Theory:** [special-permissions](./04_users_permissions/file_permissions.md#8-special-permissions)


---

### Q36 · [Normal] · `acl-permissions`

> **What are ACLs? How do `getfacl` and `setfacl` extend standard Unix permissions?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
ACLs (Access Control Lists) allow granting permissions to specific users or groups beyond the single owner/group/other model of standard Unix permissions.

**How to think through this:**
1. Standard Unix only allows one owner, one group, and a catch-all "other" — you cannot grant read access to a specific second user without adding them to the group
2. `setfacl -m u:alice:rw /var/data/report.csv` grants Alice read+write without changing ownership or the group
3. `setfacl -m g:auditors:r /var/data/` grants an entire group read access on top of existing permissions
4. `getfacl /var/data/report.csv` shows all ACL entries for the file
5. A `+` at the end of `ls -l` output (e.g., `-rw-r--r--+`) signals that ACLs are present

**Key takeaway:** ACLs are surgical — they let you grant permissions to any specific user or group without restructuring ownership.

</details>

📖 **Theory:** [acl-permissions](./04_users_permissions/file_permissions.md#linux--file-permissions)


---

### Q37 · [Normal] · `process-signals`

> **List the most important Linux signals (SIGHUP, SIGINT, SIGTERM, SIGKILL, SIGSTOP). Which cannot be caught or ignored?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`SIGKILL` (9) and `SIGSTOP` (19) cannot be caught, blocked, or ignored — they are handled directly by the kernel.

**How to think through this:**
1. **SIGHUP (1)** — sent when a terminal closes; many daemons use it as a "reload config" signal
2. **SIGINT (2)** — sent by Ctrl+C; requests interruption; can be caught (think Python's KeyboardInterrupt)
3. **SIGTERM (15)** — the polite shutdown request; can be caught so the process cleans up gracefully
4. **SIGKILL (9)** — instant, unblockable termination; the kernel kills the process directly — no cleanup possible
5. **SIGSTOP (19)** — pauses a process unconditionally; `SIGCONT` resumes it; Ctrl+Z sends the catchable equivalent SIGTSTP

Use `kill -l` to list all signals. `kill -9 PID` force-kills; `kill -15 PID` (or just `kill PID`) asks nicely.

**Key takeaway:** Always try SIGTERM first to give processes a chance to clean up; reserve SIGKILL for when SIGTERM is ignored.

</details>

📖 **Theory:** [process-signals](./05_processes/signals.md#linux--signals)


---

### Q38 · [Normal] · `systemd-basics`

> **What is systemd? What does `systemctl start`, `stop`, `enable`, `disable`, and `status` do?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
systemd is the init system and service manager on most modern Linux distributions — PID 1, responsible for booting the system and managing all services.

**How to think through this:**
1. `systemctl start nginx` — starts the service right now (one-time, does not persist across reboots)
2. `systemctl stop nginx` — stops the running service immediately
3. `systemctl enable nginx` — creates symlinks so the service starts automatically at boot
4. `systemctl disable nginx` — removes those symlinks; service no longer starts at boot
5. `systemctl status nginx` — shows whether the service is active/inactive, the last few log lines, and the PID

Common combos: `systemctl enable --now nginx` starts it immediately and enables it for boot in one command.

**Key takeaway:** `start`/`stop` affect the current session; `enable`/`disable` affect what happens at the next reboot.

</details>

📖 **Theory:** [systemd-basics](./08_system_administration/systemd_services.md#linux--systemd-and-services)


---

### Q39 · [Normal] · `systemd-units`

> **What is a systemd unit file? Write a minimal `.service` unit that runs `/usr/bin/myapp` as user `appuser` and restarts on failure.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A unit file is a plain-text configuration file that tells systemd how to manage a service, mount, socket, timer, or other resource.

**How to think through this:**
1. Unit files live in `/etc/systemd/system/` (admin-managed) or `/lib/systemd/system/` (package-managed)
2. A `.service` file has three sections: `[Unit]` for metadata, `[Service]` for execution details, `[Install]` for boot target
3. Minimal example saved as `/etc/systemd/system/myapp.service`:

```ini
[Unit]
Description=My Application
After=network.target

[Service]
ExecStart=/usr/bin/myapp
User=appuser
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

4. After creating/editing: `systemctl daemon-reload` then `systemctl enable --now myapp`

**Key takeaway:** `Restart=on-failure` is the watchdog — systemd will revive your process automatically without any external monitor.

</details>

📖 **Theory:** [systemd-units](./08_system_administration/systemd_services.md#linux--systemd-and-services)


---

### Q40 · [Normal] · `journalctl`

> **How do you use `journalctl` to view logs for a specific service, filter by time, and follow in real time?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`journalctl` queries the systemd journal — the centralised binary log store that captures stdout/stderr of all services.

**How to think through this:**
1. **Specific service:** `journalctl -u nginx` shows all logs for the nginx unit; `-u` stands for unit
2. **Filter by time:** `journalctl -u nginx --since "2024-01-15 10:00" --until "2024-01-15 11:00"`
3. **Relative time:** `journalctl -u nginx --since "1 hour ago"`
4. **Follow in real time:** `journalctl -u nginx -f` (like `tail -f` but for the journal)
5. **Combine:** `journalctl -u nginx -f --since "5 minutes ago"` — catch up then follow
6. **Boot logs only:** `journalctl -b` for this boot; `journalctl -b -1` for the previous boot

**Key takeaway:** `-u` to scope to a service, `--since`/`--until` to slice time, `-f` to stream — combine all three freely.

</details>

📖 **Theory:** [journalctl](./08_system_administration/logs_and_journalctl.md#linux--logs-and-journalctl)


---

### Q41 · [Normal] · `cron-jobs`

> **What does the cron expression `30 2 * * 1-5` mean? How do `crontab -e` and `/etc/cron.d/` differ?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`30 2 * * 1-5` means "run at 02:30 AM, every weekday (Monday through Friday)."

**How to think through this:**
1. Cron fields left to right: `minute hour day-of-month month day-of-week`
2. Parsing: minute=30, hour=2, day-of-month=any, month=any, day-of-week=1-5 (Mon-Fri)
3. **`crontab -e`** — edits the current user's personal crontab. Jobs run as that user. Stored in `/var/spool/cron/`
4. **`/etc/cron.d/`** — system-level drop-in directory. Each file includes an explicit username field (6 fields total): `30 2 * * 1-5 root /usr/bin/backup.sh`. Useful for packages and configuration management tools like Ansible
5. Other system cron directories: `/etc/cron.daily/`, `/etc/cron.hourly/` (scripts dropped in, no time field needed)

**Key takeaway:** Personal tasks go in `crontab -e`; system/service tasks with explicit user control go in `/etc/cron.d/`.

</details>

📖 **Theory:** [cron-jobs](./08_system_administration/systemd_services.md#7-systemd-timers--modern-cron)


---

### Q42 · [Normal] · `disk-df-du`

> **What is the difference between `df -h` and `du -sh /var`? How do you find which directory is consuming the most space?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`df` reports filesystem-level disk usage (total, used, available per mount); `du` measures actual disk space consumed by a directory tree.

**How to think through this:**
1. `df -h` asks the filesystem: "how full are your mounted partitions?" — fast, one line per mount point
2. `du -sh /var` walks every file under `/var` and sums their sizes — slower but shows where space actually lives
3. To find the biggest offenders under `/var`: `du -sh /var/* | sort -rh | head -10`
4. To drill down recursively: `du -h --max-depth=2 /var | sort -rh | head -20`
5. Why they can differ: deleted files still held open by running processes count in `df` but not in `du`

**Key takeaway:** `df` for "is the disk full?"; `du` for "what is eating the disk?"

</details>

📖 **Theory:** [disk-df-du](./08_system_administration/disk_management.md#should-see-xvdf--20280--0--20g--0-disk)


---

### Q43 · [Normal] · `lsblk-mount`

> **What does `lsblk` show? How do you mount a new disk at `/data` and make it persist after reboot?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`lsblk` lists block devices in a tree — disks, partitions, and their mount points — without needing root.

**How to think through this:**
1. `lsblk` shows device names (`sda`, `sdb`), sizes, types (disk/part/lvm), and current mount points
2. Workflow to add a new disk (e.g., `/dev/sdb`):
   - Partition: `fdisk /dev/sdb` or `parted /dev/sdb`
   - Format: `mkfs.ext4 /dev/sdb1`
   - Create mount point: `mkdir /data`
   - Mount now: `mount /dev/sdb1 /data`
3. To persist across reboots, add to `/etc/fstab`:
   ```
   /dev/sdb1   /data   ext4   defaults   0   2
   ```
4. Better practice — use UUID so device names don't shift: `blkid /dev/sdb1` to get the UUID, then:
   ```
   UUID=abc-123   /data   ext4   defaults   0   2
   ```
5. Test fstab without rebooting: `mount -a`

**Key takeaway:** Mount makes it available now; `/etc/fstab` makes it available forever — always use UUID to avoid device-name drift.

</details>

📖 **Theory:** [lsblk-mount](./08_system_administration/disk_management.md#disk-space-on-all-mounted-filesystems)


---

### Q44 · [Normal] · `inodes`

> **What is an inode? What information does it store? How can a disk be "full" even when `df` shows free space?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
An inode is the metadata record for a file — everything about the file except its name and data. A disk can run out of inodes before running out of data blocks.

**How to think through this:**
1. Each file has exactly one inode storing: permissions, ownership, timestamps (atime/mtime/ctime), file size, link count, and pointers to data blocks — but NOT the filename
2. Filenames live in directory entries that point to inode numbers
3. The filesystem pre-allocates a fixed number of inodes at format time. Check with `df -i`
4. Scenario: a mail spool or tmp directory creates millions of tiny files, exhausting inodes while only using a fraction of data blocks. `df -h` looks fine; `df -i` shows 100% inode usage
5. When inodes are full: "No space left on device" errors even with gigabytes free

**Key takeaway:** Always check both `df -h` (blocks) and `df -i` (inodes) when diagnosing "disk full" errors.

</details>

📖 **Theory:** [inodes](./02_filesystem/links_and_inodes.md#linux--links-and-inodes)


---

### Q45 · [Normal] · `hard-vs-soft-links`

> **What is the difference between a hard link and a symbolic link? When would you choose one over the other?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A hard link is another directory entry pointing to the same inode; a symbolic link is a separate file that stores a path to the target.

**How to think through this:**
1. **Hard link** (`ln original hardlink`): shares the same inode number — same data, same permissions, same everything. Deleting the original leaves the hard link fully intact. Cannot cross filesystem boundaries. Cannot link directories.
2. **Symbolic link** (`ln -s original symlink`): a pointer file containing a path string. If the target is deleted, the symlink breaks ("dangling symlink"). Can cross filesystems. Can point to directories.
3. Check with `ls -li` — hard links share the same inode number; symlinks show `->` and their own inode
4. **Choose hard links** when: you need a resilient backup reference on the same filesystem (e.g., `rsync --link-dest` for incremental backups)
5. **Choose symlinks** when: pointing to directories, crossing filesystems, or creating versioned aliases (e.g., `/usr/bin/python -> python3.11`)

**Key takeaway:** Hard links share identity; symlinks share a path — symlinks are more flexible but fragile if the target moves.

</details>

📖 **Theory:** [hard-vs-soft-links](./02_filesystem/links_and_inodes.md#5-hard-links-vs-symlinks--side-by-side)


---

### Q46 · [Normal] · `tar-compression`

> **What does `tar -czvf archive.tar.gz /etc/nginx` do? How do you extract it? What is the difference between `.tar.gz` and `.tar.bz2`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`tar -czvf archive.tar.gz /etc/nginx` creates a gzip-compressed archive of the `/etc/nginx` directory.

**How to think through this:**
1. Flag breakdown: `-c` create, `-z` compress with gzip, `-v` verbose (list files), `-f archive.tar.gz` output filename
2. `tar` alone just bundles files (no compression); `-z` pipes through gzip, `-j` through bzip2, `-J` through xz
3. **Extract:** `tar -xzvf archive.tar.gz` — swap `-c` (create) for `-x` (extract). Extracts to current directory by default; use `-C /target/dir` to specify destination
4. **`.tar.gz`** (gzip): faster compression/decompression, widely supported, moderate compression ratio
5. **`.tar.bz2`** (bzip2): slower but better compression ratio — good for archives you write once and read rarely
6. Modern alternative: `.tar.xz` gives the best compression ratio at the cost of speed

**Key takeaway:** `tar` bundles, `-z`/`-j`/`-J` compresses — swap `-c` to `-x` to go from archive to extract.

</details>

📖 **Theory:** [tar-compression](./02_filesystem/file_operations.md#include-hidden-files-starting-with)


---

### Q47 · [Normal] · `firewall-ufw`

> **What does `ufw allow 22/tcp`, `ufw deny 3306`, and `ufw default deny incoming` do? How do you enable ufw safely?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These rules set up a firewall that allows SSH, blocks MySQL from outside, and drops all other inbound traffic by default.

**How to think through this:**
1. `ufw default deny incoming` — sets the default policy: drop any incoming connection not explicitly allowed. Set this BEFORE enabling ufw
2. `ufw default allow outgoing` — typically also set so the server can initiate outbound connections freely
3. `ufw allow 22/tcp` — punches a hole for SSH before enabling the firewall (critical — skip this and you lock yourself out)
4. `ufw deny 3306` — explicitly blocks MySQL port on all protocols
5. **Safe enable sequence:** always run in this order:
   ```bash
   ufw default deny incoming
   ufw default allow outgoing
   ufw allow 22/tcp
   ufw enable
   ufw status verbose
   ```
6. `ufw status numbered` shows rules with indexes for easy deletion: `ufw delete 2`

**Key takeaway:** Allow SSH before you enable ufw — there is no warning if you lock yourself out of a remote server.

</details>

📖 **Theory:** [firewall-ufw](./06_networking/firewall.md#3-ufw--uncomplicated-firewall-ubuntu)


---

### Q48 · [Normal] · `iptables-basics`

> **Explain the three main iptables chains: INPUT, OUTPUT, FORWARD. What does `iptables -A INPUT -p tcp --dport 80 -j ACCEPT` do?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The three chains represent the three paths a packet can take through the kernel's network stack.

**How to think through this:**
1. **INPUT** — packets destined for the local system. Controls what external traffic reaches your services
2. **OUTPUT** — packets originating from the local system. Controls outbound connections your system initiates
3. **FORWARD** — packets passing through the system (neither source nor destination). Used when the machine acts as a router or NAT gateway
4. `iptables -A INPUT -p tcp --dport 80 -j ACCEPT`: `-A INPUT` appends a rule to the INPUT chain; `-p tcp` matches TCP protocol; `--dport 80` matches destination port 80; `-j ACCEPT` is the target action (accept the packet)
5. Common targets: `ACCEPT`, `DROP` (silently discard), `REJECT` (discard + send error back), `LOG`
6. Rules are evaluated top to bottom — first match wins. `-A` appends; `-I` inserts at the top

**Key takeaway:** INPUT is for traffic coming in, OUTPUT for traffic going out, FORWARD for traffic passing through — most server hardening focuses on INPUT.

</details>

📖 **Theory:** [iptables-basics](./06_networking/firewall.md#5-iptables--the-low-level-firewall)


---

### Q49 · [Normal] · `network-troubleshooting`

> **A server can't reach `google.com` but `ping 8.8.8.8` works. What is wrong and how do you diagnose it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
DNS resolution is broken. The server can reach IP addresses (routing works) but cannot resolve hostnames to IPs.

**How to think through this:**
1. `ping 8.8.8.8` works → IP routing and internet connectivity are fine
2. `ping google.com` fails → the system cannot resolve `google.com` to an IP
3. Confirm with: `nslookup google.com` or `dig google.com` — if these fail, DNS is the culprit
4. Check configured DNS servers: `cat /etc/resolv.conf` — look for `nameserver` lines
5. Test a specific DNS server directly: `dig @8.8.8.8 google.com` — if this works, your configured nameserver is the problem
6. Check `/etc/nsswitch.conf` to confirm `hosts: files dns` ordering is correct
7. Fix: set a working nameserver in `/etc/resolv.conf` or configure via `systemd-resolved`/`NetworkManager`

**Key takeaway:** IP works but hostname fails always means DNS — `dig` and `cat /etc/resolv.conf` are your first two moves.

</details>

📖 **Theory:** [network-troubleshooting](./06_networking/network_commands.md#linux--network-commands)


---

### Q50 · [Normal] · `tcp-states`

> **What is the difference between a TCP connection in `ESTABLISHED`, `TIME_WAIT`, and `CLOSE_WAIT`? Why does TIME_WAIT exist?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These states represent different phases of the TCP connection lifecycle — active data transfer, graceful local close, and waiting for the remote side to close.

**How to think through this:**
1. **ESTABLISHED** — the connection is open and both sides are actively exchanging data. Normal, healthy state.
2. **TIME_WAIT** — the local side has sent its FIN and received the remote FIN+ACK. It waits for 2×MSL (typically 60 seconds) before fully closing. Purpose: ensures any delayed packets from the old connection don't corrupt a new connection on the same port pair, and guarantees the final ACK was received.
3. **CLOSE_WAIT** — the remote side has sent FIN (it's done), but the local application has not yet called `close()`. This means a bug in your application — it received the close signal but is not acting on it. Accumulating CLOSE_WAIT connections = application leak.
4. Check with: `ss -tan | grep -c TIME_WAIT` or `netstat -tan`

**Key takeaway:** TIME_WAIT is normal and protective; CLOSE_WAIT accumulating means your application is not closing connections properly.

</details>

📖 **Theory:** [tcp-states](./06_networking/network_commands.md#show-all-listening-tcp-ports)


---

### Q51 · [Normal] · `memory-management`

> **What is the difference between RAM used by `free -h` columns: `total`, `used`, `free`, `available`, `buff/cache`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`available` is the only column that tells you how much memory a new process can realistically use — not `free`.

**How to think through this:**
1. **total** — physical RAM installed in the system
2. **used** — memory currently allocated by processes (total minus free minus buff/cache)
3. **free** — memory not used for anything at all — the kernel tries to keep this near zero by using spare RAM as cache
4. **buff/cache** — memory the kernel is using for disk buffers and page cache to speed up I/O. This memory is "in use" but immediately reclaimable if a process needs it
5. **available** — an estimate of how much memory can be given to new processes without swapping: essentially `free + reclaimable buff/cache`. This is the number to watch.
6. A system with `free` near 0 but `available` at 8GB is healthy — the kernel is using spare RAM productively as cache

**Key takeaway:** Ignore `free`; watch `available` — a low `available` value is the real signal that memory pressure is building.

</details>

📖 **Theory:** [memory-management](./05_processes/process_management.md#linux--process-management)


---

### Q52 · [Normal] · `swap-space`

> **What is swap space? When does Linux use it? What is swappiness and why would you lower it on a database server?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Swap is disk space used as overflow when physical RAM is exhausted. Swappiness controls the kernel's eagerness to move memory pages to swap even when RAM is available.

**How to think through this:**
1. Swap is typically a dedicated partition or a swap file. Check with `swapon --show` and `free -h`
2. The kernel moves infrequently-used memory pages to swap (page out) to free RAM for active processes
3. **Swappiness** is a kernel parameter (0–100, default 60). A value of 60 means the kernel will start swapping when RAM is still 40% free, preferring to keep the page cache warm
4. For a database server (e.g., PostgreSQL, MySQL): the database manages its own buffer pool in RAM. If the kernel swaps out database pages to disk, query latency spikes dramatically — you want the DB in RAM at all costs
5. Lower swappiness: `sysctl vm.swappiness=10` (temporarily) or add `vm.swappiness=10` to `/etc/sysctl.conf` (permanently). Value of 1 means "swap only to avoid OOM kill"
6. Setting to 0 does not disable swap — it just makes the kernel extremely reluctant to use it

**Key takeaway:** Low swappiness keeps database buffer pools resident in RAM; without it the kernel may swap out critical data structures, tanking query performance.

</details>

📖 **Theory:** [swap-space](./08_system_administration/disk_management.md#8-swap-space)


---

### Q53 · [Normal] · `load-average`

> **What does `load average: 2.5, 1.8, 1.2` in `top` mean? On a 4-core server, is this load average concerning?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Load average represents the average number of processes in a runnable or uninterruptible state over 1, 5, and 15 minutes. On a 4-core server, `2.5` is not concerning — the CPUs have headroom.

**How to think through this:**
1. The three numbers are 1-minute, 5-minute, and 15-minute averages of the run queue length
2. A load average equal to the number of CPU cores means the cores are 100% utilized with nothing waiting. Below that = underloaded. Above that = queue is building.
3. Rule of thumb: divide load average by CPU count to get per-core load. `2.5 / 4 = 0.625` — only 62.5% utilization at the 1-minute mark
4. The trend matters: `2.5, 1.8, 1.2` is rising (1.2 fifteen minutes ago → 2.5 now). Investigate what is ramping up
5. A flat `3.8, 3.9, 4.0` on a 4-core server means sustained full utilization but no queue — acceptable
6. `8.0, 8.0, 8.0` on a 4-core server means 4 processes always waiting — this needs attention
7. Note: I/O wait (disk) also inflates load average, not just CPU

**Key takeaway:** Normalize load average by CPU count — and watch the trend direction, not just the snapshot value.

</details>

📖 **Theory:** [load-average](./05_processes/process_management.md#current-load-averages)


---

### Q54 · [Normal] · `file-descriptors`

> **What is a file descriptor? What are fd 0, 1, and 2? How do you check open file descriptors for a process?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A file descriptor is an integer handle the kernel gives a process to represent an open resource — file, socket, pipe, or device.

**How to think through this:**
1. Every process gets three standard file descriptors by default:
   - **fd 0** — stdin (standard input)
   - **fd 1** — stdout (standard output)
   - **fd 2** — stderr (standard error)
2. When a process opens a file or socket, the kernel assigns the next available integer (3, 4, 5…)
3. Shell redirection works through FDs: `> file` redirects fd 1; `2>file` redirects fd 2; `2>&1` points fd 2 to wherever fd 1 is going
4. Check open FDs for a process: `ls -la /proc/PID/fd/` — each symlink is an open descriptor
5. `lsof -p PID` gives a human-readable view with file paths and types
6. Check system-wide FD limit: `ulimit -n` (per-process); `cat /proc/sys/fs/file-max` (system-wide)

**Key takeaway:** File descriptors are the universal abstraction — everything the process talks to (files, network sockets, pipes) is a numbered FD.

</details>

📖 **Theory:** [file-descriptors](./03_shell_basics/pipes_and_redirection.md#with-pipe--one-step-no-temp-file)


---

### Q55 · [Normal] · `environment-variables`

> **What is the difference between `export VAR=value` and `VAR=value`? How do you make a variable permanent?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`VAR=value` sets a shell variable visible only in the current shell; `export VAR=value` marks it as an environment variable, making it visible to child processes.

**How to think through this:**
1. Shell variables exist only in the current shell session. Child processes (scripts, programs you run) do not inherit them
2. `export` promotes a variable to the process environment, which child processes inherit via `execve`
3. Verify: `VAR=hello; bash -c 'echo $VAR'` prints nothing. `export VAR=hello; bash -c 'echo $VAR'` prints `hello`
4. **Make permanent** — add to the appropriate shell config file:
   - User-level: `~/.bashrc` (interactive shells) or `~/.bash_profile` (login shells)
   - System-wide: `/etc/environment` (simple KEY=VALUE format, no export needed) or `/etc/profile.d/custom.sh`
5. After editing: `source ~/.bashrc` to apply without restarting the shell

**Key takeaway:** `export` is the difference between "my shell knows this" and "every program I launch knows this."

</details>

📖 **Theory:** [environment-variables](./03_shell_basics/commands.md#linux--essential-shell-commands)


---

### Q56 · [Normal] · `shell-history`

> **How does `.bash_history` work? How do you search history with Ctrl+R? How do you run the last command as sudo?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`.bash_history` is the persistent record of commands, written when the shell exits. Ctrl+R does reverse incremental search through it.

**How to think through this:**
1. `~/.bash_history` stores your command history. Size controlled by `HISTSIZE` (in-memory) and `HISTFILESIZE` (on-disk). Commands are typically written on shell exit, not in real time
2. **Ctrl+R** — opens reverse-i-search. Start typing and bash shows the most recent matching command. Press Ctrl+R again to step further back. Enter to run; Esc or right-arrow to edit first; Ctrl+C to cancel
3. **Run last command as sudo:** `sudo !!` — `!!` expands to the previous command. Most common use: you forget sudo, run a command, get "permission denied", then type `sudo !!`
4. Other useful history expansions: `!ssh` re-runs the most recent command starting with "ssh"; `!$` expands to the last argument of the previous command
5. View history with line numbers: `history | tail -20`. Run by number: `!142`
6. Avoid storing sensitive commands: prefix with a space (if `HISTCONTROL=ignorespace` is set)

**Key takeaway:** `sudo !!` is the most-used history trick in daily Linux work — run last command with root privileges.

</details>

📖 **Theory:** [shell-history](./03_shell_basics/commands.md#linux--essential-shell-commands)


---

### Q57 · [Normal] · `text-processing-pipeline`

> **You have a log file with lines like `2024-01-15 ERROR: connection refused`. Write a pipeline to extract and count unique error types.**

```bash
# Sample log lines:
# 2024-01-15 ERROR: connection refused
# 2024-01-15 ERROR: timeout waiting for response
# 2024-01-16 ERROR: connection refused
# 2024-01-15 INFO: request completed
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
```bash
grep "ERROR:" app.log | awk -F'ERROR: ' '{print $2}' | sort | uniq -c | sort -rn
```

**How to think through this:**
1. `grep "ERROR:"` — filters to only error lines, discarding INFO/WARN etc.
2. `awk -F'ERROR: ' '{print $2}'` — splits each line on `ERROR: ` as the delimiter and prints the second field (the error message)
3. `sort` — groups identical messages together; `uniq -c` requires sorted input to count consecutive duplicates
4. `uniq -c` — counts consecutive identical lines, prepending the count
5. `sort -rn` — sorts numerically (`-n`) in reverse (`-r`) to show highest-count errors first
6. Alternative with `sed`: `grep "ERROR:" app.log | sed 's/.*ERROR: //' | sort | uniq -c | sort -rn`

Output looks like:
```
      2 connection refused
      1 timeout waiting for response
```

**Key takeaway:** The grep → extract → sort → uniq -c → sort -rn pattern is the standard pipeline for frequency analysis of any log file.

</details>

📖 **Theory:** [text-processing-pipeline](./03_shell_basics/text_processing.md#linux--text-processing)


---

### Q58 · [Normal] · `xargs`

> **What does `find /tmp -name "*.log" -mtime +30 | xargs rm` do? Why is `xargs` safer than a subshell here?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
It finds log files in `/tmp` older than 30 days and deletes them. `xargs` batches the arguments into efficient `rm` calls and avoids the "argument list too long" error that subshell expansion can trigger.

**How to think through this:**
1. `find /tmp -name "*.log" -mtime +30` — `-mtime +30` means last modified more than 30 days ago; outputs one file path per line
2. `xargs rm` — reads those paths from stdin and calls `rm` with as many arguments as the OS allows per invocation, batching efficiently
3. **Why not `rm $(find ...)`?** — subshell `$(...)` expands all results into one command line. With thousands of files this hits `ARG_MAX` (the kernel limit on argument length) and fails with "Argument list too long"
4. `xargs` respects `ARG_MAX` automatically, splitting into multiple `rm` calls if needed
5. Handle filenames with spaces: use `find ... -print0 | xargs -0 rm` — null-delimited instead of newline-delimited
6. Dry run first: `find /tmp -name "*.log" -mtime +30 | xargs echo rm` — prints commands without executing

**Key takeaway:** xargs is the safe bridge between `find`'s output and commands that take file arguments — always use `-print0 | xargs -0` when filenames may contain spaces.

</details>

📖 **Theory:** [xargs](./03_shell_basics/text_processing.md#linux--text-processing)


---

### Q59 · [Normal] · `here-documents`

> **What is a heredoc? Write an example using `cat << EOF` to write a multi-line config file.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A heredoc (here-document) is a way to pass a multi-line string to a command inline in a script, without creating a temporary file.

**How to think through this:**
1. Syntax: `command << DELIMITER` — feed lines to `command` until a line containing only `DELIMITER` is encountered
2. `EOF` is conventional but any word works as the delimiter
3. Variables and command substitutions are expanded inside a heredoc by default
4. Use `<< 'EOF'` (quoted delimiter) to treat the body as literal text — no variable expansion

Example writing a config file:
```bash
cat << EOF > /etc/myapp/config.conf
# MyApp configuration
host=localhost
port=8080
log_level=info
data_dir=/var/lib/myapp
user=$(whoami)
EOF
```

5. `<<-EOF` (with a dash) strips leading tabs — useful for indented scripts
6. Heredocs work with any command that reads stdin: `ssh user@host << EOF`, `mysql -u root << EOF`, `python3 << EOF`

**Key takeaway:** Heredocs make scripts self-contained — no separate template files needed for generating configs or running multi-line remote commands.

</details>

📖 **Theory:** [here-documents](./03_shell_basics/pipes_and_redirection.md#6-here-document)


---

### Q60 · [Normal] · `screen-tmux`

> **What is `tmux` and why is it useful for remote SSH sessions? How do you detach and reattach?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`tmux` is a terminal multiplexer — it runs a persistent session on the server that survives SSH disconnections and lets you split one terminal into multiple panes and windows.

**How to think through this:**
1. **The problem it solves:** if your SSH connection drops while a long job is running, the process receives SIGHUP and dies. tmux keeps the session alive on the server regardless of your connection
2. **Start a named session:** `tmux new -s mysession`
3. **Detach** (leave session running on server): `Ctrl+B` then `D` — the prefix key is `Ctrl+B` by default
4. **List sessions:** `tmux ls`
5. **Reattach:** `tmux attach -t mysession` — from any SSH connection, even a different machine
6. **Key operations inside tmux:**
   - Split pane horizontally: `Ctrl+B %`
   - Split pane vertically: `Ctrl+B "`
   - Switch windows: `Ctrl+B n` (next) / `Ctrl+B p` (previous)
   - New window: `Ctrl+B c`
7. `screen` is the older alternative — `screen -S name`, `Ctrl+A D` to detach, `screen -r name` to reattach

**Key takeaway:** Always start tmux before running anything long-running over SSH — losing your connection becomes a minor inconvenience instead of a disaster.

</details>

📖 **Theory:** [screen-tmux](./03_shell_basics/commands.md#linux--essential-shell-commands)


---

### Q61 · [Normal] · `build-from-source`

> **Describe the `./configure && make && make install` workflow. What does each step do?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
This is the classic GNU Autotools build pipeline: probe the system, compile, and install.

**How to think through this:**
1. **`./configure`** — a shell script generated by Autotools that probes your system: checks for required libraries, compiler capabilities, and header files. Produces a `Makefile` tailored to your environment. Common flags: `--prefix=/usr/local` (install location), `--enable-feature`, `--with-library`
2. **`make`** — reads the generated `Makefile` and compiles the source code into binaries. Parallelise with `make -j$(nproc)` to use all CPU cores
3. **`make install`** — copies the compiled binaries, libraries, and man pages to the prefix directory (default `/usr/local`). Needs sudo if installing system-wide
4. To uninstall: `make uninstall` (if the Makefile supports it) or track files with `checkinstall` which creates a proper package
5. Modern projects may use `cmake`, `meson`, or language-specific build systems (`cargo build`, `go build`) but the concept is the same: configure → build → install

**Key takeaway:** `configure` generates the recipe, `make` follows it, `make install` delivers the result — always check `--prefix` so you know where things land.

</details>

📖 **Theory:** [build-from-source](./07_package_management/build_from_source.md#linux--build-from-source)


---

### Q62 · [Normal] · `shared-libraries`

> **What is a shared library (`.so` file)? What does `ldd` do? How does `ldconfig` help?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A shared library is compiled code loaded at runtime by multiple programs simultaneously, saving disk and memory vs. static linking.

**How to think through this:**
1. `.so` = shared object. The Linux equivalent of Windows `.dll`. Example: `libpthread.so.0`, `libssl.so.3`
2. A statically linked binary contains its library code inside the binary itself — large but self-contained. A dynamically linked binary references `.so` files loaded at runtime — smaller binary but depends on libraries being present
3. **`ldd /usr/bin/nginx`** — lists all shared libraries an executable depends on and where the dynamic linker will find each one. "not found" in the output means a missing library will cause the binary to fail
4. **`ldconfig`** — scans standard library directories (`/lib`, `/usr/lib`, directories in `/etc/ld.so.conf`) and rebuilds the dynamic linker cache (`/etc/ld.so.cache`). Run `ldconfig` after installing a new `.so` file so the linker can find it
5. To add a custom library path: add the directory to `/etc/ld.so.conf.d/mylib.conf`, then run `ldconfig`
6. Override at runtime without ldconfig: `LD_LIBRARY_PATH=/custom/lib ./myapp`

**Key takeaway:** `ldd` diagnoses missing library dependencies; `ldconfig` refreshes the linker's map after you add new libraries.

</details>

📖 **Theory:** [shared-libraries](./07_package_management/build_from_source.md#linux--build-from-source)


---

### Q63 · [Normal] · `kernel-modules`

> **What is a kernel module? How do `lsmod`, `modprobe`, and `modinfo` differ?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A kernel module is a piece of kernel code that can be loaded and unloaded at runtime without rebooting — drivers, filesystems, and network protocols are common examples.

**How to think through this:**
1. Modules live in `/lib/modules/$(uname -r)/` as `.ko` (kernel object) files
2. **`lsmod`** — lists currently loaded modules, their size, and how many other modules depend on them. Think `ps` but for kernel modules
3. **`modinfo module_name`** — shows metadata about a module: description, author, version, parameters it accepts, and which kernel it was built for. Does not require the module to be loaded
4. **`modprobe module_name`** — intelligently loads a module along with all its dependencies. Preferred over the lower-level `insmod` which loads a single module without dependency resolution. `modprobe -r module_name` removes it and unused dependencies
5. Common usage: `modprobe br_netfilter` (required for Kubernetes networking), `modprobe overlay` (for container runtimes)
6. Make modules load at boot: add the module name to `/etc/modules-load.d/mymodule.conf`

**Key takeaway:** `lsmod` shows what is loaded, `modinfo` describes it, `modprobe` loads it with dependencies — always prefer modprobe over insmod.

</details>

📖 **Theory:** [kernel-modules](./01_fundamentals/architecture.md#4-layer-2--the-kernel)


---

### Q64 · [Normal] · `sysctl`

> **What is `sysctl` used for? Give 2 examples of kernel parameters you might tune for a high-traffic web server.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`sysctl` reads and writes kernel parameters at runtime via the `/proc/sys/` virtual filesystem, allowing you to tune networking, memory, and security behaviour without rebooting.

**How to think through this:**
1. `sysctl -a` lists all tunable parameters. `sysctl kernel.hostname` reads one. `sysctl -w net.ipv4.ip_forward=1` sets one immediately (not persistent)
2. Make changes persistent: add to `/etc/sysctl.conf` or a file in `/etc/sysctl.d/`, then `sysctl -p` to reload

**Example 1 — Increase the connection backlog:**
```bash
sysctl -w net.core.somaxconn=65535
```
Default is 128. Under high traffic, the kernel queue for incoming connections fills up and new connections are dropped. Raising this prevents connection refusals during traffic spikes.

**Example 2 — Enable TCP time-wait socket reuse:**
```bash
sysctl -w net.ipv4.tcp_tw_reuse=1
```
Allows the kernel to reuse sockets in TIME_WAIT state for new connections. Under heavy load, thousands of TIME_WAIT sockets can exhaust ephemeral ports, blocking new outbound connections.

**Key takeaway:** sysctl is how you push the kernel's network and memory limits beyond safe defaults — always test changes and document them in `/etc/sysctl.d/`.

</details>

📖 **Theory:** [sysctl](./08_system_administration/systemd_services.md#linux--systemd-and-services)


---

### Q65 · [Normal] · `resource-limits`

> **What do `ulimit -n 65536` and `/etc/security/limits.conf` control? Why does this matter for a database?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
These control per-process resource limits — `ulimit -n` sets the maximum number of open file descriptors for the current shell and its children.

**How to think through this:**
1. `ulimit -n 65536` — raises the open file descriptor limit to 65,536 for the current session. Check current limits: `ulimit -a`
2. Two limit types: **soft** (current enforced limit, user can raise up to hard limit) and **hard** (ceiling only root can raise). `ulimit -Sn 65536` sets soft; `ulimit -Hn 65536` sets hard
3. **`/etc/security/limits.conf`** — makes limits persistent for users and services. Format:
   ```
   postgres    soft    nofile    65536
   postgres    hard    nofile    65536
   ```
4. **Why databases care:** PostgreSQL and MySQL open one or more file descriptors per connection, per table, per WAL segment. A busy database with hundreds of connections and thousands of tables can easily hit the default limit of 1024 FDs. When the limit is hit, the database cannot open new connections or files, causing errors and crashes
5. For systemd services, set limits in the unit file: `LimitNOFILE=65536`

**Key takeaway:** Databases need large FD limits because every connection and data file costs a descriptor — the default 1024 limit will cause failures under any real load.

</details>

📖 **Theory:** [resource-limits](./05_processes/process_management.md#linux--process-management)


---

### Q66 · [Normal] · `strace-ltrace`

> **What does `strace -p PID` do? When would you use it vs `lsof -p PID`?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`strace -p PID` attaches to a running process and prints every system call it makes in real time — a live wiretap on the process's conversation with the kernel.

**How to think through this:**
1. **`strace -p PID`** — shows system calls as they happen: file opens, network sends, memory allocations, signal handling. Use it when a process is misbehaving and you need to see exactly what it is trying to do at the kernel level. Common flags: `-e trace=file` (only file-related calls), `-e trace=network` (only network), `-o output.txt` (write to file), `-f` (follow forks/threads)
2. **`lsof -p PID`** — lists what the process currently has open: files, sockets, pipes, devices. It is a static snapshot, not a live trace
3. **When to use strace:** a process is hanging — `strace` shows it stuck in a `read()` or `futex()` call; a process fails silently — `strace` shows the failing `open()` with "No such file or directory"; performance investigation — see which syscalls are taking time
4. **When to use lsof:** you want to know which files or network connections a process has open right now; diagnose "file in use" or "port already bound" errors; inventory what a daemon is holding
5. `ltrace` is the library call equivalent — traces calls to shared libraries (e.g., `malloc`, `fopen`) rather than raw syscalls

**Key takeaway:** `strace` shows what a process is doing moment to moment; `lsof` shows what it currently holds open — strace diagnoses behaviour, lsof diagnoses state.

</details>

📖 **Theory:** [strace-ltrace](./05_processes/process_management.md#linux--process-management)


---

## 🟠 Tier 3 — Advanced

### Q67 · [Thinking] · `performance-profiling`

> **A server has high CPU usage. Walk through the tools you'd use (top, htop, perf, vmstat) to identify the culprit process.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Start broad with system-level tools, then narrow to the specific process.

**How to think through this:**
1. Run `top` or `htop` — sort by CPU (`P` key in top). Identify the PID and process name consuming the most CPU.
2. Use `vmstat 1 5` — check if the CPU is spending time in user space (`us`), kernel/system (`sy`), or waiting on I/O (`wa`). High `wa` means disk is the real bottleneck, not CPU.
3. Use `pidstat -u 1 5` — shows per-process CPU over time, confirms whether usage is steady or bursty.
4. Use `perf top` or `perf record -p <PID> && perf report` — drops into the call stack of the process, showing which functions are burning cycles. This identifies whether it's a hot loop in application code, a library, or a kernel syscall.
5. Use `strace -p <PID>` — if perf is unavailable, strace shows which syscalls the process is making. A flood of repeated syscalls is a red flag.

**Key takeaway:** Work top-down — system view first, process view second, function-level last.

</details>

📖 **Theory:** [performance-profiling](./05_processes/process_management.md#linux--process-management)


---

### Q68 · [Thinking] · `disk-io-troubleshooting`

> **How do iostat, iotop, and dstat help diagnose disk I/O bottlenecks?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Each tool answers a different question about the same I/O problem.

**How to think through this:**
1. `iostat -xz 1` — shows per-device utilization (`%util`), throughput (`MB/s`), IOPS (`r/s`, `w/s`), and latency (`await` = average milliseconds per request). A device at 100% `%util` with high `await` is saturated.
2. `iotop` — like `top` but for disk. Shows which process is generating the I/O, how many KB/s it is reading and writing. Lets you pinpoint the culprit application.
3. `dstat` — an all-in-one view combining CPU, memory, disk, and network in one terminal. Useful for spotting correlations — e.g., disk writes spike exactly when CPU spikes, suggesting a logging or write-heavy workload.

**How to use them together:** `iostat` tells you the disk is the problem, `iotop` tells you which process is causing it, `dstat` shows whether it correlates with other system events.

**Key takeaway:** `iostat` → device health, `iotop` → process blame, `dstat` → system-wide correlation.

</details>

📖 **Theory:** [disk-io-troubleshooting](./08_system_administration/disk_management.md#4-listing-disks-and-partitions)


---

### Q69 · [Thinking] · `network-performance`

> **What is iperf3 used for? What does ss -s show about TCP connections?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`iperf3` measures raw network throughput between two hosts. `ss -s` summarizes TCP connection state counts.

**How to think through this:**
1. `iperf3` runs in client/server mode. Start `iperf3 -s` on the target, then `iperf3 -c <server-ip>` on the source. It reports bandwidth in Mbits/sec, showing the maximum throughput the network path can sustain. Useful for testing whether a network bottleneck is real or perceived.
2. `ss -s` prints a summary: total sockets, TCP sockets broken down by state (ESTABLISHED, TIME-WAIT, CLOSE-WAIT, SYN-RECV, etc.). A large number of TIME-WAIT sockets is normal after many short-lived connections. A growing CLOSE-WAIT count means the application is not closing sockets properly. A spike in SYN-RECV can indicate a SYN flood attack.
3. `ss -tnp` lists individual connections with the owning process — useful when you want to see which application owns a specific port or connection.

**Key takeaway:** `iperf3` measures the pipe's capacity; `ss -s` shows the health of connections using that pipe.

</details>

📖 **Theory:** [network-performance](./06_networking/network_commands.md#linux--network-commands)


---

### Q70 · [Thinking] · `log-rotation`

> **What is logrotate? Write a config that rotates /var/log/myapp.log daily, keeps 14 days, and compresses old logs.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`logrotate` is a system utility that automatically rotates, compresses, and removes log files on a schedule to prevent them from filling the disk.

**How to think through this:**
1. Logrotate reads config files in `/etc/logrotate.d/`. Each file defines rules for one or more log paths.
2. The key directives: `daily` sets the rotation frequency, `rotate 14` keeps 14 old copies, `compress` gzips old files, `delaycompress` skips compressing the most recent rotated file (so the application can still write to it briefly), `missingok` suppresses errors if the log is absent, `notifempty` skips rotation if the file is empty, `postrotate` runs a command after rotation (e.g., to signal the app to reopen its log handle).

```
/var/log/myapp.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        systemctl kill -s HUP myapp.service
    endscript
}
```

3. Test with `logrotate -d /etc/logrotate.d/myapp` (dry run) before enabling.

**Key takeaway:** `logrotate` manages log lifecycle automatically; `postrotate` ensures the app reopens its file handle after rotation.

</details>

📖 **Theory:** [log-rotation](./08_system_administration/logs_and_journalctl.md#6-log-rotation--keeping-logs-from-filling-your-disk)


---

### Q71 · [Thinking] · `cgroups`

> **What are cgroups? How do they relate to Docker container resource limits?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
cgroups (control groups) are a Linux kernel feature that lets you allocate and limit resources — CPU, memory, disk I/O, network — for groups of processes.

**How to think through this:**
1. Think of cgroups as a budget system. You create a cgroup, assign processes to it, and set limits. The kernel enforces those limits and tracks usage per group.
2. Key resource controllers: `cpu` (CPU time shares and quotas), `memory` (RAM limits, OOM behaviour), `blkio` (disk I/O throttling), `net_cls` (network packet tagging).
3. Docker uses cgroups directly under the hood. When you run `docker run --memory=512m --cpus=1.5`, Docker creates a cgroup for that container and writes those limits into `/sys/fs/cgroup/`. The kernel enforces them transparently.
4. cgroups v1 vs v2: Most modern distributions use cgroups v2 (unified hierarchy), which Docker and Kubernetes support. The cgroup tree is at `/sys/fs/cgroup/`.

**Key takeaway:** cgroups are the kernel primitive that makes container resource limits possible — Docker is a user-friendly API on top of them.

</details>

📖 **Theory:** [cgroups](./05_processes/process_management.md#linux--process-management)


---

### Q72 · [Thinking] · `namespaces`

> **What are Linux namespaces? Name 6 types and explain how they enable container isolation.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Linux namespaces wrap a global system resource so that processes inside the namespace see their own isolated instance of it.

**How to think through this:**
1. Think of namespaces as a magic mirror — each container looks at the mirror and sees its own world, even though the same kernel is running everything.
2. The six core namespace types:
   - **PID namespace** — processes inside have their own PID numbering starting at 1. Container PID 1 maps to a different kernel PID. Processes cannot see processes in other namespaces.
   - **Network namespace** — each namespace has its own network interfaces, routing tables, and iptables rules. This is why each container gets its own `eth0`.
   - **Mount namespace** — isolated filesystem mount table. A container can mount/unmount without affecting the host.
   - **UTS namespace** — isolated hostname and domain name. Each container can have its own `hostname`.
   - **IPC namespace** — isolated inter-process communication (shared memory, semaphores). Prevents containers from signalling each other via IPC.
   - **User namespace** — maps container UIDs/GIDs to different host UIDs/GIDs. Allows a container to think it is running as root while actually mapping to an unprivileged host user.
3. Docker creates all six namespaces per container using `clone()` and `unshare()` syscalls.

**Key takeaway:** Each namespace type isolates one dimension of the OS; together they create the illusion of a separate machine.

</details>

📖 **Theory:** [namespaces](./05_processes/process_management.md#linux--process-management)


---

### Q73 · [Thinking] · `security-hardening`

> **Name 5 steps to harden a fresh Linux server before putting it in production.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Security hardening reduces the attack surface of a server before it is exposed to the network or workloads.

**How to think through this:**
1. **Disable root SSH login and use key-based authentication only** — set `PermitRootLogin no` and `PasswordAuthentication no` in `/etc/ssh/sshd_config`. This eliminates brute-force password attacks against root.
2. **Apply all OS updates and enable automatic security patches** — `apt upgrade` / `yum update` immediately. Unpatched CVEs are the most common initial access vector.
3. **Configure a firewall (ufw or iptables/nftables)** — default DENY all inbound, then explicitly allow only the ports the service needs (e.g., 22, 443). This limits blast radius if a service is compromised.
4. **Remove or disable unused services** — `systemctl disable` and `stop` anything not needed. Every running service is an attack surface. Check with `systemctl list-units --type=service --state=running`.
5. **Set up fail2ban or equivalent** — automatically bans IPs that fail SSH authentication repeatedly, blocking automated scanning tools.

Bonus steps: enable SELinux/AppArmor, audit with `lynis audit system`, rotate SSH host keys, configure NTP, and set up centralised logging.

**Key takeaway:** Hardening is about reducing every unnecessary entry point before the first workload runs.

</details>

📖 **Theory:** [security-hardening](./04_users_permissions/sudo_and_root.md#9-disabling-root-login-security-best-practice)


---

### Q74 · [Thinking] · `selinux-apparmor`

> **What is SELinux? What is the difference between enforcing, permissive, and disabled modes?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
SELinux (Security-Enhanced Linux) is a mandatory access control (MAC) system built into the Linux kernel. It enforces policies that define exactly which processes can access which files, ports, and other resources — beyond what standard Unix permissions allow.

**How to think through this:**
1. Standard Unix permissions are discretionary — the file owner decides. SELinux is mandatory — a central policy decides, and even root is constrained.
2. Every process and file gets a **security context** (a label like `system_u:object_r:httpd_t:s0`). The policy defines which labels can interact with which.
3. The three modes:
   - **Enforcing** — policy is active and violations are blocked and logged. This is the production state.
   - **Permissive** — policy is active but violations are only logged, not blocked. Used for troubleshooting or policy development. The system behaves as if SELinux is off but you get audit logs to see what would have been denied.
   - **Disabled** — SELinux is completely off, no logging, no enforcement. Switching from disabled to enforcing requires a filesystem relabel on reboot.
4. Check current mode: `getenforce`. Change temporarily: `setenforce 0` (permissive) or `setenforce 1` (enforcing). Persist in `/etc/selinux/config`.
5. Most container-related SELinux denials are fixed with `chcon` or `restorecon` to relabel files.

**Key takeaway:** Permissive mode is your debugging tool — it shows what SELinux would block without breaking anything.

</details>

📖 **Theory:** [selinux-apparmor](./04_users_permissions/sudo_and_root.md#linux--sudo-and-root)


---

### Q75 · [Thinking] · `ssh-hardening`

> **What are 5 SSH security best practices you should configure in /etc/ssh/sshd_config?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
SSH is the most common entry point into a Linux server — hardening it is non-negotiable before exposing a server to the internet.

**How to think through this:**
1. **`PermitRootLogin no`** — never allow direct root login over SSH. Use a regular user and `sudo`. If root is compromised remotely, the game is over.
2. **`PasswordAuthentication no`** — enforce SSH key pairs only. Passwords are vulnerable to brute force; private keys are not.
3. **`Port 2222`** (or another non-standard port) — changes the default port from 22. Not true security, but eliminates 99% of automated scanners that only target port 22.
4. **`AllowUsers alice bob`** or **`AllowGroups sshusers`** — explicitly whitelist which users or groups can log in via SSH. Prevents compromised service accounts from being used as SSH entry points.
5. **`MaxAuthTries 3`** and **`LoginGraceTime 30`** — limit the number of authentication attempts per connection and reduce the window for a connection to authenticate. Slow down brute-force attempts that do reach your port.

After any change: `sshd -t` to validate config, then `systemctl reload sshd`.

**Key takeaway:** SSH hardening is layered — each setting removes one attack vector, and together they make the surface nearly impenetrable.

</details>

📖 **Theory:** [ssh-hardening](./06_networking/ssh.md#linux--ssh)


---

## 🔵 Tier 4 — Interview / Scenario

### Q76 · [Interview] · `explain-permissions-junior`

> **A junior developer asks why their script won't run with "permission denied". Walk them through diagnosing and fixing it.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
"Permission denied" on a script almost always means the execute bit is missing — the file exists and is readable, but the OS won't run it as a program.

**How to think through this:**
1. First, reproduce the exact error context. Ask: how are they running it? `./script.sh`? `bash script.sh`? Running with `bash` explicitly bypasses the execute bit entirely — the shell reads the file as text. Running with `./` requires the execute bit.
2. Show them `ls -la script.sh`. Walk them through the permission string. If it shows `-rw-r--r--`, there is no `x` anywhere.
3. Explain the three permission groups: owner (`u`), group (`g`), others (`o`). Ask: who is running the script? If it is the file owner, only the owner's `x` bit matters.
4. Fix with `chmod u+x script.sh` (add execute for the owner only) or `chmod 755 script.sh` (owner can read/write/execute, group and others can read/execute).
5. Second common cause: wrong shebang line. If the first line is `#!/usr/bin/python3` but Python 3 is at `/usr/bin/python`, the script will fail with "no such file or directory" disguised as a permission-style error. Check with `head -1 script.sh` and `which python3`.
6. Third cause: the script is on a filesystem mounted with `noexec`. Check `mount | grep noexec`. Common on `/tmp` partitions.

**Key takeaway:** Always check `ls -la` first — the permission string tells the whole story.

</details>

📖 **Theory:** [explain-permissions-junior](./04_users_permissions/file_permissions.md#linux--file-permissions)


---

### Q77 · [Interview] · `compare-processes-threads`

> **Explain the difference between processes and threads. What is a zombie process?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A process is an isolated program with its own memory space; threads are execution units within a process that share that memory.

**How to think through this:**
1. Think of a process as a house — it has its own walls (memory space), front door (file descriptors), and address. Each process is independent. If one crashes, others are unaffected.
2. Threads are people living inside the house. They share the same space (heap, file descriptors, code) but each has their own stack and program counter. Communication between threads is fast (shared memory) but dangerous (race conditions). Communication between processes requires IPC (pipes, sockets, shared memory segments).
3. Creating a process (`fork()`) is expensive — the kernel copies the entire address space. Creating a thread is cheap — it shares the parent's memory. This is why web servers use thread pools rather than forking a new process per request.
4. A **zombie process** is a process that has finished executing but whose entry remains in the process table because its parent has not yet called `wait()` to collect its exit status. The child is dead but its record is not cleaned up. Zombies appear as `Z` state in `ps aux`. They consume no CPU or memory, only a PID slot.
5. Zombies are cleaned up when the parent calls `wait()`, or when the parent itself exits (init/systemd adopts and reaps orphans automatically).

**Key takeaway:** Zombies are not a resource problem by themselves — they signal a bug in the parent process's signal handling.

</details>

📖 **Theory:** [compare-processes-threads](./05_processes/process_management.md#3-viewing-processes)


---

### Q78 · [Interview] · `explain-boot-process`

> **Describe the Linux boot process from power-on to login prompt. Name each stage.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The Linux boot process has six distinct stages, each handing off control to the next.

**How to think through this:**
1. **BIOS/UEFI** — firmware runs first. Does a Power-On Self Test (POST), identifies boot devices, loads the bootloader from the MBR (BIOS) or EFI partition (UEFI).
2. **Bootloader (GRUB2)** — loads the kernel image (`vmlinuz`) and the initial RAM disk (`initrd`/`initramfs`) into memory. Shows the boot menu if multiple kernels are installed.
3. **Kernel initialisation** — the kernel decompresses itself, initialises hardware (CPU, memory, drivers), mounts the `initramfs` as a temporary root filesystem to load drivers needed to access the real root disk.
4. **initramfs** — a minimal in-memory filesystem. Loads storage drivers, decrypts LUKS volumes if needed, finds the real root partition, and pivots root to it.
5. **init / systemd (PID 1)** — the first real process. systemd reads its unit files, resolves dependencies, and starts services in parallel according to the target (e.g., `multi-user.target` or `graphical.target`).
6. **Login prompt** — once the target is reached, `getty` starts on TTYs and/or a display manager starts for graphical login.

**Key takeaway:** Each stage exists to prepare the environment for the next — hardware → kernel → filesystem → services → user.

</details>

📖 **Theory:** [explain-boot-process](./01_fundamentals/architecture.md#7-what-happens-when-you-boot-linux)


---

### Q79 · [Interview] · `compare-hard-soft-links`

> **Compare hard links and symbolic links. Why can you not hard-link across filesystems?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Hard links and symbolic links both create alternative names for files, but they work at fundamentally different levels.

**How to think through this:**
1. Every file on a Linux filesystem has an **inode** — a data structure holding metadata (permissions, timestamps, data block pointers) identified by a number. A filename is just a directory entry that points to an inode number.
2. A **hard link** creates a second directory entry pointing to the same inode. There is no "original" — both names are equal. The inode's link count increments. The data is only deleted when the link count drops to zero (all names removed).
3. A **symbolic (soft) link** is a separate file whose content is a path string pointing to another file. It is like a shortcut. If the target is deleted, the symlink becomes dangling (broken). It has its own inode.
4. **Why no hard links across filesystems:** inode numbers are only unique within a single filesystem. A hard link in `/home` pointing to inode 12345 has no meaning on `/data`, which has its own inode 12345 for a completely different file. The kernel cannot create a cross-filesystem hard link because there is no shared inode namespace.
5. Symbolic links work across filesystems because they store a path string, not an inode number. The path is resolved at access time.

**Key takeaway:** Hard links are aliases to the same inode; symlinks are pointers to a path — the inode boundary explains the cross-filesystem restriction.

</details>

📖 **Theory:** [compare-hard-soft-links](./02_filesystem/links_and_inodes.md#3-hard-links)


---

### Q80 · [Interview] · `explain-file-descriptors`

> **Explain file descriptors. Why does a web server need ulimit -n 65536?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A file descriptor (FD) is a non-negative integer that the kernel assigns to an open resource — a file, socket, pipe, or device. It is the process's handle to that resource.

**How to think through this:**
1. When a process opens a file or accepts a network connection, the kernel creates an entry in the process's file descriptor table and returns the next available integer. By convention, 0 = stdin, 1 = stdout, 2 = stderr. Application FDs start at 3.
2. Every active TCP connection on a web server is an open socket, which occupies one file descriptor per connection.
3. `ulimit -n` controls the maximum number of open file descriptors per process. The default is typically 1024.
4. A web server handling 10,000 concurrent connections needs at least 10,000 FDs — plus FDs for open log files, config files, SSL contexts, and internal pipes. 1024 would cause "too many open files" errors and connection refusals well before the server is truly overloaded.
5. Setting `ulimit -n 65536` (or higher) gives the server room to handle high concurrency. For systemd services this is set with `LimitNOFILE=65536` in the unit file. System-wide limits are in `/etc/security/limits.conf`.

**Key takeaway:** Each open connection is an open file descriptor — the ulimit is the ceiling on how many the OS will allow the process to hold at once.

</details>

📖 **Theory:** [explain-file-descriptors](./03_shell_basics/pipes_and_redirection.md#with-pipe--one-step-no-temp-file)


---

### Q81 · [Design] · `scenario-disk-full`

> **Your production server disk is 100% full. Walk through how you diagnose and recover without downtime.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A full disk stops writes, which can crash databases, break logging, and prevent new connections. Speed matters, but so does not deleting the wrong thing.

**How to think through this:**
1. **Confirm and locate** — `df -h` to see which filesystem is full. `du -sh /* 2>/dev/null | sort -rh | head -20` to identify the top consumers. Narrow down: `du -sh /var/log/* | sort -rh` if `/var` is the culprit.
2. **Quick wins first** — clear package manager caches (`apt clean` / `yum clean all`), remove old kernel packages (`apt autoremove`), check for core dump files in `/var/crash` or `/tmp`.
3. **Log files** — if logs are the culprit, do NOT just `rm` a log file that a running process has open. The FD stays open; the disk space is not freed until the process closes it. Instead: `> /var/log/bigfile.log` (truncate in place) or `logrotate --force`. Then check logrotate config to prevent recurrence.
4. **Find deleted-but-open files** — `lsof | grep deleted | awk '{print $7, $9}' | sort -rn` — this finds files that are deleted but still held open by processes, consuming space the kernel cannot reclaim yet. Restarting the process frees the space.
5. **Create breathing room** — if nothing is obviously safe to delete, temporarily move large files to another filesystem or S3, then address root cause (logrotate misconfiguration, runaway log writer, missing cleanup job).
6. **Prevent recurrence** — set up disk usage alerting at 75% and 90% thresholds.

**Key takeaway:** Check for deleted-but-open files — this is the most common "ghost disk usage" trap in production.

</details>

📖 **Theory:** [scenario-disk-full](./08_system_administration/disk_management.md#9-emergency-disk-full--what-to-do)


---

### Q82 · [Design] · `scenario-ssh-locked-out`

> **You accidentally ran `iptables -F` and `iptables -P INPUT DROP` on a remote server. You are now locked out. What options do you have?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
`iptables -F` flushed all rules and `iptables -P INPUT DROP` set the default policy to drop everything inbound — including SSH. Recovery depends on what access methods are available.

**How to think through this:**
1. **Cloud console / out-of-band access** — on AWS, use EC2 Instance Connect or Systems Manager (SSM) Session Manager. On GCP, use the serial console. On bare metal, use IPMI/iDRAC/iLO. These connect through a side channel that bypasses the OS network stack entirely.
2. **AWS SSM (if agent is running)** — `aws ssm start-session --target <instance-id>`. SSM communicates over HTTPS outbound from the agent, so the INPUT DROP rule does not block it if the agent was already connected when you ran the command.
3. **Rescue mode / reboot** — some cloud providers let you attach the instance's disk to a rescue instance, mount it, and edit `/etc/iptables/rules.v4` or `/etc/sysconfig/iptables` to remove the DROP rule. Then reattach and boot normally.
4. **Prevention** — never run iptables changes directly on a live remote session without a safety net. The standard pattern is: schedule an `at` job to flush rules in 5 minutes (`echo "iptables -F && iptables -P INPUT ACCEPT" | at now + 5 minutes`), make your change, test it, then cancel the job if it works. If you get locked out, the job rescues you.

**Key takeaway:** Always set a timed rollback job before applying firewall changes to a remote server you cannot physically reach.

</details>

📖 **Theory:** [scenario-ssh-locked-out](./06_networking/ssh.md#now-all-ssh-connections-use-the-loaded-key-without-prompting)


---

### Q83 · [Design] · `scenario-process-killed`

> **A critical process keeps getting killed. dmesg shows OOM killer messages. What happened and how do you prevent it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The OOM (Out-Of-Memory) killer is a kernel mechanism of last resort — when physical RAM and swap are exhausted, it kills a process to prevent total system freeze.

**How to think through this:**
1. **Understand what happened** — the kernel scores all processes by memory usage, runtime, and oom_adj score. The process with the highest "badness" score gets killed. `dmesg | grep -i oom` shows which process was killed, how much memory was in use, and what the memory state looked like.
2. **Find the root cause** — was it a memory leak? Run `ps aux --sort=-%mem` over time to see if the process's RSS was growing. Was it a sudden spike? Check application logs for a large batch job, a traffic burst, or a misconfigured cache.
3. **Immediate remedies:**
   - Add swap if there is none: `fallocate -l 4G /swapfile && mkswap /swapfile && swapon /swapfile`. Swap is slow but gives the OOM killer more room before acting.
   - Set `vm.overcommit_memory = 2` in `/etc/sysctl.conf` to prevent the kernel from allocating more memory than physically exists.
4. **Protect the critical process** — set `oom_score_adj` to -1000 to make the kernel almost never kill it: `echo -1000 > /proc/<PID>/oom_score_adj`. For systemd services: `OOMScoreAdjust=-1000` in the unit file.
5. **Long-term fix** — address the root cause: fix memory leaks, add more RAM, set memory limits on less critical services with cgroups so they get killed first.

**Key takeaway:** OOM killing is a symptom — either a process has a memory leak, or the server is genuinely undersized for its workload.

</details>

📖 **Theory:** [scenario-process-killed](./05_processes/process_management.md#linux--process-management)


---

### Q84 · [Design] · `scenario-high-load`

> **A server's load average spikes to 50 on an 8-core machine. Walk through your triage process.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A load average of 50 on an 8-core machine means there are roughly 50 processes competing for CPU or waiting for I/O at any given moment — 6x overloaded. Triage means finding the bottleneck type first.

**How to think through this:**
1. **Check load type** — `vmstat 1 5`. Look at the columns: `r` (runnable, CPU-bound) vs `b` (blocked, waiting for I/O). If `b` is high and `wa` (I/O wait) is high, the bottleneck is disk or network I/O, not CPU. If `r` is high and `us`+`sy` are high, it is CPU-bound.
2. **If CPU-bound** — `top` or `htop` sorted by CPU. Identify the top processes. Are they all the same process (single runaway job) or many processes (poorly configured job scheduler launching too many workers)?
3. **If I/O-bound** — `iostat -xz 1` to identify which disk. `iotop` to identify which process. Common culprits: a backup job, a database doing a full table scan, a runaway log writer.
4. **Check for fork bombs or runaway spawning** — `ps aux | wc -l` to count total processes. `ps aux --sort=-%cpu | head -20` to find repeat offenders.
5. **Immediate relief** — `nice -n 19 <PID>` to deprioritize a non-critical process, `ionice -c 3 -p <PID>` to deprioritize its I/O, or `kill` if it is truly runaway.
6. **Post-incident** — add monitoring (load average alerts), add cgroup CPU limits to non-critical services, consider horizontal scaling.

**Key takeaway:** Load average alone does not tell you the bottleneck type — `vmstat` splits it into CPU vs I/O immediately.

</details>

📖 **Theory:** [scenario-high-load](./05_processes/process_management.md#start-with-higher-priority-requires-root-for-negative-values)


---

### Q85 · [Design] · `scenario-cron-not-running`

> **A cron job that was running daily has silently stopped. Walk through how you diagnose why.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Silent cron failures are common because cron swallows stdout/stderr by default unless mail is configured or output is explicitly redirected.

**How to think through this:**
1. **Verify the crontab is still there** — `crontab -l` as the correct user. Check `/etc/cron.d/` and `/etc/crontab` for system-level jobs. Confirm the schedule syntax is correct using `crontab.guru`.
2. **Check cron daemon logs** — `grep CRON /var/log/syslog` (Debian/Ubuntu) or `grep crond /var/log/cron` (RHEL/CentOS). This shows whether cron is even attempting to run the job. Look for lines like `(user) CMD (command)`.
3. **If cron runs the job but it fails silently** — the most common cause is environment. Cron runs with a minimal `PATH` (usually `/usr/bin:/bin`). A script that works manually relies on your full shell `PATH`. Fix: add `PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin` at the top of the crontab, or use absolute paths in the script.
4. **Redirect output in the crontab entry** — change `0 2 * * * /path/to/script.sh` to `0 2 * * * /path/to/script.sh >> /var/log/myjob.log 2>&1`. Now you have a log to inspect.
5. **Check if the script itself fails** — run it manually as the cron user: `sudo -u cronuser /path/to/script.sh`. Check for missing dependencies, changed file paths, or expired credentials.
6. **Check if the cron daemon is running** — `systemctl status cron` or `systemctl status crond`.

**Key takeaway:** The most common cause is a PATH or environment difference between the user's shell session and the cron execution environment.

</details>

📖 **Theory:** [scenario-cron-not-running](./08_system_administration/systemd_services.md#try-reload-fall-back-to-restart-if-reload-not-supported)


---

### Q86 · [Interview] · `compare-sysv-systemd`

> **Compare SysV init vs systemd. Why did the industry move to systemd?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
SysV init is the traditional sequential init system; systemd is the modern parallel, dependency-aware init system that has replaced it on virtually all major distributions.

**How to think through this:**
1. **SysV init** — starts services by executing shell scripts in `/etc/init.d/` one at a time in numeric order (S01network, S02syslog, etc.). Simple to understand, but slow because it is strictly sequential. No way to express "start service B only after service A is ready" beyond ordering numbers. No built-in service supervision — if a service crashes, it stays dead.
2. **systemd** — represents services as declarative unit files. Resolves a dependency graph (`After=`, `Requires=`, `Wants=`) and starts services in parallel wherever possible. Dramatically faster boot times on multi-core systems.
3. **Key systemd advantages:**
   - Parallel startup — independent services start simultaneously
   - `journald` — structured binary logging with `journalctl` for rich filtering
   - Socket activation — services can be started on first connection, not at boot
   - `cgroup` integration — each service gets its own cgroup for resource tracking and clean shutdown
   - Built-in watchdog and restart policies (`Restart=on-failure`)
   - Dependency management — `systemctl list-dependencies` shows the full graph
4. **The controversy** — systemd replaced many small Unix tools (syslog, cron, network config) with a monolithic suite. Critics argue this violates Unix philosophy. Supporters argue it solves real operational problems.

**Key takeaway:** systemd won because parallel startup, dependency tracking, and built-in service supervision solve real production reliability problems that SysV init could not address elegantly.

</details>

📖 **Theory:** [compare-sysv-systemd](./08_system_administration/systemd_services.md#linux--systemd-and-services)


---

### Q87 · [Interview] · `compare-hard-links-vs-copy`

> **When does a hard link save space vs creating a copy? When would a hard link cause unexpected behaviour?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Hard links save space whenever two references to the same data exist in the same filesystem — but they create surprising coupling between the two names.

**How to think through this:**
1. **Space saving** — a hard link adds only a directory entry (a few bytes), while `cp` duplicates all data blocks. If you have a 1 GB file referenced by 10 hard links, the disk stores 1 GB, not 10 GB. `ls -l` shows the link count, and `du` without `--count-links` may report inflated sizes for hard-linked trees.
2. **Where it saves space in practice** — backup tools like `rsync --link-dest` and `borgbackup` use hard links to create multiple "full" backup snapshots that share unchanged files, using only the delta in actual disk space.
3. **When hard links cause unexpected behaviour:**
   - **Edit-in-place** — if you edit a hard-linked file with an editor that modifies in place (like `sed -i`), both names see the change. If the editor creates a new file and renames it (copy-on-write style, like vim's default), the hard link is broken and only the old name points to the old data. Surprising when you think you edited "one" file.
   - **`chmod` or `chown` affects all names** — since both names point to the same inode, changing permissions via one name changes them for all.
   - **`rm` does not delete data** — removing one hard link just decrements the link count. The data persists until the last name is removed. This is intentional but surprises people who expect `rm` to always free space.
4. **Diagnostic** — `stat file` shows the inode number and link count. Files with the same inode number are hard links to each other.

**Key takeaway:** Hard links share an inode completely — changes to metadata and in-place writes are visible through all names, which is powerful but easy to misuse.

</details>

📖 **Theory:** [compare-hard-links-vs-copy](./02_filesystem/links_and_inodes.md#5-hard-links-vs-symlinks--side-by-side)


---

### Q88 · [Design] · `scenario-log-analysis`

> **You have a 50 GB nginx access log. Write a command pipeline to find the top 10 IPs by request count without loading the whole file into memory.**

```bash
# Stream the file, extract IPs, count occurrences, sort descending, show top 10
awk '{print $1}' /var/log/nginx/access.log \
  | sort --parallel=4 -S 2G \
  | uniq -c \
  | sort -rn \
  | head -10

# Alternative using cut (faster for fixed-delimiter logs)
cut -d' ' -f1 /var/log/nginx/access.log \
  | sort -S 2G \
  | uniq -c \
  | sort -rn \
  | head -10
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Use a streaming pipeline — each tool processes one line at a time, so memory usage stays constant regardless of file size.

**How to think through this:**
1. `awk '{print $1}'` (or `cut -d' ' -f1`) — extracts the first field (the client IP) from each line of the nginx combined log format. This reduces the data volume dramatically before any sorting.
2. `sort` — `uniq -c` requires adjacent duplicates, so we must sort first. The `-S 2G` flag gives sort a 2 GB sort buffer, letting it sort in-memory in chunks rather than spilling excessively to disk. `--parallel=4` uses multiple CPU cores. For a 50 GB file, sort will still use temp files but handles this gracefully.
3. `uniq -c` — collapses sorted duplicate lines and prepends a count. Output: `  1234 192.168.1.1`.
4. Second `sort -rn` — sorts by the count column numerically in reverse (highest first).
5. `head -10` — takes only the top 10 results.

**For compressed logs** — if the log is gzipped: `zcat /var/log/nginx/access.log.gz | awk '{print $1}' | sort | uniq -c | sort -rn | head -10`.

**Key takeaway:** The pipeline pattern — extract, sort, count, re-sort — is the standard streaming approach for log analysis at any scale without loading data into memory.

</details>

📖 **Theory:** [scenario-log-analysis](./08_system_administration/logs_and_journalctl.md#8-real-world-log-analysis)


---

### Q89 · [Design] · `scenario-user-audit`

> **Security asks: which users logged in in the last 30 days and from which IPs. What commands give you this?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Linux maintains login history in binary log files that dedicated commands parse — combine them for a complete picture.

**How to think through this:**
1. **`last`** — reads `/var/log/wtmp` and shows all login/logout events with username, terminal, source IP, and timestamp. Filter to last 30 days: `last -F | awk 'NF > 0' | grep -v "^reboot\|^wtmp"`. For a specific time window: `last --since "30 days ago"` (on systems with GNU last).
2. **`lastb`** — reads `/var/log/btmp` and shows failed login attempts. Useful for security: `lastb | head -50` shows the most recent brute-force attempts.
3. **`lastlog`** — shows the last login time for every account on the system, even accounts that have never logged in. Good for auditing dormant accounts: `lastlog | grep -v "Never logged in"`.
4. **For SSH specifically** — `grep "Accepted" /var/log/auth.log | awk '{print $9, $11}' | sort | uniq -c | sort -rn` shows which users authenticated and from which IPs, with counts.
5. **Combine for a full report:**
   ```
   last -F -w | grep -v "^reboot\|^wtmp\|^$" | awk '{print $1, $3}' | sort | uniq | column -t
   ```
6. **Note:** `wtmp` and `btmp` are rotated and may not go back 30 days on busy systems. Check `/var/log/wtmp.1` for the previous rotation.

**Key takeaway:** `last` + `grep "Accepted" /var/log/auth.log` together cover both successful logins and the source IPs that security needs.

</details>

📖 **Theory:** [scenario-user-audit](./04_users_permissions/users_and_groups.md#linux--users-and-groups)


---

### Q90 · [Design] · `scenario-network-latency`

> **Users in a specific region report slow API response times. The server looks fine. How do you isolate whether the issue is DNS, TCP, or application-level?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Regional slowness with a healthy server points to the network path. Isolate each layer systematically.

**How to think through this:**
1. **DNS resolution** — from the affected region (or use a VPN/cloud instance in that region): `dig @8.8.8.8 api.example.com` and `time nslookup api.example.com`. Check TTL — if DNS TTL is very short, users may be resolving on every request. Check if a regional DNS resolver is returning a far-away IP instead of a nearby one (GeoDNS misconfiguration). Expected DNS resolution: under 50ms.
2. **TCP connection time** — `curl -o /dev/null -s -w "%{time_namelookup} %{time_connect} %{time_appconnect} %{time_total}\n" https://api.example.com`. The `time_connect` field shows raw TCP handshake time — this isolates network round-trip latency from application latency. High `time_connect` = routing or congestion problem, not application.
3. **Traceroute / MTR** — `mtr --report api.example.com` from the affected region. Shows each hop in the route, latency per hop, and packet loss. A spike at a specific hop identifies the congested or misconfigured router.
4. **TLS handshake** — `time_appconnect - time_connect` in the curl output isolates TLS overhead. High TLS time can mean the server is under CPU load for crypto or using slow cipher negotiation.
5. **Application-level** — if all network layers look fine, add server-side timing headers or check APM (e.g., Datadog traces) to see which part of the request handler is slow. Database query? External API call? Memory pressure causing GC pauses?
6. **Cross-check with a CDN** — if there is a CDN in front of the API, check CDN logs for cache hit rate and origin pull latency. A CDN misconfiguration can explain regional-only slowness.

**Key takeaway:** Use `curl -w` timing breakdowns to surgically isolate DNS, TCP, TLS, and application layers without needing special tooling.

</details>

📖 **Theory:** [scenario-network-latency](./06_networking/network_commands.md#linux--network-commands)


---

## 🔴 Tier 5 — Critical Thinking

### Q91 · [Logical] · `predict-permissions`

> **What does `chmod u+x,g-w,o=r file.sh` do to a file that starts with `-rw-rw-rw-`? Show the final permission string.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The final permission string is `-rwxr--r--`.

**How to think through this:**
1. Start: `-rw-rw-rw-`
   - Owner: `rw-` (read, write, no execute)
   - Group: `rw-` (read, write, no execute)
   - Others: `rw-` (read, write, no execute)
2. Apply `u+x` — add execute for owner: `rw-` → `rwx`
3. Apply `g-w` — remove write for group: `rw-` → `r--`
4. Apply `o=r` — set others to exactly read (absolute assignment, not relative): `rw-` → `r--`
5. Result: owner=`rwx`, group=`r--`, others=`r--` → `-rwxr--r--`

**Key insight on `=` vs `+/-`:** `o=r` is an absolute assignment — it sets the others bits to exactly `r--` regardless of what was there. `o+r` would only add read while keeping any existing bits. Here, the `w` that others had is removed by the `=r` assignment.

**Numeric equivalent:** `rwx`=7, `r--`=4, `r--`=4 → `chmod 744 file.sh`

**Key takeaway:** The `=` operator in chmod is an absolute set, not a relative add/remove — it clears all bits for that group first.

</details>

📖 **Theory:** [predict-permissions](./04_users_permissions/file_permissions.md#linux--file-permissions)


---

### Q92 · [Logical] · `predict-redirect`

> **What does `command 2>&1 > file.txt` produce vs `command > file.txt 2>&1`? Why does the order matter?**

```bash
# Order 1: redirect stderr to stdout FIRST, then redirect stdout to file
command 2>&1 > file.txt
# Result: stderr → terminal (original stdout), stdout → file.txt

# Order 2: redirect stdout to file FIRST, then redirect stderr to stdout
command > file.txt 2>&1
# Result: both stdout AND stderr → file.txt
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The order of redirections is evaluated left to right, and `2>&1` means "point FD 2 at whatever FD 1 currently points to" — not "always follow FD 1."

**How to think through this:**
1. Think of file descriptors as variables holding a destination. `2>&1` is an assignment: "set FD 2 equal to the current value of FD 1." It captures the current value of FD 1 at that moment, not a live reference.
2. **Order 1 (`command 2>&1 > file.txt`):**
   - At `2>&1`: FD 1 currently points to the terminal. So FD 2 is set to terminal.
   - At `> file.txt`: FD 1 is redirected to file.txt.
   - Result: FD 1 (stdout) → file.txt, FD 2 (stderr) → terminal. Stderr appears on screen, stdout goes to file.
3. **Order 2 (`command > file.txt 2>&1`):**
   - At `> file.txt`: FD 1 is redirected to file.txt.
   - At `2>&1`: FD 1 now points to file.txt. So FD 2 is set to file.txt.
   - Result: both FD 1 and FD 2 → file.txt. Both stdout and stderr go to the file.
4. The second order is what most people want when they write "redirect all output to a file."

**Key takeaway:** Shell redirections are evaluated left to right; `2>&1` copies the current value of stdout at the moment it is evaluated, not a live pointer.

</details>

📖 **Theory:** [predict-redirect](./03_shell_basics/pipes_and_redirection.md#linux--pipes-and-redirection)


---

### Q93 · [Logical] · `predict-pipe-exit`

> **In `cat file | grep pattern | wc -l`, if grep finds no matches, what is the exit code of the whole pipeline? What is PIPEFAIL?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
By default, the pipeline's exit code is the exit code of the last command (`wc -l`), which is 0 (success) even if `grep` found nothing.

**How to think through this:**
1. `grep` returns exit code 1 when it finds no matches. But in a default bash pipeline, only the exit code of the rightmost command determines `$?`.
2. `wc -l` receives an empty stdin (grep output nothing) and successfully counts 0 lines, exiting with code 0. So `echo $?` after the pipeline returns 0 — the pipeline looks successful even though grep found nothing.
3. This is a silent failure trap in scripts. If you check `$?` after a pipeline expecting to detect "no matches found," the default behavior deceives you.
4. **PIPEFAIL** — a bash option that changes this behavior: `set -o pipefail`. With pipefail enabled, the pipeline's exit code is the exit code of the rightmost command that exited with a non-zero status. In the example, `grep` exits 1, so the pipeline exits 1.
5. Most robust shell scripts start with `set -euo pipefail`: `-e` exits on any error, `-u` treats unset variables as errors, `-o pipefail` catches pipeline failures.
6. `set -e` without `pipefail` will not catch pipeline failures — they are explicitly excluded from `-e` behavior in the POSIX spec.

**Key takeaway:** Without `set -o pipefail`, a pipeline masks failures from all commands except the last one — a common source of silent bugs in scripts.

</details>

📖 **Theory:** [predict-pipe-exit](./03_shell_basics/pipes_and_redirection.md#linux--pipes-and-redirection)


---

### Q94 · [Debug] · `debug-broken-symlink`

> **`ls -la` shows `config.conf -> /etc/app/config.conf` highlighted in red. What is wrong and how do you fix it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The symlink is dangling — it points to a target that does not exist. The red highlighting in `ls` is how most terminals display a broken symbolic link.

**How to think through this:**
1. A symlink stores a path string. When you access the symlink, the kernel follows the path to the target. If the target does not exist, the symlink is dangling. The symlink file itself exists; the path it points to does not.
2. **Verify** — `ls -la /etc/app/config.conf` will confirm "No such file or directory." `readlink config.conf` shows the path the symlink contains.
3. **Common causes:**
   - The target file was deleted or moved.
   - The target path was never created (symlink created prematurely).
   - A relative vs absolute path confusion — if the symlink uses a relative path, it is relative to the symlink's directory, not where you are when you create it.
4. **Fix options:**
   - Re-create the target file at `/etc/app/config.conf` if it was accidentally deleted.
   - Update the symlink to point to the new location: `ln -sf /new/path/config.conf config.conf`.
   - Remove the broken symlink: `rm config.conf`, then recreate correctly.
5. **Find all broken symlinks in a directory:** `find /etc/app -xtype l` (matches symlinks whose targets do not exist).

**Key takeaway:** A dangling symlink is not a filesystem error — the symlink is valid, its target is missing. Fix the target or update the link.

</details>

📖 **Theory:** [debug-broken-symlink](./02_filesystem/links_and_inodes.md#find-broken-symlinks)


---

### Q95 · [Debug] · `debug-zombie-process`

> **`ps aux` shows several Z state processes. `kill -9` has no effect. Why? How do you clean them up?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
Zombie processes are already dead — `kill -9` cannot kill something that is not running. Zombies are corpses waiting for their parent to collect the exit status.

**How to think through this:**
1. When a process exits, its resources (memory, file descriptors) are freed immediately. But its entry in the process table persists, holding the exit status and PID, until the parent calls `wait()` to read it. A process in this state is a zombie (`Z` in `ps`).
2. `kill -9` sends SIGKILL to a running process. A zombie is not running — it has no code to receive signals. The signal is silently ignored.
3. **Identify the parent** — `ps -o ppid= -p <zombie-pid>` gives the parent's PID. The parent is the one responsible for calling `wait()`. If the parent is misbehaving (not reaping children), it is the real problem.
4. **Fix option 1 — signal the parent** — send SIGCHLD to the parent: `kill -CHLD <parent-pid>`. This signals the parent that a child has exited, which should trigger its signal handler to call `wait()`. Whether this works depends on how the parent handles SIGCHLD.
5. **Fix option 2 — kill the parent** — if the parent will not reap, kill it. When the parent dies, init/systemd (PID 1) adopts the orphaned zombie and immediately reaps it. The zombie disappears.
6. **When zombies are a problem** — a handful of zombies is harmless. Thousands of zombies exhaust the PID namespace, preventing new processes from spawning. This indicates a serious bug in the parent application's process management.

**Key takeaway:** Zombies are reaped by their parent or by init after the parent dies — killing the parent is the reliable cleanup method when the parent is not reaping.

</details>

📖 **Theory:** [debug-zombie-process](./05_processes/process_management.md#linux--process-management)


---

### Q96 · [Debug] · `debug-cron-env`

> **A script runs perfectly manually but fails silently when run by cron. What is the most common reason and how do you debug it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The most common cause is the PATH difference between a user's interactive shell and cron's minimal environment.

**How to think through this:**
1. When you run a script manually, you inherit your full shell environment: `PATH`, `HOME`, `USER`, language settings, any variables set in `.bashrc` or `.bash_profile`, and loaded virtualenvs or NVM/rbenv shims.
2. Cron runs with a stripped-down environment. `PATH` is typically just `/usr/bin:/bin`. There is no sourcing of `.bashrc`. `HOME` may differ. Any tool not in those two directories will produce "command not found" — which, if stderr is not captured, disappears silently.
3. **How to debug:**
   - Add output redirection to the crontab: `* * * * * /path/to/script.sh >> /tmp/cronlog.log 2>&1`
   - Add `env > /tmp/cron_env.txt` as a cron job to dump the cron environment and compare it to `env` in your shell
   - Run the script as the cron user in a minimal environment: `env -i HOME=/home/user PATH=/usr/bin:/bin /bin/bash /path/to/script.sh`
4. **Fix options:**
   - Add `PATH=...` at the top of the crontab file (applies to all jobs)
   - Use absolute paths for all commands inside the script: `/usr/local/bin/python3` instead of `python3`
   - Source the environment explicitly at the top of the script: `. /etc/environment` or `. ~/.bash_profile`
5. Other silent-failure causes: script exits non-zero but cron does not email (MAILTO not set), file not executable, script depends on a mounted network filesystem that is not mounted at cron runtime.

**Key takeaway:** Always test cron scripts by simulating the cron environment with `env -i` before assuming they will work — the PATH gap catches almost everyone.

</details>

📖 **Theory:** [debug-cron-env](./08_system_administration/systemd_services.md#environment-variables)


---

### Q97 · [Design] · `design-log-pipeline`

> **Design a solution to ship logs from 50 Linux servers to a central system in real time. Name the tools and explain the flow.**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
A production log pipeline separates collection, transport, buffering, and storage into independent layers so each can scale and fail independently.

**How to think through this:**
1. **Collection (on each server)** — a lightweight log shipper reads log files and forwards them. Options: **Filebeat** (part of the Elastic stack, low resource usage), **Fluent Bit** (very lightweight, cloud-native), or **Promtail** (for Loki). The shipper tracks file offsets so it does not re-send on restart and handles log rotation transparently.
2. **Transport / buffering** — logs are sent to a message queue that absorbs spikes and decouples the shippers from the storage backend. **Kafka** is the standard for high-volume production systems. **Redis Streams** or **AWS Kinesis** are simpler alternatives. The buffer ensures no log loss if the storage layer is temporarily unavailable.
3. **Aggregation / processing (optional)** — **Logstash** or **Fluentd** can sit between the queue and storage to parse, enrich, filter, and route logs. Add fields like server name, environment, datacenter. Drop noisy debug logs. Route errors to an alerting path.
4. **Storage and indexing** — **Elasticsearch** (for full-text search and dashboards via Kibana), **Loki** (for label-based log queries, tightly integrated with Grafana, lower cost than Elasticsearch), or **AWS OpenSearch** / **Splunk** for enterprise.
5. **Full flow:** `Application logs → Filebeat (per server) → Kafka → Logstash → Elasticsearch → Kibana`
6. **Reliability considerations** — Filebeat persists its position; Kafka retains messages for hours/days so the consumer can catch up; Elasticsearch uses replica shards for durability. Each layer can be independently scaled.

**Key takeaway:** The message queue (Kafka) is the critical reliability component — it decouples producers from consumers and prevents log loss during downstream outages.

</details>

📖 **Theory:** [design-log-pipeline](./08_system_administration/logs_and_journalctl.md#linux--logs-and-journalctl)


---

### Q98 · [Design] · `design-user-provisioning`

> **You need to create 100 users on a new server with home directories, specific groups, and SSH keys. How would you automate this?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
User provisioning at scale is a configuration management problem — use a declarative tool, not a bash loop.

**How to think through this:**
1. **Data source** — users, groups, and SSH keys should live in a structured file (CSV, YAML, or pulled from an identity provider like LDAP/Active Directory). Do not hardcode them in a script.
2. **Bash approach (small scale)** — read from a CSV and loop:
   ```bash
   while IFS=, read -r username group pubkey; do
     useradd -m -G "$group" -s /bin/bash "$username"
     mkdir -p /home/"$username"/.ssh
     echo "$pubkey" >> /home/"$username"/.ssh/authorized_keys
     chown -R "$username":"$username" /home/"$username"/.ssh
     chmod 700 /home/"$username"/.ssh
     chmod 600 /home/"$username"/.ssh/authorized_keys
   done < users.csv
   ```
3. **Idempotency problem** — a bash script run twice creates duplicates or errors. A better approach: check `id "$username"` before `useradd`, use `usermod` for existing users.
4. **Configuration management (production scale)** — use **Ansible**, **Puppet**, or **Chef**. Ansible's `user` and `authorized_key` modules are idempotent by design. Running the playbook multiple times is safe. The state file (inventory or vars) becomes the source of truth.
5. **Ansible example approach** — a `vars/users.yml` file lists users and keys. A playbook loops over the list, creates users, sets groups, deploys SSH keys. Ansible handles "already exists" cases automatically.
6. **For ongoing management** — integrate with an identity provider (LDAP, Okta, AWS IAM Identity Center) so user lifecycle (creation, deactivation, key rotation) is managed centrally rather than per-server.

**Key takeaway:** Bash is adequate for one-time small-scale provisioning, but Ansible is the correct answer for anything that needs to be repeatable, auditable, and idempotent.

</details>

📖 **Theory:** [design-user-provisioning](./04_users_permissions/users_and_groups.md#linux--users-and-groups)


---

### Q99 · [Critical] · `edge-case-find-xargs`

> **`find /data -name "*.log" | xargs rm` fails with "Argument list too long". Explain why and provide two ways to fix it.**

```bash
# Problem: xargs passes all arguments in one exec() call
find /data -name "*.log" | xargs rm
# Error: /usr/bin/rm: Argument list too long

# Fix 1: Use find's built-in -delete action (no xargs needed)
find /data -name "*.log" -delete

# Fix 2: Use xargs with -0 and find with -print0 (null-delimited, batched)
find /data -name "*.log" -print0 | xargs -0 rm

# Fix 3: Use xargs with -P for parallel deletion (bonus)
find /data -name "*.log" -print0 | xargs -0 -P4 rm
```

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The error is not a shell limitation — it is a kernel limit on the size of the argument array passed to `exec()`.

**How to think through this:**
1. When the shell runs a command, it calls `execve()` which has a limit on the total size of all arguments and environment variables combined (`ARG_MAX`, typically 2 MB on Linux). With thousands of log files, the list of filenames exceeds this limit in a single `exec()` call.
2. `xargs` by default collects all stdin and passes it as arguments to one `rm` invocation. If the input is large enough, this single invocation hits `ARG_MAX`.
3. **Fix 1: `find -delete`** — `find` has a built-in `-delete` action that deletes each matched file as it finds it. No argument list is ever constructed. This is the simplest and most efficient solution.
4. **Fix 2: `xargs -0` with `find -print0`** — `xargs` without extra flags batches arguments (it will call `rm` multiple times with safe-sized batches). The `-0` flag uses null bytes as delimiters instead of whitespace, which correctly handles filenames with spaces, newlines, or special characters. `find -print0` produces null-terminated output to match.
5. **Why plain `xargs rm` sometimes works** — `xargs` does batch by default, but the default delimiter is whitespace, which breaks filenames with spaces. The failure mode is subtle: some files get deleted, files with spaces do not, and the argument list error only occurs when a single batch still exceeds `ARG_MAX`.
6. **Check `ARG_MAX`:** `getconf ARG_MAX`

**Key takeaway:** Use `find -delete` for simplicity, or `find -print0 | xargs -0` for composability — never use plain `xargs` with filenames that could contain spaces.

</details>

📖 **Theory:** [edge-case-find-xargs](./02_filesystem/file_operations.md#8-finding-files)


---

### Q100 · [Critical] · `edge-case-inode-full`

> **`df -h` shows 40% disk usage but `touch newfile` fails with "No space left on device". What is happening and how do you diagnose it?**

<details>
<summary>💡 Show Answer</summary>

**Answer:**
The inode table is exhausted. Disk space and inodes are two separate resources — a filesystem can run out of either independently.

**How to think through this:**
1. Every file (and directory and symlink) on a filesystem consumes one inode — a metadata record. The number of inodes is fixed when the filesystem is formatted (by default, roughly one inode per 16 KB of space). A filesystem can have space left in data blocks but zero inodes available.
2. `df -h` shows block usage. `df -i` shows inode usage. Run `df -i` — if any filesystem shows `IUse%` at 100%, that is your problem.
3. **Common cause** — a huge number of small files. Typical culprits: a mail spool directory, a PHP session directory, a cache directory, a job queue that is writing one file per task and never cleaning up, or a log directory writing one file per event.
4. **Find the directory consuming inodes** — `find / -xdev -printf '%h\n' | sort | uniq -c | sort -rn | head -20`. This counts files per directory, showing which directory has the most files.
5. **Fix:**
   - Delete the unnecessary small files (`find /var/spool -type f -mtime +30 -delete`)
   - If the files are legitimate and numerous, reformat the filesystem with a higher inode density: `mkfs.ext4 -i 4096 /dev/sdXY` (one inode per 4 KB). Or use XFS, which allocates inodes dynamically and rarely hits this limit.
6. **Prevention** — add inode usage monitoring alongside disk usage monitoring. `df -i` in your monitoring stack.

**Key takeaway:** Disk space and inodes are separate finite resources — `df -i` is the diagnostic you need when `df -h` shows free space but writes fail.

</details>

📖 **Theory:** [edge-case-inode-full](./02_filesystem/links_and_inodes.md#linux--links-and-inodes)
