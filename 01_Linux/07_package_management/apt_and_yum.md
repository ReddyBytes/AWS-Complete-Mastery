# Linux — Package Management (apt & yum/dnf)

> Package managers are how you install, update, and remove software on Linux — the App Store of the server world, but faster and from the terminal.

---

## 1. The Analogy — A Supermarket with a Delivery Service

Without a package manager, installing software means:
- Find the download link
- Download a file
- Check if it needs other libraries (dependencies)
- Install those first
- Install your software
- Hope it doesn't conflict with something else

With a package manager:
```bash
sudo apt install nginx
# That's it. It finds nginx, downloads it, installs all dependencies, done.
```

It's like ordering from a supermarket that delivers everything you need, already checked for quality.

---

## 2. The Two Big Families

```
Debian Family (Ubuntu, Debian, Mint):
  Package format:    .deb
  Package manager:   apt (or apt-get for scripts)
  Package database:  /var/lib/dpkg/
  Config sources:    /etc/apt/sources.list

Red Hat Family (RHEL, CentOS, Amazon Linux, Fedora):
  Package format:    .rpm
  Package manager:   yum (older) / dnf (modern)
  Package database:  /var/lib/rpm/
  Config sources:    /etc/yum.repos.d/
```

Same concepts, different commands. Learn one, and the other takes 10 minutes.

---

## 3. `apt` — Debian/Ubuntu

### Daily Commands

```bash
# Update package list (always do this before installing!)
sudo apt update

# Upgrade all installed packages
sudo apt upgrade

# Install a package
sudo apt install nginx

# Install multiple packages
sudo apt install nginx curl git python3-pip

# Remove a package
sudo apt remove nginx

# Remove package + config files
sudo apt purge nginx

# Remove unused packages (dependencies no longer needed)
sudo apt autoremove

# Search for a package
apt search nginx
apt search "web server"

# Show info about a package
apt show nginx

# List installed packages
apt list --installed
apt list --installed | grep nginx

# Update + upgrade in one step (common in scripts)
sudo apt update && sudo apt upgrade -y
```

### What Happens When You `apt install`?

```
1. apt reads /etc/apt/sources.list (list of repositories)
2. Downloads package metadata from those repos
3. Resolves dependencies (what other packages are needed)
4. Downloads all required .deb files to /var/cache/apt/archives/
5. Installs them in the right order
6. Runs post-install scripts
```

### Managing Repositories

```bash
# Add a new repository (PPA — Personal Package Archive)
sudo add-apt-repository ppa:ondrej/nginx

# Add a third-party repo key + repo (Docker example)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list

sudo apt update
sudo apt install docker-ce

# List configured repos
cat /etc/apt/sources.list
ls /etc/apt/sources.list.d/
```

### Non-Interactive (for scripts)

```bash
# -y = answer yes to all prompts
sudo apt install -y nginx

# Prevent any interactive prompts at all
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y tzdata
```

---

## 4. `yum` / `dnf` — Red Hat/Amazon Linux

### RHEL 7, CentOS 7, Amazon Linux 2 → use `yum`
### RHEL 8+, CentOS 8+, Fedora, Amazon Linux 2023 → use `dnf`

The commands are almost identical. `dnf` is the newer, faster replacement.

```bash
# Update package list + upgrade (one command, unlike apt)
sudo yum update
sudo dnf update

# Install a package
sudo yum install nginx
sudo dnf install nginx

# Install multiple packages
sudo dnf install nginx curl git python3-pip

# Remove a package
sudo yum remove nginx
sudo dnf remove nginx

# Search for a package
yum search nginx
dnf search nginx

# Show info about a package
yum info nginx
dnf info nginx

# List installed packages
yum list installed
dnf list installed | grep nginx

# Clean cached data
sudo yum clean all
sudo dnf clean all
```

### Managing Repositories with yum/dnf

```bash
# List configured repositories
yum repolist
dnf repolist

# Install EPEL (Extra Packages for Enterprise Linux)
sudo yum install epel-release       # Amazon Linux 2
sudo dnf install epel-release       # Amazon Linux 2023

# Add a custom repo file
sudo cat > /etc/yum.repos.d/myrepo.repo << 'EOF'
[myrepo]
name=My Custom Repo
baseurl=https://repo.example.com/
enabled=1
gpgcheck=0
EOF

# Install from a specific repo
sudo dnf install --enablerepo=epel htop
```

---

## 5. Installing .deb or .rpm Files Directly

Sometimes you download a package file directly:

```bash
# Install a .deb file (Ubuntu)
sudo dpkg -i package.deb

# Fix any missing dependencies after dpkg
sudo apt install -f

# Better: use apt to install local .deb (handles deps)
sudo apt install ./package.deb

# Install a .rpm file (RHEL/CentOS)
sudo rpm -ivh package.rpm

# Better: use dnf for local .rpm
sudo dnf install ./package.rpm
```

---

## 6. Finding Where Files Were Installed

```bash
# Ubuntu: which files did a package install?
dpkg -L nginx

# Where is the nginx binary?
which nginx
dpkg -L nginx | grep bin

# What package owns this file?
dpkg -S /usr/sbin/nginx           # Ubuntu
rpm -qf /usr/sbin/nginx           # RHEL/CentOS
```

---

## 7. Real World Examples

**Set up a fresh Ubuntu server for a Python app:**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv nginx git curl
pip3 install --user gunicorn
```

**Install Docker on Ubuntu:**
```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
# Add Docker GPG key and repo (see Docker docs for latest)
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker $USER
```

**Install common tools on Amazon Linux 2023:**
```bash
sudo dnf update -y
sudo dnf install -y git curl wget vim htop python3 python3-pip
sudo dnf install -y docker
sudo systemctl enable --now docker
```

---

## 8. Summary

```
Ubuntu/Debian (apt):
  sudo apt update             refresh package list
  sudo apt upgrade -y         upgrade all packages
  sudo apt install pkg        install package
  sudo apt remove pkg         remove package
  sudo apt purge pkg          remove + delete config
  sudo apt autoremove         clean unused dependencies
  apt search term             find packages
  apt show pkg                package details

RHEL/Amazon Linux (yum/dnf):
  sudo dnf update             update everything
  sudo dnf install pkg        install package
  sudo dnf remove pkg         remove package
  dnf search term             find packages
  dnf info pkg                package details

Key insight:
  ✓ Always `apt update` before `apt install`
  ✓ Use -y flag in scripts to avoid interactive prompts
  ✓ apt uses /etc/apt/sources.list for repos
  ✓ dnf/yum uses /etc/yum.repos.d/ for repos
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Firewall](../06_networking/firewall.md) &nbsp;|&nbsp; **Next:** [Build from Source →](./build_from_source.md)

**Related Topics:** [Build from Source](./build_from_source.md)
