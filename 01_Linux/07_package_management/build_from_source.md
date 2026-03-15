# Linux — Build from Source

> Package managers don't have everything. Sometimes you need the latest version, custom compile flags, or software that's just not in any repository.

---

## 1. When Do You Build from Source?

```
Situations where building from source is necessary:
──────────────────────────────────────────────────────────
  Latest version    apt has nginx 1.18, you need 1.25
  Custom options    Compile with specific modules enabled
  Not in repos      Niche software with no .deb/.rpm package
  Patched version   Apply a security patch before official release
  Performance       Compile with CPU-specific optimisations
──────────────────────────────────────────────────────────
```

For everyday software, use your package manager. Build from source only when you have a specific reason.

---

## 2. The Classic Build Process

Most open-source C/C++ software follows the same three-step pattern:

```bash
./configure    # 1. Check your system, generate Makefile
make           # 2. Compile the code
make install   # 3. Copy files to the right locations
```

It's been this way since the 1980s and still applies to thousands of projects.

---

## 3. Install Build Tools First

Before building anything, you need compilers and tools:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y build-essential      # gcc, g++, make, libc-dev
sudo apt install -y git curl wget        # download tools

# RHEL/CentOS/Amazon Linux
sudo dnf groupinstall -y "Development Tools"   # gcc, g++, make
sudo dnf install -y git curl wget

# Verify
gcc --version
make --version
```

---

## 4. Step-by-Step Example — Building nginx from Source

```bash
# Step 1: Install dependencies
sudo apt install -y libpcre3-dev zlib1g-dev libssl-dev

# Step 2: Download the source code
cd /tmp
wget https://nginx.org/download/nginx-1.25.3.tar.gz

# Step 3: Extract the archive
tar -xzf nginx-1.25.3.tar.gz
cd nginx-1.25.3

# Step 4: Configure — decide what to compile in
./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib64/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_gzip_static_module

# Step 5: Compile (use all CPU cores with -j)
make -j$(nproc)

# Step 6: Install
sudo make install

# Verify
nginx -v
```

---

## 5. What `./configure` Does

`configure` is a shell script that:
- Checks if required libraries and tools are present
- Lets you choose features to include/exclude
- Generates a `Makefile` tailored to your system

```bash
# See all available options
./configure --help

# Common configure flags:
--prefix=/usr/local          # where to install (default: /usr/local)
--with-feature               # enable an optional feature
--without-feature            # disable a feature
--enable-feature             # another way to enable
--disable-feature            # another way to disable
--with-library=/path/to/lib  # use a specific library location
```

If configure fails, it tells you exactly what's missing:
```
checking for PCRE library... not found
configure: error: the HTTP rewrite module requires the PCRE library.
```

```bash
# Install the missing library
sudo apt install libpcre3-dev
# Then run ./configure again
```

---

## 6. What `make` Does

`make` reads the `Makefile` that `configure` created and:
- Compiles each source file (`.c` → `.o` object file)
- Links object files into the final binary

```bash
# Compile using 1 core (slow)
make

# Compile using all cores (faster)
make -j$(nproc)          # nproc returns number of CPU cores
make -j4                  # use 4 cores explicitly

# Compilation takes time — for large projects (Linux kernel, gcc) this can be hours
```

---

## 7. What `make install` Does

Copies the compiled binary, libraries, man pages, and config files to the right locations on your system.

```bash
sudo make install

# Usually installs to:
# Binary:  /usr/local/bin/ or /usr/bin/
# Libs:    /usr/local/lib/
# Config:  /usr/local/etc/ or /etc/
# Man:     /usr/local/share/man/
```

---

## 8. Uninstalling Source-Built Software

This is the big downside of building from source — no clean uninstall command:

```bash
# If the project supports it (rare):
sudo make uninstall

# Manual approach — use stow to track files
sudo apt install stow
# Use DESTDIR to install to a tracking dir first

# Better approach: install to a custom prefix
./configure --prefix=/opt/myapp
make -j$(nproc)
sudo make install
# Now everything is isolated in /opt/myapp/
# To uninstall: sudo rm -rf /opt/myapp
```

**Best practice:** Always install custom software to `/opt/softwarename` or `/usr/local` — not directly to `/usr`.

---

## 9. Building Python Packages from Source

Python packages use a different (simpler) system:

```bash
# From PyPI (Python Package Index)
pip3 install requests             # download and build from PyPI

# From source directory
git clone https://github.com/some/project
cd project
pip3 install .                    # or: python3 setup.py install

# Build wheel (distributable binary)
pip3 install build
python3 -m build
ls dist/
```

---

## 10. Real World Example — Custom Python Build

Sometimes you need a specific Python version not in repos:

```bash
# Install build dependencies
sudo apt install -y \
  libssl-dev libffi-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev \
  libncurses5-dev libncursesw5-dev xz-utils

# Download Python source
cd /tmp
wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
tar -xzf Python-3.12.0.tgz
cd Python-3.12.0

# Configure with optimisations
./configure --enable-optimizations --prefix=/opt/python3.12

# Compile (takes 5-10 minutes)
make -j$(nproc)

# Install
sudo make altinstall    # 'altinstall' prevents overwriting system python

# Use it
/opt/python3.12/bin/python3.12 --version
```

---

## 11. Summary

```
When to build from source:
  ✓ Need latest version not in repos
  ✓ Need custom compile flags/modules
  ✓ Software not available as a package

The three steps:
  ./configure [options]    check system, generate Makefile
  make -j$(nproc)          compile with all CPU cores
  sudo make install        copy to system directories

Best practices:
  ✓ Install build tools first (build-essential / Development Tools)
  ✓ Check ./configure --help for available options
  ✓ Install to /opt/softwarename for easy removal
  ✓ Read the README and INSTALL files first
  ✓ Use make altinstall for Python (don't break system Python)

Source-built vs package manager:
  ✓ Use package manager for 95% of software
  ✓ Build from source only when you have a specific reason
  ✓ Package manager updates are automatic; source builds are manual
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← apt and yum](./apt_and_yum.md) &nbsp;|&nbsp; **Next:** [systemd Services →](../08_system_administration/systemd_services.md)

**Related Topics:** [apt and yum](./apt_and_yum.md)
