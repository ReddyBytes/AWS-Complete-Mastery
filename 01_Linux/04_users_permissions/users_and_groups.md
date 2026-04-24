# Linux — Users and Groups

> Every file, process, and action in Linux is owned by a user. Understanding users and groups is the foundation of Linux security.

---

## 1. The Analogy — An Office Building

Think of a Linux system as an office building:

- **Users** are individual employees — each has their own desk (home directory), badge (username), and ID number (UID)
- **Groups** are departments — Marketing, Engineering, Finance
- **root** is the building manager — can go anywhere, do anything
- **File permissions** are door locks — who can enter which room

When you create a file, it belongs to you. Others can only access it if you give them permission.

---

## 2. User Types

```
User Types on Linux:
──────────────────────────────────────────────────────────
  root (UID 0)      The superuser. Full system access.
                    Can read/write/delete any file.
                    Can kill any process.

  System users      UIDs 1–999 (or 1–499 on older systems)
  (UID 1-999)       Created by the OS for services:
                    www-data (nginx), postgres, mysql
                    They don't log in — they just run services

  Regular users     UIDs 1000+
  (UID 1000+)       People who log in to the system
                    Each gets their own home dir in /home/
──────────────────────────────────────────────────────────
```

---

## 3. User Information Files

Linux stores user info in plain text files:

```bash
# /etc/passwd — user accounts (not passwords!)
# Format: username:x:UID:GID:comment:home:shell
cat /etc/passwd

alice:x:1001:1001:Alice Smith:/home/alice:/bin/bash
nginx:x:33:33:www-data:/var/www:/usr/sbin/nologin
root:x:0:0:root:/root:/bin/bash

# /etc/shadow — hashed passwords (readable only by root)
sudo cat /etc/shadow

# /etc/group — group definitions
# Format: groupname:x:GID:members
cat /etc/group
sudo:x:27:alice,bob
docker:x:999:alice
```

---

## 4. Creating and Managing Users

```bash
# Create a new user (with home directory)
sudo useradd -m alice

# Create user with specific shell, comment, home dir
sudo useradd -m -s /bin/bash -c "Alice Smith" alice

# Set password for user
sudo passwd alice

# Create user and add to group at creation
sudo useradd -m -G sudo,docker alice

# Create a system user (for a service, no home dir, no login)
sudo useradd --system --no-create-home --shell /usr/sbin/nologin nginx
```

---

## 5. Modifying Users

```bash
# Change username
sudo usermod -l newname oldname

# Add user to a group (without removing from other groups)
sudo usermod -aG docker alice
sudo usermod -aG sudo alice

# Change user's home directory
sudo usermod -d /new/home alice

# Lock a user account (prevent login)
sudo usermod -L alice

# Unlock a user account
sudo usermod -U alice

# Change user's shell
sudo usermod -s /bin/zsh alice

# Set account expiry date
sudo usermod -e 2024-12-31 contractor
```

---

## 6. Deleting Users

```bash
# Remove user (keep home directory)
sudo userdel alice

# Remove user AND their home directory
sudo userdel -r alice

# Check if any files still belong to deleted user
find / -user alice 2>/dev/null
find / -uid 1001 2>/dev/null        # by UID (if user is gone)
```

---

## 7. Creating and Managing Groups

```bash
# Create a new group
sudo groupadd developers

# Create group with specific GID
sudo groupadd -g 1500 developers

# Add user to group
sudo usermod -aG developers alice

# Remove user from group
sudo gpasswd -d alice developers

# Delete a group
sudo groupdel developers

# See what groups a user belongs to
groups alice
id alice

# See all members of a group
getent group docker
```

---

## 8. Switching Users

```bash
# Switch to another user (keeps current environment)
su alice

# Switch to another user (full login environment)
su - alice

# Switch to root
su -

# Run a single command as another user
su - alice -c "ls /home/alice"

# Run a command as root (preferred over su)
sudo ls /root

# Run a command as a specific user via sudo
sudo -u alice ls /home/alice
```

---

## 9. Viewing User Information

```bash
# Who am I?
whoami

# My UID, GID, and all groups
id

# All info about another user
id alice

# Who is currently logged in?
who
w                    # more detailed — shows what they're doing

# Last login times
last                 # all recent logins
last alice           # alice's login history
lastlog              # last login for all users

# Currently logged in users
users
```

---

## 10. Password Policies

```bash
# Change your own password
passwd

# Change another user's password (root only)
sudo passwd alice

# Force user to change password on next login
sudo passwd -e alice

# Set password expiry (days)
sudo chage -M 90 alice       # password expires in 90 days
sudo chage -l alice          # view expiry info for alice

# Lock an account immediately
sudo passwd -l alice

# Unlock
sudo passwd -u alice
```

---

## 11. Real World Scenarios

**Set up a new developer on a server:**
```bash
# Create user with home dir
sudo useradd -m -s /bin/bash -c "John Developer" john

# Set initial password
sudo passwd john

# Add to relevant groups
sudo usermod -aG sudo,docker,developers john

# They can now log in and deploy
```

**Create a service account for an application:**
```bash
# Service account — no login, no home dir
sudo useradd --system --no-create-home --shell /usr/sbin/nologin myapp

# Run the app as this user
sudo -u myapp /usr/local/bin/myapp --config /etc/myapp/config.yaml
```

**Audit who has sudo access:**
```bash
grep -Po '^sudo.+:\K.*$' /etc/group
getent group sudo
cat /etc/sudoers | grep -v "^#" | grep -v "^$"
```

---

## 12. Summary

```
User management:
  useradd -m username       create user with home dir
  passwd username           set password
  usermod -aG group user    add user to group
  userdel -r username       delete user + home dir

Group management:
  groupadd groupname        create group
  groups username           show user's groups
  id username               show UID, GID, all groups

Switching users:
  su - username             switch to user (full login)
  sudo command              run command as root
  sudo -u user command      run command as specific user

Key files:
  /etc/passwd               user accounts
  /etc/shadow               hashed passwords
  /etc/group                groups and members
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Text Processing](../03_shell_basics/text_processing.md) &nbsp;|&nbsp; **Next:** [File Permissions →](./file_permissions.md)

**Related Topics:** [File Permissions](./file_permissions.md) · [Sudo and Root](./sudo_and_root.md)

---

## 📝 Practice Questions

- 📝 [Q22 · users-groups](../linux_practice_questions_100.md#q22--normal--users-groups)
- 📝 [Q24 · etc-passwd-shadow](../linux_practice_questions_100.md#q24--normal--etc-passwd-shadow)
- 📝 [Q89 · scenario-user-audit](../linux_practice_questions_100.md#q89--design--scenario-user-audit)
- 📝 [Q98 · design-user-provisioning](../linux_practice_questions_100.md#q98--design--design-user-provisioning)

