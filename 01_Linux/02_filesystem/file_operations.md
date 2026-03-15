# Linux — File Operations

> Files are the currency of Linux. Master creating, copying, moving, and deleting files — and you'll spend 80% less time fighting the terminal.

---

## 1. The Analogy — A Physical Filing Room

Think of the Linux filesystem as a physical filing room:

- **Directories** are filing cabinets and folders
- **Files** are sheets of paper
- **Commands** are the actions you perform: put a new sheet in, copy a sheet, move it to another folder, shred it

The only difference: in Linux, you type the action instead of physically doing it.

---

## 2. Viewing Files and Directories

```bash
# List files in current directory
ls

# Long format — shows permissions, owner, size, date
ls -l

# Include hidden files (starting with .)
ls -la

# Human-readable file sizes (KB, MB, GB)
ls -lh

# Sort by modification time (newest first)
ls -lt

# List a specific directory
ls /etc/nginx/
```

Example output of `ls -lh`:
```
-rw-r--r-- 1 alice alice 2.4K Jan 15 09:30 config.yaml
drwxr-xr-x 2 alice alice 4.0K Jan 14 22:10 logs/
-rwxr-xr-x 1 alice alice  18K Jan 13 11:00 deploy.sh
```

- First character: `-` = file, `d` = directory, `l` = symbolic link
- Then permissions, owner, size, date, name

---

## 3. Creating Files and Directories

```bash
# Create an empty file
touch notes.txt

# Create multiple files at once
touch file1.txt file2.txt file3.txt

# Create a directory
mkdir logs

# Create nested directories (all in one command)
mkdir -p projects/webapp/src

# Create a file with content immediately
echo "Hello World" > greeting.txt

# Append to a file
echo "Second line" >> greeting.txt
```

---

## 4. Reading File Contents

```bash
# Print entire file to screen
cat config.yaml

# Print with line numbers
cat -n config.yaml

# View large files page by page (q to quit)
less /var/log/syslog

# View top 10 lines
head access.log

# View top 20 lines
head -20 access.log

# View last 10 lines
tail error.log

# View last 50 lines
tail -50 error.log

# Watch a file in real-time (perfect for logs)
tail -f /var/log/nginx/access.log
```

**Real world tip:** `tail -f` is the most used command when debugging production issues. Open a second terminal, run it, and watch logs roll in as you reproduce a bug.

---

## 5. Copying Files and Directories

```bash
# Copy a file
cp source.txt destination.txt

# Copy to a different directory
cp config.yaml /etc/myapp/

# Copy and keep original name, just change location
cp deploy.sh /usr/local/bin/

# Copy a directory and everything inside it (-r = recursive)
cp -r logs/ logs_backup/

# Copy and show progress
cp -rv large_folder/ backup/

# Copy with preservation of timestamps and permissions
cp -a source_dir/ dest_dir/
```

**Real world example** — backup a config before changing it:
```bash
# Always back up before editing!
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
sudo nano /etc/nginx/nginx.conf
# If something breaks: sudo cp /etc/nginx/nginx.conf.bak /etc/nginx/nginx.conf
```

---

## 6. Moving and Renaming Files

`mv` does both — move a file to a different location AND rename it:

```bash
# Rename a file
mv old_name.txt new_name.txt

# Move a file to a different directory
mv report.pdf /home/alice/documents/

# Move and rename at the same time
mv temp_log.txt /var/log/app/access.log

# Move a directory
mv old_dir/ new_dir/

# Move multiple files into a directory
mv file1.txt file2.txt file3.txt /tmp/archive/
```

---

## 7. Deleting Files and Directories

```bash
# Delete a file
rm old_report.txt

# Delete without confirmation prompt
rm -f old_report.txt

# Delete a directory and everything inside it
rm -rf old_logs/

# Interactive delete — asks before each file (safer)
rm -i *.txt

# Delete all .log files in current directory
rm *.log
```

> **Warning:** `rm -rf` is permanent. There is no Recycle Bin. No Ctrl+Z.
> Before running `rm -rf some_dir/`, double-check the path with `ls some_dir/` first.

---

## 8. Finding Files

```bash
# Find a file by name
find /etc -name "nginx.conf"

# Find all .log files in /var
find /var -name "*.log"

# Find files modified in the last 24 hours
find /var/log -mtime -1

# Find files larger than 100MB
find / -size +100M

# Find and delete all .tmp files
find /tmp -name "*.tmp" -delete

# Find directories only
find /home -type d

# Find files only
find /home -type f
```

---

## 9. Checking File Details

```bash
# What type is this file?
file mystery_file

# How big is this file/directory?
du -sh logs/           # size of logs/ directory
du -sh /var/log/*      # size of each item in /var/log
df -h                  # disk space used on all mounts

# When was it last modified?
stat config.yaml       # full details: size, inode, timestamps

# Count lines/words/characters in a file
wc -l access.log       # count lines
wc -w document.txt     # count words
wc -c binary.bin       # count bytes
```

---

## 10. Viewing and Editing Text Files

```bash
# Quick view
cat config.yaml

# Edit with nano (beginner-friendly)
nano config.yaml
# Ctrl+O to save, Ctrl+X to exit

# Edit with vim (powerful, steep learning curve)
vim config.yaml
# i to enter insert mode, Esc to exit, :wq to save and quit, :q! to quit without saving

# Edit with built-in fallback
vi config.yaml         # available on every Linux system
```

---

## 11. Useful File Shortcuts

```bash
# View file without creating it (if it doesn't exist, creates it)
cat > newfile.txt
# Type content, then Ctrl+D to save

# Quick one-liner to create config
cat > /tmp/test.conf << 'EOF'
server_name = myapp
port = 8080
debug = false
EOF

# Concatenate multiple files into one
cat header.txt body.txt footer.txt > full_document.txt

# Compare two files
diff old_config.yaml new_config.yaml

# Sort a file and remove duplicates
sort data.txt | uniq > sorted_data.txt
```

---

## 12. Summary

```bash
# Viewing
ls -lh          # list files with sizes
cat             # print file contents
tail -f         # follow a file in real time
less            # page through large files
find            # locate files

# Creating
touch           # create empty file
mkdir -p        # create directory (with parents)
echo "" >       # create file with content

# Copying / Moving
cp -r           # copy recursively
mv              # move or rename
cp file file.bak  # always backup before editing

# Deleting
rm              # remove file
rm -rf          # remove directory (CAREFUL)

# Info
stat            # full file details
du -sh          # directory size
df -h           # disk space
wc -l           # count lines
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Directory Structure](./directory_structure.md) &nbsp;|&nbsp; **Next:** [Links and Inodes →](./links_and_inodes.md)

**Related Topics:** [Directory Structure](./directory_structure.md) · [Links and Inodes](./links_and_inodes.md)
