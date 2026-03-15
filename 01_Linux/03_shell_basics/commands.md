# Linux — Essential Shell Commands

> These are the commands you'll type hundreds of times a week. Learn them once, use them forever.

---

## 1. The Shell — Your Conversation with Linux

The shell is a text-based conversation. You type a command, Linux responds.

```
You type:    ls -lh /var/log
Linux says:  [list of log files with sizes]
```

Every command follows this pattern:
```
command  [options]  [arguments]
   ↓         ↓          ↓
  ls        -lh      /var/log
  cp        -r       source/ dest/
  grep      -i       "error" /var/log/syslog
```

---

## 2. Navigation

```bash
pwd                     # Where am I? (Print Working Directory)
ls                      # What's here?
ls -la                  # What's here including hidden files?
ls -lh                  # What's here with human-readable sizes?
cd /var/log             # Go to /var/log
cd ~                    # Go home
cd ..                   # Go up one level
cd -                    # Go back to previous directory
tree                    # Show directory tree (install: apt install tree)
```

---

## 3. Viewing Files

```bash
cat file.txt            # Print entire file
head -20 file.txt       # First 20 lines
tail -20 file.txt       # Last 20 lines
tail -f app.log         # Follow live (Ctrl+C to stop)
less file.txt           # Scroll through (q to quit, /word to search)
grep "error" file.txt   # Find lines containing "error"
wc -l file.txt          # Count lines
```

---

## 4. Creating and Editing

```bash
touch newfile.txt               # Create empty file
mkdir logs                      # Create directory
mkdir -p a/b/c                  # Create nested directories
echo "text" > file.txt          # Create file with content (overwrites)
echo "more text" >> file.txt    # Append to file
nano file.txt                   # Edit with nano (beginner-friendly)
vim file.txt                    # Edit with vim (powerful)
```

---

## 5. Copying, Moving, Deleting

```bash
cp file.txt copy.txt            # Copy file
cp -r dir/ dir_backup/          # Copy directory
mv old.txt new.txt              # Rename file
mv file.txt /tmp/               # Move to /tmp
rm file.txt                     # Delete file
rm -rf old_dir/                 # Delete directory (no undo!)
```

---

## 6. Searching

```bash
# Find files
find /etc -name "*.conf"                 # find config files
find /var/log -name "*.log" -mtime -1    # modified in last day
find / -size +100M                       # files over 100MB
find /home -type d                       # directories only

# Search inside files
grep "ERROR" app.log                     # find lines with ERROR
grep -i "error" app.log                  # case insensitive
grep -r "database_url" /etc/             # search recursively
grep -n "timeout" config.yaml            # show line numbers
grep -v "DEBUG" app.log                  # lines NOT containing DEBUG
grep -c "404" access.log                 # count matching lines
```

---

## 7. System Information

```bash
# Who am I?
whoami                  # current username
id                      # user ID, group IDs
hostname                # machine name

# What's the OS?
uname -a                # kernel and system info
cat /etc/os-release     # OS name and version
lsb_release -a          # detailed Linux version

# What's running?
top                     # interactive process viewer (q to quit)
htop                    # better top (install: apt install htop)
ps aux                  # list all processes
ps aux | grep nginx     # find nginx processes

# How long has it been running?
uptime                  # uptime + load averages

# Hardware info
nproc                   # number of CPU cores
free -h                 # RAM usage
lscpu                   # CPU details
lsblk                   # disk layout
```

---

## 8. Disk and Memory

```bash
df -h                   # disk space on all mounted filesystems
du -sh /var/log/        # size of /var/log directory
du -sh /var/log/*       # size of each item inside /var/log
free -h                 # RAM and swap usage

# Find what's eating disk
du -sh /* 2>/dev/null | sort -rh | head -10   # top 10 largest dirs
```

---

## 9. Network Checks

```bash
ping google.com                 # is the network working?
ping -c 4 google.com            # send exactly 4 pings
curl https://example.com        # make an HTTP request
curl -I https://example.com     # just response headers
wget https://example.com/file   # download a file
ssh user@server-ip              # connect to remote server
```

---

## 10. Getting Help

```bash
man ls              # full manual for ls (q to quit)
man grep            # manual for grep
ls --help           # quick help for ls
grep --help         # quick help for grep
type ls             # is this a command, alias, or built-in?
which python3       # where is python3 installed?
whereis nginx       # find nginx binary + man pages
```

---

## 11. History and Shortcuts

```bash
history             # show all past commands
history | grep ssh  # find previous ssh commands
!!                  # run last command again
!ssh                # run last command starting with "ssh"
Ctrl+R              # search command history interactively
Ctrl+C              # cancel running command
Ctrl+L              # clear screen (same as `clear`)
Ctrl+A              # jump to start of line
Ctrl+E              # jump to end of line
Tab                 # autocomplete (press twice for options)
```

---

## 12. Chaining Commands

```bash
# Run second command only if first succeeds
mkdir logs && cd logs

# Run second command regardless
mkdir logs; echo "done"

# Run second command only if first FAILS
mkdir logs || echo "logs already exists"
```

---

## 13. Real World Cheat Sheet

```bash
# Check why server is slow
top                           # see CPU/memory usage
df -h                         # check disk space
tail -f /var/log/syslog       # watch system logs

# Quickly find a config
find /etc -name "*.conf" | grep nginx
grep -r "listen 80" /etc/nginx/

# How many 404 errors today?
grep "404" /var/log/nginx/access.log | wc -l

# What process is using port 80?
ss -tlnp | grep :80

# Free up disk space (find large files)
du -sh /var/log/* | sort -rh | head -5
```

---

## 14. Summary

```
Navigation:   pwd, ls, cd
Viewing:      cat, head, tail -f, less, grep
Creating:     touch, mkdir -p, echo >, nano
Copying:      cp -r, mv, rm -rf
Searching:    find, grep -r
System info:  whoami, uname -a, top, df -h, free -h
Help:         man, --help, which
Shortcuts:    Tab, Ctrl+R, !!, history
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Links and Inodes](../02_filesystem/links_and_inodes.md) &nbsp;|&nbsp; **Next:** [Pipes and Redirection →](./pipes_and_redirection.md)

**Related Topics:** [Pipes and Redirection](./pipes_and_redirection.md) · [Text Processing](./text_processing.md)
