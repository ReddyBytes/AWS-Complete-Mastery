# Linux — Firewall

> A firewall decides what network traffic is allowed in and out of your server. Without one, every port you open is a potential entry point for attackers.

---

## 1. The Analogy — A Bouncer at a Club

Your server is the club. The firewall is the bouncer at the door:

- **Allowed** → traffic comes through
- **Denied** → connection is dropped or rejected
- **Rules** → the bouncer's list of who gets in based on: source, destination, port, protocol

By default on a fresh server: everything is usually allowed. Your job is to lock it down to only what's needed.

---

## 2. Two Layers of Firewall on Linux

```
Internet
    ↓
Cloud Security Group     ← Layer 1: Cloud-level (AWS Security Group, GCP Firewall)
    ↓
Linux Firewall           ← Layer 2: OS-level (ufw, iptables)
    ↓
Your Application
```

On AWS: Security Groups are the first line. Linux firewall is the second. Always configure both.

---

## 3. `ufw` — Uncomplicated Firewall (Ubuntu)

`ufw` is the beginner-friendly frontend to iptables, default on Ubuntu.

### Basic Usage

```bash
# Check status
sudo ufw status
sudo ufw status verbose      # more detail

# Enable / disable
sudo ufw enable
sudo ufw disable

# Default policies (set these first)
sudo ufw default deny incoming    # block all incoming by default
sudo ufw default allow outgoing   # allow all outgoing by default
```

### Allowing Services

```bash
# Allow by port
sudo ufw allow 22              # SSH
sudo ufw allow 80              # HTTP
sudo ufw allow 443             # HTTPS
sudo ufw allow 5432            # PostgreSQL

# Allow by service name (ufw knows common ports)
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Allow a port range
sudo ufw allow 8000:8080/tcp

# Allow UDP
sudo ufw allow 53/udp          # DNS

# Allow from a specific IP only
sudo ufw allow from 192.168.1.10 to any port 22

# Allow from a specific subnet
sudo ufw allow from 10.0.0.0/24 to any port 5432
```

### Denying and Deleting Rules

```bash
# Deny a port
sudo ufw deny 3306             # block MySQL from outside

# Delete a rule
sudo ufw delete allow 80
sudo ufw delete allow http

# Delete by rule number
sudo ufw status numbered
sudo ufw delete 3              # delete rule number 3

# Reset all rules
sudo ufw reset
```

### Typical Server Setup

```bash
# Start fresh
sudo ufw reset

# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH first — before enabling! (or you'll lock yourself out)
sudo ufw allow 22

# Allow web traffic
sudo ufw allow 80
sudo ufw allow 443

# Allow specific app
sudo ufw allow 8080            # app server
sudo ufw allow from 10.0.0.0/8 to any port 5432   # DB from private network only

# Enable
sudo ufw enable

# Check
sudo ufw status verbose
```

---

## 4. `firewalld` — RHEL/CentOS/Amazon Linux

`firewalld` is the default on Red Hat-based systems. It uses the concept of **zones**.

```bash
# Check status
sudo firewall-cmd --state
sudo firewall-cmd --list-all

# Start/stop
sudo systemctl start firewalld
sudo systemctl enable firewalld

# Add a service (permanent)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=ssh

# Add a port (permanent)
sudo firewall-cmd --permanent --add-port=8080/tcp

# Remove a service
sudo firewall-cmd --permanent --remove-service=http

# Apply changes (reload required after --permanent)
sudo firewall-cmd --reload

# Temporary (until reboot, no --permanent)
sudo firewall-cmd --add-port=3000/tcp

# List everything
sudo firewall-cmd --list-all
```

---

## 5. `iptables` — The Low-Level Firewall

Both `ufw` and `firewalld` are frontends to `iptables`. Understanding iptables helps you debug.

```bash
# List current rules
sudo iptables -L -n -v

# List with line numbers
sudo iptables -L -n -v --line-numbers

# Allow incoming on port 80
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Allow established connections (important — don't block responses!)
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Drop all other incoming
sudo iptables -A INPUT -j DROP

# Delete a rule by line number
sudo iptables -D INPUT 3

# Save rules (Ubuntu)
sudo iptables-save > /etc/iptables/rules.v4

# Save rules (RHEL/CentOS)
sudo service iptables save
```

**For most purposes, use `ufw` or `firewalld` instead of iptables directly.**

---

## 6. Checking What's Blocked

```bash
# See all ufw rules with rule numbers
sudo ufw status numbered

# Check if a specific port is accessible from outside
# From ANOTHER machine:
nc -zv server-ip 80
telnet server-ip 80

# From the server itself (bypasses firewall)
nc -zv localhost 80

# See what iptables is actually doing
sudo iptables -L -n -v

# Log dropped packets (useful for debugging)
sudo ufw logging on
sudo tail -f /var/log/ufw.log
```

---

## 7. Real World Firewall Setup

**Typical web server (nginx + app + database):**

```bash
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH — only from your office IP
sudo ufw allow from 203.0.113.0/24 to any port 22

# Web traffic — anyone
sudo ufw allow 80
sudo ufw allow 443

# App server — only from nginx (localhost)
sudo ufw allow from 127.0.0.1 to any port 8080

# Database — only from app subnet
sudo ufw allow from 10.0.1.0/24 to any port 5432

sudo ufw enable
sudo ufw status verbose
```

**Important — always test SSH works before enabling the firewall:**
```bash
# Open a SECOND terminal and test SSH login before enabling
# If it works → safe to enable
# If not → you'd lock yourself out!
```

---

## 8. Summary

```
ufw (Ubuntu):
  ufw default deny incoming         block all by default
  ufw allow 22                      allow SSH
  ufw allow from IP to any port 22  SSH from specific IP only
  ufw deny 3306                     block a port
  ufw status numbered               view with numbers
  ufw delete 3                      delete rule 3

firewalld (RHEL/Amazon Linux):
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-port=8080/tcp
  firewall-cmd --reload             apply permanent changes

Key rules to always set:
  ✓ Default deny incoming
  ✓ Allow 22 (SSH) BEFORE enabling firewall
  ✓ Allow 80/443 for web servers
  ✓ Restrict database ports to private network only

Two layers:
  Cloud: AWS Security Groups
  OS: ufw / firewalld
  Both must allow traffic for it to pass
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← SSH](./ssh.md) &nbsp;|&nbsp; **Next:** [Package Management →](../07_package_management/apt_and_yum.md)

**Related Topics:** [Network Commands](./network_commands.md) · [SSH](./ssh.md)
