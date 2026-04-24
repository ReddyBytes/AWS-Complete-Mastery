# Linux — Text Processing

> `grep`, `awk`, `sed`, `sort`, `uniq` — these five tools handle 90% of all log analysis, data extraction, and config manipulation you'll ever need.

---

## 1. Why Text Processing Matters

In Linux, configuration files, logs, and data are all plain text. The tools that process text are therefore your most powerful diagnostic and automation tools.

```bash
# Real scenario: Find all IPs that got 500 errors today
grep " 500 " /var/log/nginx/access.log \
  | awk '{print $1}' \
  | sort | uniq -c | sort -rn | head -10

# Real scenario: Extract all email addresses from a file
grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' users.csv

# Real scenario: Replace old domain in all configs
sed -i 's/old-domain.com/new-domain.com/g' /etc/nginx/*.conf
```

---

## 2. `grep` — Find Lines Matching a Pattern

`grep` is your first line of defense for searching.

```bash
# Basic search
grep "ERROR" app.log

# Case insensitive
grep -i "error" app.log

# Show line numbers
grep -n "ERROR" app.log

# Show lines NOT matching (invert)
grep -v "DEBUG" app.log

# Count matching lines
grep -c "404" access.log

# Recursive search in directory
grep -r "database_url" /etc/

# Search multiple files
grep "timeout" /etc/nginx/*.conf

# Show 3 lines before and after each match (context)
grep -B 3 -A 3 "CRITICAL" app.log

# Extract only the matching part (not the whole line)
grep -o "ERROR.*" app.log

# Match whole word only
grep -w "fail" app.log   # won't match "failure"
```

### grep with Regular Expressions

```bash
# Lines starting with a date pattern (2024-)
grep "^2024-" app.log

# Lines ending with a status code
grep "200$" access.log

# Match IP address pattern
grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" access.log

# Extract emails
grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' data.txt
```

---

## 3. `awk` — Process Columns of Data

`awk` treats each line as a row and splits it into columns by whitespace. Perfect for structured text like logs.

```bash
# Print the 1st column of every line
awk '{print $1}' access.log

# Print multiple columns
awk '{print $1, $7, $9}' access.log   # IP, URL, status code

# nginx log format: IP - - [date] "method url protocol" status size
# Print IP and status code
awk '{print $1, $9}' /var/log/nginx/access.log

# Filter: print lines where column 9 (status) is 500
awk '$9 == "500" {print $0}' /var/log/nginx/access.log

# Filter: print lines where column 10 (response size) > 10000
awk '$10 > 10000 {print $1, $10}' /var/log/nginx/access.log

# Calculate average response size
awk '{sum += $10; count++} END {print "Average:", sum/count}' access.log

# Count occurrences (like uniq -c but more powerful)
awk '{count[$1]++} END {for (ip in count) print count[ip], ip}' access.log \
  | sort -rn | head -10
```

### `awk` with Custom Delimiter

```bash
# CSV file — use comma as delimiter
awk -F',' '{print $2}' users.csv       # print second column

# /etc/passwd uses : as delimiter
awk -F':' '{print $1, $3}' /etc/passwd   # username and UID

# Key=value config file
awk -F'=' '{print $1}' config.properties  # print all keys
```

---

## 4. `sed` — Find and Replace in Text Streams

`sed` (stream editor) is the king of find-and-replace.

```bash
# Replace first occurrence of "old" with "new" on each line
sed 's/old/new/' file.txt

# Replace ALL occurrences on each line (g = global)
sed 's/old/new/g' file.txt

# Replace and edit the file in place (-i flag)
sed -i 's/old/new/g' file.txt

# Edit in place with backup
sed -i.bak 's/old/new/g' file.txt   # saves original as file.txt.bak

# Delete lines matching a pattern
sed '/DEBUG/d' app.log

# Delete blank lines
sed '/^$/d' file.txt

# Print only matching lines (like grep)
sed -n '/ERROR/p' app.log

# Print lines 5 to 10
sed -n '5,10p' file.txt
```

### Real World `sed` Uses

```bash
# Change port in nginx config
sudo sed -i 's/listen 80/listen 8080/g' /etc/nginx/nginx.conf

# Replace all occurrences of old domain with new domain in all configs
sudo sed -i 's/old-company.com/new-company.com/g' /etc/nginx/*.conf

# Remove all comment lines from a config (lines starting with #)
sed '/^#/d' /etc/someapp/config.conf

# Add a line after a match
sed '/server_name/a\    listen 443 ssl;' nginx.conf
```

