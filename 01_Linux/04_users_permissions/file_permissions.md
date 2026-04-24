# Linux — File Permissions

> Every file in Linux has exactly three questions answered: who can read it, who can write it, who can execute it. Understanding this protects your systems.

---

## 1. The Analogy — A Gym Locker Room

Imagine a gym:

- **Owner** — the person who rented the locker. They have full access.
- **Group** — gym members. Maybe they can see the locker number but not open it.
- **Others** — random people off the street. They get the least access.

For every file in Linux, these same three parties exist: the owner, the owner's group, and everyone else.

---

## 2. Reading Permission Output

```bash
ls -la /etc/nginx/nginx.conf
```

```
-rw-r--r-- 1 root root 2457 Jan 15 nginx.conf
│└──┘└──┘└──┘
│  │   │   └── Others can: read only
│  │   └─────── Group can: read only
│  └─────────── Owner can: read + write
└────────────── File type: - = file, d = directory, l = symlink
```

The 10-character permission string broken down:

```
- r w x r - x r - -
│ │ │ │ │ │ │ │ │ │
│ └─────┘ └─────┘ └─────┘
│  Owner   Group   Others
│
└── Type: - file, d dir, l symlink, b block device
```

---

## 3. The Three Permissions

| Symbol | Meaning | On a file | On a directory |
|--------|---------|-----------|----------------|
| `r` | Read | View file contents | List directory contents |
| `w` | Write | Modify file contents | Create/delete files inside |
| `x` | Execute | Run as a program | Enter the directory with `cd` |
| `-` | Denied | No permission | No permission |

**Important:** To `cd` into a directory, you need `x` permission on it. To list it, you need `r`. To create files inside, you need `w`.

---

## 4. Octal (Numeric) Permissions

Each permission has a numeric value:

```
r = 4
w = 2
x = 1
- = 0

Add them up for each group:
rwx = 4+2+1 = 7
rw- = 4+2+0 = 6
r-x = 4+0+1 = 5
r-- = 4+0+0 = 4
--- = 0+0+0 = 0
```

So `chmod 755` means:
```
7 = rwx  (owner: full)
5 = r-x  (group: read + execute)
5 = r-x  (others: read + execute)
```

**Common permission values:**

| Octal | Symbolic | Use case |
|-------|----------|----------|
| `755` | rwxr-xr-x | Executable scripts, public directories |
| `644` | rw-r--r-- | Regular files, config files |
| `600` | rw------- | Private keys, passwords |
| `700` | rwx------ | Private scripts, restricted dirs |
| `777` | rwxrwxrwx | World-writable (avoid in production!) |
| `000` | --------- | No access for anyone |

---

## 5. `chmod` — Change Permissions

### Symbolic Mode

```bash
# Add execute for owner
chmod u+x deploy.sh

# Remove write from group
chmod g-w config.yaml

# Add read for others
chmod o+r README.md

# Set exact permissions for all (u=user, g=group, o=others)
chmod u=rw,g=r,o=r config.yaml

# Add execute for everyone
chmod +x script.sh

# Remove write for everyone except owner
chmod go-w important.txt
```

### Numeric Mode

```bash
# Owner: rwx, Group: r-x, Others: r-x
chmod 755 script.sh

# Owner: rw, Group: r, Others: r
chmod 644 config.yaml

# Owner only (SSH private key)
chmod 600 ~/.ssh/id_rsa

# Recursive — apply to directory and all contents
chmod -R 755 /var/www/html/
```

---

## 6. `chown` — Change Owner

```bash
# Change owner
sudo chown alice file.txt

# Change owner and group
sudo chown alice:developers file.txt

# Change just the group
sudo chown :developers file.txt
# or
sudo chgrp developers file.txt

# Recursive — change owner of directory and all contents
sudo chown -R www-data:www-data /var/www/html/

# Change owner to match another file
sudo chown --reference=reference.txt target.txt
```

---

## 7. Real World Permission Scenarios

### Web Server Files

```bash
# Nginx/Apache serving static files
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/       # dirs: can cd into them
sudo find /var/www/html -type f -exec chmod 644 {} \;   # files: readable
```

