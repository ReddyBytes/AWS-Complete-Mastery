# Linux — Links and Inodes

> Understanding how Linux actually stores files on disk explains why hard links are instant, why symlinks can break, and why deleting a file doesn't always free up disk space.

---

## 1. The Analogy — Library Books and Catalogue Cards

Imagine a library:

- The **actual book** sitting on a shelf = the file's data on disk
- The **catalogue card** pointing to that book's shelf location = an **inode**
- A **copy of that catalogue card** placed elsewhere = a **hard link**
- A **sticky note saying "go look in section B"** = a **symbolic (soft) link**

You can have multiple catalogue cards pointing to the same book. Removing one card doesn't remove the book — the book only disappears when the last card is removed.

---

## 2. What Is an Inode?

When Linux stores a file, it stores two things separately:

1. **The data** — the actual file contents, stored in data blocks on disk
2. **The metadata** — inode (Index Node) — a small record containing:

```
Inode contains:
──────────────────────────────────────────────
  File type          (regular file, directory, link)
  Permissions        (rwxr-xr-x)
  Owner              (user ID, group ID)
  Size               (bytes)
  Timestamps         (created, modified, accessed)
  Link count         (how many directory entries point here)
  Pointer to data    (where on disk the actual data lives)

Inode does NOT contain:
──────────────────────────────────────────────
  The filename       (that's stored in the directory)
```

The filename is stored in the **directory**, which maps name → inode number. That's the key insight.

```bash
# See inode numbers
ls -li

# Output:
# 2621442 -rw-r--r-- 1 alice alice 1234 Jan 15 config.yaml
# ^inode     ^link count
```

---

## 3. Hard Links

A **hard link** is just another directory entry pointing to the **same inode** (same data on disk).

```bash
# Create a hard link
ln original.txt hardlink.txt

# Both now point to the same inode
ls -li original.txt hardlink.txt
# 2621442 -rw-r--r-- 2 alice alice 1234 Jan 15 original.txt
# 2621442 -rw-r--r-- 2 alice alice 1234 Jan 15 hardlink.txt
# ^same inode!         ^link count is now 2
```

**What this means:**

```
Directory:
  "original.txt"  → inode 2621442
  "hardlink.txt"  → inode 2621442   (same inode!)
                         ↓
                   Data on Disk
```

- Editing either file changes both (they ARE the same file)
- Deleting `original.txt` does NOT delete the data — `hardlink.txt` still has a reference
- Data is only deleted when link count reaches 0

```bash
# Verify they share the same inode
stat original.txt
stat hardlink.txt

# Delete the original — data still accessible via hard link
rm original.txt
cat hardlink.txt    # still works!
```

**Limitations of hard links:**
- Cannot hard link across filesystems (different disks)
- Cannot hard link to directories (would create loops)

---

## 4. Symbolic (Soft) Links

A **symlink** is a file that contains a **path** to another file. It's a shortcut or alias.

```bash
# Create a symlink
ln -s /usr/local/nginx/bin/nginx /usr/bin/nginx

# Create a symlink to a directory
ln -s /var/www/html /home/alice/website

# List symlinks (shows -> target)
ls -la /usr/bin/nginx
# lrwxrwxrwx 1 root root 26 Jan 15 nginx -> /usr/local/nginx/bin/nginx
# ^l = symlink
```

**What this means:**

```
"nginx" symlink → contains path "/usr/local/nginx/bin/nginx"
                            ↓
                  separate inode for nginx binary
                            ↓
                     Data on Disk
```

---

## 5. Hard Links vs Symlinks — Side by Side

```
                    Hard Link           Symbolic Link
──────────────────────────────────────────────────────
What it is          Another name for    A file containing
                    the same inode      a path to another file

Cross filesystem?   No                  Yes
Link to directory?  No                  Yes
If target deleted   Still works         Broken link (dangling)
Size                Same as original    Very small (just a path)
Inode               Same as original    Different inode

Use when            You need a true     You need a shortcut/
                    alias on same disk  alias across the system
```

---

## 6. Real World Uses

### Symlinks in Production

```bash
# Web server deployment — zero-downtime swap
/var/www/
├── myapp_v1/           ← old version
├── myapp_v2/           ← new version
└── current -> myapp_v2 ← symlink (nginx serves from here)

# Deploy new version:
ln -sfn /var/www/myapp_v3 /var/www/current
# nginx immediately serves new version, no restart needed

# Rollback:
ln -sfn /var/www/myapp_v2 /var/www/current
```

### Symlinks for Config Management

```bash
# Dotfiles setup — keep configs in git, symlink to home
ln -s ~/dotfiles/.bashrc ~/.bashrc
ln -s ~/dotfiles/.vimrc ~/.vimrc
ln -s ~/dotfiles/.gitconfig ~/.gitconfig
```

### Why `rm` Doesn't Always Free Disk Space

```bash
# A log file being actively written by nginx
rm /var/log/nginx/access.log

# Disk space is NOT freed yet!
# The nginx process still has the file open (another reference)
# The inode's link count is 0, but open file handles keep data alive

# To actually free space, you need to restart nginx (close its file handle)
sudo systemctl restart nginx
```

This is why `df -h` sometimes shows high disk usage even after deleting files. Check with:
```bash
lsof | grep deleted    # list files that are deleted but still open
```

---

## 7. Checking and Managing Inodes

```bash
# Check inode usage (running out of inodes = can't create files!)
df -i

# Find the inode number of a file
ls -li filename.txt
stat filename.txt

# Find all hard links to a file
find / -inum 2621442    # replace with actual inode number

# Find broken symlinks
find /etc -xtype l      # symlinks whose target doesn't exist
```

---

## 8. Summary

```
Inode:
  ✓ Stores all metadata about a file (permissions, size, owner)
  ✓ Does NOT store the filename
  ✓ The filename → inode mapping lives in the directory

Hard link:
  ✓ Another directory entry pointing to the same inode
  ✓ Deleting one doesn't delete the data
  ✓ Cannot cross filesystems or link to directories
  ✓ Created with: ln source target

Symbolic link:
  ✓ A file containing a path to another file
  ✓ Can cross filesystems and point to directories
  ✓ Breaks if the target is deleted (dangling link)
  ✓ Created with: ln -s source target

Real world:
  ✓ Use symlinks for zero-downtime deployments (current -> v3)
  ✓ Use symlinks for dotfiles management
  ✓ Hard links useful to prevent accidental data loss
  ✓ df -i to check inode exhaustion
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← File Operations](./file_operations.md) &nbsp;|&nbsp; **Next:** [Shell Commands →](../03_shell_basics/commands.md)

**Related Topics:** [Directory Structure](./directory_structure.md) · [File Operations](./file_operations.md)

---

## 📝 Practice Questions

- 📝 [Q44 · inodes](../linux_practice_questions_100.md#q44--normal--inodes)
- 📝 [Q45 · hard-vs-soft-links](../linux_practice_questions_100.md#q45--normal--hard-vs-soft-links)
- 📝 [Q79 · compare-hard-soft-links](../linux_practice_questions_100.md#q79--interview--compare-hard-soft-links)
- 📝 [Q87 · compare-hard-links-vs-copy](../linux_practice_questions_100.md#q87--interview--compare-hard-links-vs-copy)
- 📝 [Q94 · debug-broken-symlink](../linux_practice_questions_100.md#q94--debug--debug-broken-symlink)
- 📝 [Q100 · edge-case-inode-full](../linux_practice_questions_100.md#q100--critical--edge-case-inode-full)

