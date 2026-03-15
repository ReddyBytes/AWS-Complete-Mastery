# Linux — Pipes and Redirection

> Pipes and redirection are what transform individual commands into powerful one-liners. This is where Linux's "everything is a file" philosophy pays off.

---

## 1. The Analogy — Kitchen Workstations

Imagine a kitchen assembly line:

```
Chopper → Mixer → Fryer → Plater → Customer
```

Each station takes input, does one thing, and passes output to the next. No station cares what came before — it just processes what arrives.

**Linux pipes work exactly this way:**

```bash
cat access.log | grep "404" | sort | uniq -c | sort -rn | head -10
```

```
cat      →  grep   →  sort  →  uniq -c  →  sort -rn  →  head
(read)      (filter)   (sort)   (count)     (sort by    (top 10)
                                             count)
```

Each command does one thing. Together they solve complex problems.

---

## 2. The Three Standard Streams

Every Linux process has three streams:

```
                    ┌──────────────┐
stdin  ──(0)──►    │              │ ──(1)──► stdout
                   │   Program    │
stderr ◄──(2)──    │              │
                   └──────────────┘
```

| Stream | Number | Default | Description |
|--------|--------|---------|-------------|
| **stdin** | 0 | Keyboard | Input the program reads |
| **stdout** | 1 | Terminal | Normal output |
| **stderr** | 2 | Terminal | Error messages |

Understanding these three is the key to everything else.

---

## 3. The Pipe Operator `|`

The pipe `|` connects stdout of one command to stdin of the next.

```bash
# Without pipe — two separate steps
ls /etc > /tmp/list.txt
grep "nginx" /tmp/list.txt

# With pipe — one step, no temp file
ls /etc | grep "nginx"
```

### Real World Pipe Examples

```bash
# How many processes are running?
ps aux | wc -l

# Find all users logged in
who | sort

# Top 5 largest files in /var/log
du -sh /var/log/* | sort -rh | head -5

# How many 404 errors in the last hour?
grep "404" /var/log/nginx/access.log | wc -l

# Find which IPs hit your server most
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Find all running Python processes
ps aux | grep python | grep -v grep

# Watch error count rise in real time
watch -n 1 'grep ERROR /var/log/app.log | wc -l'
```

---

## 4. Output Redirection `>` and `>>`

Redirect stdout to a file instead of the terminal.

```bash
# Write to a file (OVERWRITES existing content)
echo "Hello" > greeting.txt
ls /etc > file_list.txt

# Append to a file (adds to end, preserves existing content)
echo "First line" > log.txt
echo "Second line" >> log.txt
echo "Third line" >> log.txt

# Redirect both stdout and stderr to a file
command > output.txt 2>&1

# Common in cron jobs (silence all output)
/usr/local/bin/backup.sh > /dev/null 2>&1
```

**The `/dev/null` trick:**
```bash
# /dev/null is the black hole — discard any output
ls -la / > /dev/null          # discard stdout
command 2> /dev/null          # discard errors only
command > /dev/null 2>&1      # discard everything
```

---

## 5. Input Redirection `<`

Send file contents as stdin to a command.

```bash
# Feed a file as input to a command
sort < names.txt

# Same as:
cat names.txt | sort

# Very useful for database imports
mysql -u root -p mydb < backup.sql

# Count words in a file
wc -w < essay.txt
```

---

## 6. Here Document `<<`

Write multi-line input directly in the shell.

```bash
# Create a file with multi-line content
cat > config.txt << 'EOF'
server_name = myapp
port = 8080
debug = false
log_level = info
EOF

# Send multi-line input to a command
mysql -u root -p << 'EOF'
CREATE DATABASE myapp;
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON myapp.* TO 'appuser'@'localhost';
EOF
```

---

## 7. Stderr Redirection `2>`

```bash
# Redirect errors to a file, show normal output
find / -name "*.conf" 2> /tmp/errors.txt

# Redirect errors to a different file than stdout
command > output.txt 2> errors.txt

# Redirect errors to same place as stdout
command > all_output.txt 2>&1

# The order matters! This is WRONG (stderr not redirected):
command 2>&1 > output.txt    # WRONG — 2>&1 runs before >

# This is CORRECT:
command > output.txt 2>&1    # RIGHT — stdout redirected first, then stderr joins it
```

---

## 8. `tee` — Fork Output to Screen AND File

```bash
# See output on screen AND save to file simultaneously
./deploy.sh | tee deploy.log

# Append to existing file
./test.sh | tee -a test.log

# Send to file and pipe to another command
command | tee output.txt | grep ERROR
```

**Real world use:** Running deployments where you want to see output live AND keep a log.

```bash
ansible-playbook deploy.yml | tee /var/log/deploy_$(date +%Y%m%d).log
```

---

## 9. Process Substitution `<()`

Treat command output as a file:

```bash
# Compare output of two commands as if they were files
diff <(ls dir1/) <(ls dir2/)

# Compare running config vs saved config
diff <(nginx -T 2>/dev/null) /etc/nginx/nginx.conf
```

---

## 10. Building Real One-Liners

**Find the top 10 IPs attacking your server:**
```bash
grep "Failed password" /var/log/auth.log \
  | awk '{print $11}' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -10
```

**Find all processes using more than 10% CPU:**
```bash
ps aux | awk '$3 > 10 {print $0}'
```

**Count HTTP status codes in nginx log:**
```bash
awk '{print $9}' /var/log/nginx/access.log \
  | sort \
  | uniq -c \
  | sort -rn
```

**Find all config files changed in the last day:**
```bash
find /etc -name "*.conf" -mtime -1 | xargs ls -la
```

**Watch disk usage every 2 seconds:**
```bash
watch -n 2 'df -h | grep -v tmpfs'
```

---

## 11. Summary

```
|    Pipe — connect stdout of one command to stdin of next
>    Redirect stdout to file (overwrite)
>>   Redirect stdout to file (append)
<    Redirect file to stdin
2>   Redirect stderr to file
2>&1 Merge stderr into stdout
tee  Write to both file and stdout

Useful patterns:
  command | grep pattern       filter output
  command | wc -l              count lines
  command | sort | uniq -c     count unique items
  command > output.txt 2>&1    capture everything to file
  command > /dev/null 2>&1     silence everything
  command | tee log.txt        see output + save it
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Shell Commands](./commands.md) &nbsp;|&nbsp; **Next:** [Text Processing →](./text_processing.md)

**Related Topics:** [Shell Commands](./commands.md) · [Text Processing](./text_processing.md)
