# Linux — SSH

> SSH is how you talk to every server you'll ever manage. Master it and every remote server feels like your local machine.

---

## 1. What Is SSH?

**SSH** (Secure Shell) is an encrypted protocol for connecting to remote Linux servers. Before SSH, people used Telnet — which sent passwords in plain text over the network. Anyone snooping the connection could read your password.

SSH solved this with:
- **Encrypted connection** — all traffic is scrambled
- **Key-based authentication** — no passwords to steal
- **Tunneling** — forward ports securely through the connection

```
Your laptop ──encrypted tunnel──► Remote Server
   (client)                         (SSH daemon, sshd)
```

---

## 2. Basic SSH Connection

```bash
# Connect using username and password
ssh username@server-ip
ssh ubuntu@54.23.45.67

# Connect with a specific port (default is 22)
ssh -p 2222 username@server-ip

# Connect with a private key file
ssh -i ~/.ssh/mykey.pem ubuntu@54.23.45.67

# AWS EC2 connection (most common pattern)
ssh -i ~/.ssh/my-key.pem ec2-user@ec2-54-23-45-67.compute.amazonaws.com

# Exit the connection
exit
# or Ctrl+D
```

---

## 3. SSH Keys — Never Use Passwords for Servers

Password authentication is weak. Keys are better:

- A **private key** stays on your machine (never share it)
- A **public key** goes on the server (safe to share)
- The server verifies you have the private key that matches — without you ever sending the private key

```
Your machine:                    Remote server:
  ~/.ssh/id_rsa         ←→      ~/.ssh/authorized_keys
  (private key)                  (your public key stored here)
  NEVER SHARE THIS               Safe to share
```

### Generating a Key Pair

```bash
# Generate RSA key (4096-bit, very secure)
ssh-keygen -t rsa -b 4096 -C "alice@mycompany.com"

# Generate Ed25519 key (modern, shorter, equally secure)
ssh-keygen -t ed25519 -C "alice@mycompany.com"

# You'll be prompted:
# - Where to save: press Enter for default (~/.ssh/id_ed25519)
# - Passphrase: recommended for extra security (optional)

# Result:
ls ~/.ssh/
# id_ed25519      ← private key (NEVER share or copy to server)
# id_ed25519.pub  ← public key (safe to share, copy to servers)
```

---

## 4. Copying Your Key to a Server

```bash
# Method 1: ssh-copy-id (easiest)
ssh-copy-id username@server-ip

# With a specific key
ssh-copy-id -i ~/.ssh/id_ed25519.pub username@server-ip

# With a non-standard port
ssh-copy-id -p 2222 username@server-ip

# Method 2: Manual (when ssh-copy-id isn't available)
# Copy public key content
cat ~/.ssh/id_ed25519.pub
# Then on the server, paste it into:
# echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
# chmod 600 ~/.ssh/authorized_keys

# Method 3: For AWS EC2 — key is set at launch time
# Download the .pem file from AWS Console
# ssh -i ~/Downloads/mykey.pem ec2-user@ip-address
```

---

## 5. SSH Config File — Stop Typing Long Commands

Instead of typing `ssh -i ~/.ssh/mykey.pem -p 2222 ubuntu@54.23.45.67` every time:

```bash
nano ~/.ssh/config
```

```
# AWS development server
Host dev-server
    HostName 54.23.45.67
    User ubuntu
    IdentityFile ~/.ssh/mykey.pem
    Port 22

# AWS production server
Host prod-server
    HostName 54.23.45.100
    User ec2-user
    IdentityFile ~/.ssh/prod-key.pem

# Jump through a bastion host
Host private-app
    HostName 10.0.1.50
    User ubuntu
    ProxyJump bastion-server

# Bastion (jump host)
Host bastion-server
    HostName 54.23.45.200
    User ubuntu
    IdentityFile ~/.ssh/bastion-key.pem
```

```bash
# Now connect with just:
ssh dev-server
ssh prod-server
ssh private-app    # automatically jumps through bastion
```

---

## 6. Running Commands Without Interactive Login

