# Linux — Sudo and Root

> The difference between `sudo` and logging in as root is the difference between a spare key and living in the house. Both give you access — but one is far safer.

---

## 1. The Analogy — A Surgeon's Sign-Out Sheet

In a hospital operating room, surgical tools are kept in a locked cabinet. A surgeon doesn't carry the keys all day — they check them out when needed, sign a log, and return them.

**`sudo` works the same way:**
- You don't run as root 24/7 (too dangerous)
- When you need root access for one command, you `sudo` it
- Linux logs exactly what you did and when
- After the command, you're back to being a regular user

Running as root all the time is like carrying a loaded gun everywhere — one mistake and something gets hurt.

---

## 2. root — The Superuser

```
root user:
──────────────────────────────────────────────────────────
  UID               0 (always)
  Home dir          /root
  Prompt            # (regular users get $)
  Restrictions      None — can do anything
  Can delete        System files, other users' files, everything
  Can read          /etc/shadow, private keys, any file
  Can kill          Any process
──────────────────────────────────────────────────────────
```

```bash
# Identify yourself
whoami       # shows: alice (regular user)
             # shows: root (if you are root)

# The prompt difference
alice@server:~$      # regular user ($)
root@server:~#       # root (#)
```

**Why you should NOT log in as root directly:**
- One typo (`rm -rf /hom` instead of `/home/alice`) = disaster
- Root actions aren't attributed to a specific person in logs
- SSH into root is a common attack vector (most attackers try root first)

---

## 3. `sudo` — Controlled Superpower

`sudo` (Super User DO) runs a single command as root (or another user), logs it, and returns you to normal.

```bash
# Install a package (requires root)
sudo apt install nginx

# Edit a system file
sudo nano /etc/nginx/nginx.conf

# Restart a service
sudo systemctl restart nginx

# View sensitive file
sudo cat /etc/shadow

# Run a command as a specific user (not root)
sudo -u www-data ls /var/www/

# Open a root shell (be careful — you're now root until you exit)
sudo -i           # login shell as root
sudo -s           # non-login shell as root
sudo su -         # alternative

# Run the previous command with sudo (forgot sudo!)
sudo !!
```

---

## 4. How `sudo` Works

When you run `sudo something`:

```
1. sudo checks /etc/sudoers (who is allowed to sudo)
2. Asks for YOUR password (not root's password)
3. Verifies you're authorized
4. Logs the command to /var/log/auth.log
5. Runs the command as root
6. Returns you to your normal user
```

The password is cached for 15 minutes by default — you won't be asked again within that window.

---

## 5. The `/etc/sudoers` File

This file controls who can use sudo and what they can do.

**Never edit it directly — use `visudo`** (it validates syntax before saving, preventing lockouts):

```bash
sudo visudo
```

### Common sudoers syntax

```bash
# Full sudo access (can run anything as root)
alice ALL=(ALL:ALL) ALL

# Password-less sudo (dangerous — only for automation/trusted users)
alice ALL=(ALL:ALL) NOPASSWD: ALL

# Allow alice to restart only nginx
alice ALL=(ALL) /bin/systemctl restart nginx

# Allow the developers group full sudo
%developers ALL=(ALL:ALL) ALL

# Allow bob to run specific commands without password
bob ALL=(ALL) NOPASSWD: /usr/bin/apt update, /bin/systemctl status *
```

### Read the syntax: `user host=(run_as) commands`

```
alice   ALL=(ALL:ALL)  ALL
  │      │     │        │
  │      │     │        └── which commands (ALL = all)
  │      │     └─────────── run as which user:group (ALL:ALL = any)
  │      └───────────────── from which host (ALL = any)
  └──────────────────────── who this applies to
```

---

## 6. Checking sudo Access

```bash
# Can I sudo? What can I do?
sudo -l

# Sample output:
# User alice may run the following commands on server:
#   (ALL : ALL) ALL

# Check if a user has sudo
groups alice | grep sudo
id alice

# Who has sudo on this system?
grep -Po '^sudo.+:\K.*$' /etc/group
getent group sudo
```