---

## 5. `sort` — Sort Lines

```bash
# Sort alphabetically
sort names.txt

# Sort in reverse
sort -r names.txt

# Sort numerically (not alphabetically)
sort -n numbers.txt         # "10" comes after "9", not before "1"

# Sort by column (3rd field, numerically, reverse)
sort -k3 -n -r data.txt

# Sort by disk usage output
du -sh /var/log/* | sort -rh   # -h = human-readable sizes

# Sort IP addresses properly
sort -t. -k1,1n -k2,2n -k3,3n -k4,4n ip_list.txt
```

---

## 6. `uniq` — Remove Duplicate Lines

`uniq` only removes **adjacent** duplicates, so always `sort` first.

```bash
# Remove duplicate lines (must be sorted first)
sort names.txt | uniq

# Count occurrences of each line
sort access.log | uniq -c

# Show only lines that appear more than once
sort app.log | uniq -d

# Show only lines that appear exactly once
sort app.log | uniq -u

# Case insensitive
sort names.txt | uniq -i
```

---

## 7. `cut` — Extract Columns

```bash
# Cut by delimiter — extract 1st and 3rd fields
cut -d',' -f1,3 data.csv

# Cut by character position
cut -c1-10 file.txt          # first 10 characters of each line

# Extract username from /etc/passwd
cut -d':' -f1 /etc/passwd

# Extract just the IP from nginx logs
cut -d' ' -f1 /var/log/nginx/access.log
```

---

## 8. `tr` — Translate or Delete Characters

```bash
# Lowercase to uppercase
echo "hello world" | tr 'a-z' 'A-Z'

# Replace colons with spaces
echo "one:two:three" | tr ':' ' '

# Delete specific characters
echo "hello 123" | tr -d '0-9'    # "hello "

# Squeeze repeated spaces into one
echo "too   many   spaces" | tr -s ' '
```

---

## 9. Combining Tools — Real Log Analysis

```bash
# Top 10 most common error messages
grep "ERROR" app.log \
  | awk '{$1=$2=$3=""; print $0}' \
  | sort | uniq -c | sort -rn | head -10

# Requests per minute over the last hour
grep "$(date +%d/%b/%Y:%H)" /var/log/nginx/access.log \
  | awk '{print $4}' \
  | cut -d: -f2 \
  | sort | uniq -c

# All unique user-agents hitting your server
awk -F'"' '{print $6}' /var/log/nginx/access.log \
  | sort | uniq -c | sort -rn | head -10

# Average response time (if your logs have it)
awk '{sum += $NF; n++} END {print "avg:", sum/n, "ms"}' timing.log

# Find config keys that differ between environments
diff \
  <(grep "=" prod.conf | sort) \
  <(grep "=" staging.conf | sort)
```

---

## 10. Summary

```
grep    Find lines matching a pattern
        -i case insensitive  -v invert  -r recursive  -n line numbers

awk     Process structured columns
        $1 $2 $3 = column 1 2 3
        -F','  = use comma as delimiter

sed     Find and replace in text
        's/old/new/g'   replace all
        -i              edit file in place
        '/pattern/d'    delete matching lines

sort    Sort lines
        -n numeric  -r reverse  -h human-readable  -k column

uniq    Remove/count duplicates (sort first!)
        -c count  -d duplicates only  -u unique only

cut     Extract columns
        -d delimiter  -f field  -c characters

Combine them with pipes | to build powerful one-liners.
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Pipes and Redirection](./pipes_and_redirection.md) &nbsp;|&nbsp; **Next:** [Users and Groups →](../04_users_permissions/users_and_groups.md)

**Related Topics:** [Shell Commands](./commands.md) · [Pipes and Redirection](./pipes_and_redirection.md)

---

## 📝 Practice Questions

- 📝 [Q16 · grep-basics](../linux_practice_questions_100.md#q16--normal--grep-basics)
- 📝 [Q17 · sed-basics](../linux_practice_questions_100.md#q17--normal--sed-basics)
- 📝 [Q18 · awk-basics](../linux_practice_questions_100.md#q18--thinking--awk-basics)
- 📝 [Q57 · text-processing-pipeline](../linux_practice_questions_100.md#q57--normal--text-processing-pipeline)
- 📝 [Q58 · xargs](../linux_practice_questions_100.md#q58--normal--xargs)