### SSH Keys

```bash
# SSH private key — MUST be 600 or SSH refuses to use it
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub      # public key can be shared
chmod 700 ~/.ssh/                # .ssh dir: owner only
chmod 600 ~/.ssh/authorized_keys # only owner can read
```

### Application Config with Secrets

```bash
# Config file with database password
sudo chown myapp:myapp /etc/myapp/config.yaml
sudo chmod 600 /etc/myapp/config.yaml    # only the app user can read it
```

### Shared Team Directory

```bash
# Create shared directory
sudo mkdir /data/team-project
sudo chown :developers /data/team-project
sudo chmod 775 /data/team-project        # developers can write
sudo chmod g+s /data/team-project        # setgid: new files inherit group
```

---

## 8. Special Permissions

### `setuid` (s on user execute)

File runs with the **owner's** permissions, not the caller's:

```bash
ls -la /usr/bin/passwd
# -rwsr-xr-x 1 root root ... /usr/bin/passwd
#     ^s = setuid

# passwd is owned by root but anyone can run it
# It runs WITH root permissions so it can edit /etc/shadow
```

### `setgid` (s on group execute)

Files created in a `setgid` directory **inherit the directory's group**:

```bash
sudo chmod g+s /data/team/     # setgid on directory
# New files created here get "developers" group automatically
```

### Sticky Bit (t on others execute)

Files in a sticky directory can only be deleted by **their own owner**:

```bash
ls -la /tmp
# drwxrwxrwt ... /tmp
#          ^t = sticky bit

# Anyone can write to /tmp
# But you can only delete YOUR OWN files
```

---

## 9. `umask` — Default Permissions

`umask` defines what permissions are **removed** from newly created files:

```bash
umask           # view current umask (usually 022)

# umask 022 means:
# New files:  666 - 022 = 644 (rw-r--r--)
# New dirs:   777 - 022 = 755 (rwxr-xr-x)

# Set umask for more private files
umask 027       # new files: 640, new dirs: 750

# Set in ~/.bashrc for permanent effect
echo "umask 022" >> ~/.bashrc
```

---

## 10. Summary

```
Permission string: -rwxr-xr-x
  Position 1:     file type (- = file, d = dir, l = link)
  Positions 2-4:  owner permissions (rwx)
  Positions 5-7:  group permissions (r-x)
  Positions 8-10: others permissions (r-x)

chmod:
  chmod 755 file      numeric: rwx r-x r-x
  chmod u+x file      symbolic: add execute for owner
  chmod -R 755 dir/   recursive

chown:
  chown user file         change owner
  chown user:group file   change owner and group
  chown -R user dir/      recursive

Common values:
  600 → SSH keys, secrets (owner read/write only)
  644 → Regular files (owner rw, world r)
  755 → Scripts, directories (owner rwx, world rx)
  777 → Avoid in production (everyone full access)
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Users and Groups](./users_and_groups.md) &nbsp;|&nbsp; **Next:** [Sudo and Root →](./sudo_and_root.md)

**Related Topics:** [Users and Groups](./users_and_groups.md) · [Sudo and Root](./sudo_and_root.md)

---

## 📝 Practice Questions

- 📝 [Q10 · file-permissions-read](../linux_practice_questions_100.md#q10--normal--file-permissions-read)
- 📝 [Q11 · chmod](../linux_practice_questions_100.md#q11--normal--chmod)
- 📝 [Q12 · chown](../linux_practice_questions_100.md#q12--normal--chown)
- 📝 [Q25 · file-ownership](../linux_practice_questions_100.md#q25--critical--file-ownership)
- 📝 [Q34 · umask](../linux_practice_questions_100.md#q34--normal--umask)
- 📝 [Q35 · special-permissions](../linux_practice_questions_100.md#q35--normal--special-permissions)
- 📝 [Q36 · acl-permissions](../linux_practice_questions_100.md#q36--normal--acl-permissions)
- 📝 [Q76 · explain-permissions-junior](../linux_practice_questions_100.md#q76--interview--explain-permissions-junior)
- 📝 [Q91 · predict-permissions](../linux_practice_questions_100.md#q91--logical--predict-permissions)