---

## 7. sudo Logs — The Audit Trail

Every sudo command is logged:

```bash
# Ubuntu/Debian
sudo tail -f /var/log/auth.log | grep sudo

# RHEL/CentOS/Amazon Linux
sudo tail -f /var/log/secure | grep sudo

# Example log entries:
# Jan 15 10:23:41 server sudo: alice : TTY=pts/1 ;
#   PWD=/home/alice ; USER=root ; COMMAND=/bin/systemctl restart nginx
```

This is how you audit what happened on a server. If something was misconfigured, you can see exactly who ran what command and when.

---

## 8. Switching to Root — When You Need It

Sometimes you need to run many root commands in sequence. Instead of `sudo` before each one:

```bash
# Method 1: sudo -i (preferred — full login shell as root)
sudo -i
# You're now root. Exit with 'exit' or Ctrl+D

# Method 2: sudo -s (root shell, keeps current env)
sudo -s

# Method 3: su - (switch to root using root's password)
# Not recommended — root password shouldn't exist on modern systems
su -
```

When you're done with root tasks, always `exit` immediately:
```bash
root@server:~# exit
alice@server:~$
```

---

## 9. Disabling Root Login (Security Best Practice)

On production servers, disable direct root login entirely:

```bash
# Disable root SSH login
sudo nano /etc/ssh/sshd_config
# Change: PermitRootLogin yes → PermitRootLogin no
sudo systemctl restart sshd

# Lock root account password (so 'su -' doesn't work either)
sudo passwd -l root

# Verify (should show 'L' = locked)
sudo passwd -S root
```

Now root access is only possible through `sudo` from an authorised user — fully audited and controlled.

---

## 10. Real World Scenarios

**New server setup — create admin user before disabling root:**
```bash
# Logged in as root initially
useradd -m -s /bin/bash admin
passwd admin
usermod -aG sudo admin

# Test sudo works BEFORE disabling root login
su - admin
sudo ls /root    # should work

# Now disable root login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd
```

**Forgot sudo, command already running:**
```bash
# You just ran: nano /etc/nginx/nginx.conf
# Got "permission denied"
# Run the last command with sudo:
sudo !!
```

**Give a developer access to restart their app only:**
```bash
sudo visudo
# Add:
deploy ALL=(ALL) NOPASSWD: /bin/systemctl restart myapp, /bin/systemctl status myapp
```

---

## 11. Summary

```
root:
  UID 0, can do anything
  Prompt shows # instead of $
  Don't log in as root — use sudo instead

sudo:
  Runs one command as root
  Asks YOUR password (not root's)
  Logs everything to /var/log/auth.log
  sudo !! runs last command with sudo

/etc/sudoers:
  Always edit with: sudo visudo
  user ALL=(ALL:ALL) ALL    → full access
  NOPASSWD: command         → no password prompt
  %group ALL=(ALL) ALL      → group sudo access

Security:
  ✓ Disable root SSH login (PermitRootLogin no)
  ✓ Lock root password (passwd -l root)
  ✓ Only give sudo to people who need it
  ✓ Audit with: sudo grep sudo /var/log/auth.log
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← File Permissions](./file_permissions.md) &nbsp;|&nbsp; **Next:** [Process Management →](../05_processes/process_management.md)

**Related Topics:** [Users and Groups](./users_and_groups.md) · [File Permissions](./file_permissions.md)

---

## 📝 Practice Questions

- 📝 [Q23 · sudo](../linux_practice_questions_100.md#q23--normal--sudo)
- 📝 [Q73 · security-hardening](../linux_practice_questions_100.md#q73--thinking--security-hardening)
- 📝 [Q74 · selinux-apparmor](../linux_practice_questions_100.md#q74--thinking--selinux-apparmor)