```bash
# Run a single command on remote server
ssh ubuntu@server "ls /var/log"

# Run multiple commands
ssh ubuntu@server "sudo systemctl status nginx && df -h"

# Run a script on remote server
ssh ubuntu@server "bash -s" < local_script.sh

# Copy files with SCP (secure copy)
scp file.txt ubuntu@server:/home/ubuntu/
scp ubuntu@server:/var/log/app.log ./local_copy.log

# Copy entire directory
scp -r local_dir/ ubuntu@server:/tmp/

# Use rsync for efficient sync (only transfers changes)
rsync -avz ./app/ ubuntu@server:/opt/app/
rsync -avz --delete ./app/ ubuntu@server:/opt/app/  # delete removed files
```

---

## 7. SSH Tunneling

SSH can forward ports — useful when a service is only accessible from the server itself.

```bash
# Local port forwarding: access server's port 5432 as localhost:5432
# (Access a database that's not exposed to the internet)
ssh -L 5432:localhost:5432 ubuntu@server
# Now: psql -h localhost -p 5432 connects through the tunnel

# Access a service on a private subnet through a bastion
ssh -L 8080:private-app-server:80 ubuntu@bastion

# Reverse tunnel: expose your local port to the server
ssh -R 8080:localhost:3000 ubuntu@server
# Someone on the server can now hit localhost:8080 and reach your local port 3000

# Dynamic SOCKS proxy (route all browser traffic through server)
ssh -D 8888 ubuntu@server
# Configure browser to use SOCKS5 proxy localhost:8888
```

---

## 8. Securing SSH

On any production server, harden SSH:

```bash
sudo nano /etc/ssh/sshd_config
```

```
# Disable password authentication (use keys only)
PasswordAuthentication no

# Disable root login
PermitRootLogin no

# Allow only specific users
AllowUsers alice bob deploy

# Change default port (reduces automated scan noise)
Port 2222

# Limit authentication attempts
MaxAuthTries 3

# Disconnect idle sessions after 15 minutes
ClientAliveInterval 300
ClientAliveCountMax 3
```

```bash
# After editing, reload sshd
sudo systemctl reload sshd

# Test the new config BEFORE logging out (in case you broke it)
# Open a SECOND SSH connection first to test
ssh -p 2222 alice@server
```

---

## 9. SSH Agent — Don't Type Your Passphrase Repeatedly

```bash
# Start the agent
eval $(ssh-agent)

# Add your key (prompts for passphrase once)
ssh-add ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l

# Now all SSH connections use the loaded key without prompting
ssh dev-server
ssh prod-server
```

On macOS, keys can be stored in the Keychain:
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

---

## 10. Troubleshooting SSH

```bash
# Connection refused
sudo systemctl status sshd          # is sshd running?
ss -tlnp | grep :22                  # is it listening?
sudo ufw status                      # is firewall blocking it?

# Permission denied (public key)
# On your machine:
ls -la ~/.ssh/                       # does the key exist?
ssh-add -l                           # is it loaded in agent?

# On the server:
ls -la ~/.ssh/                       # 700 permissions?
cat ~/.ssh/authorized_keys           # is your public key there?
ls -la ~/.ssh/authorized_keys        # 600 permissions?

# Debug mode (very verbose output)
ssh -vvv ubuntu@server               # shows exactly what's failing

# Check SSH server logs
sudo journalctl -u sshd -f
sudo tail -f /var/log/auth.log
```

---

## 11. Summary

```
Connect:
  ssh user@host                     basic connection
  ssh -i key.pem user@host          with key file
  ssh dev-server                    using SSH config alias

Keys:
  ssh-keygen -t ed25519             generate key pair
  ssh-copy-id user@host             copy key to server
  ~/.ssh/config                     connection shortcuts

Secure copy:
  scp file.txt user@host:/path/     upload file
  scp user@host:/path/file.txt ./   download file
  rsync -avz src/ user@host:/dst/   sync directory

Tunneling:
  ssh -L local:remote:port host     local port forward
  ssh -R remote:local:port host     reverse tunnel

Hardening:
  PasswordAuthentication no         keys only
  PermitRootLogin no                no direct root login
  Port 2222                         non-standard port
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Network Commands](./network_commands.md) &nbsp;|&nbsp; **Next:** [Firewall →](./firewall.md)

**Related Topics:** [Network Commands](./network_commands.md) · [Firewall](./firewall.md)
