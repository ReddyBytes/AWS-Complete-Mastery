# Linux — Network Commands

> These commands are your diagnostic toolkit for understanding what your server is doing on the network — where it's connected, what ports are open, and whether traffic is flowing.

---

## 1. The Analogy — Network is the Postal System

Think of networking like a postal system:

- **IP address** = your building address
- **Port** = the apartment number inside the building (one IP, many services)
- **Packet** = a letter being delivered
- **ping** = sending a "are you there?" postcard
- **curl** = ordering something and seeing if it arrives

---

## 2. Checking Your Network Interfaces

```bash
# Show all network interfaces and their IPs
ip addr                 # modern command
ip addr show eth0       # just eth0 interface
ip a                    # short form

# Old command (still works)
ifconfig

# Output example:
# eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
#   inet 172.31.45.23/20  ← your private IP
#   inet6 fe80::abc...    ← IPv6

# Quick: what's my IP?
hostname -I             # all IPs
ip addr show eth0 | grep "inet " | awk '{print $2}'
```

---

## 3. `ping` — Is the Host Reachable?

```bash
# Basic ping (press Ctrl+C to stop)
ping google.com

# Send exactly 4 pings
ping -c 4 google.com

# Ping with interval (1 ping per 2 seconds)
ping -i 2 google.com

# Ping local machine (127.0.0.1 = loopback)
ping 127.0.0.1
ping localhost

# Diagnose "no internet":
ping 8.8.8.8          # can I reach Google's DNS? (tests internet)
ping google.com       # can I resolve DNS? (tests DNS)
ping 172.31.0.1       # can I reach my gateway? (tests local network)
```

---

## 4. Checking Open Ports and Connections

### `ss` — Socket Statistics (Modern)

```bash
# Show all listening TCP ports
ss -tlnp

# All listening ports (TCP + UDP)
ss -ulnp

# All established connections
ss -tnp

# Find what's using port 80
ss -tlnp | grep :80

# All connections (listening + established)
ss -anp

# Count connections per state
ss -s
```

### `netstat` (Older, but widely used)

```bash
# Show all listening ports with process names
netstat -tlnp

# Show all connections
netstat -anp

# Show routing table
netstat -r

# Statistics summary
netstat -s
```

### What the columns mean:

```
Proto  Local Address    Foreign Address  State       PID/Program
tcp    0.0.0.0:80      0.0.0.0:*        LISTEN      1234/nginx
tcp    172.31.45.23:22 1.2.3.4:45678   ESTABLISHED 5678/sshd
```

---

## 5. Checking Routes

```bash
# Routing table — where does traffic go?
ip route
route -n            # old command

# Output:
# default via 172.31.0.1 dev eth0    ← default gateway
# 172.31.32.0/20 dev eth0            ← local subnet

# Trace the path packets take to reach a host
traceroute google.com
tracepath google.com    # doesn't need root
mtr google.com          # live traceroute (install with apt)
```

---

## 6. DNS Lookups

```bash
# Look up IP address for a domain
nslookup google.com
dig google.com

# More detailed DNS query
dig google.com ANY           # all record types
dig @8.8.8.8 google.com      # use Google's DNS server
dig google.com MX            # mail records
dig google.com TXT           # text records (SPF, DKIM)

# Reverse lookup: IP → hostname
dig -x 8.8.8.8
nslookup 8.8.8.8

# Check what DNS server you're using
cat /etc/resolv.conf

# Local hostname resolution
cat /etc/hosts               # local overrides
```

---

## 7. `curl` — Make HTTP Requests

```bash
# Basic GET request
curl https://example.com

# Show only response headers
curl -I https://example.com

# Show headers + body
curl -i https://example.com

# POST request with JSON body
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name": "alice"}' \
  https://api.example.com/users

# Download a file
curl -O https://example.com/file.tar.gz

# Download with progress bar
curl -# -O https://example.com/large-file.tar.gz

# Follow redirects
curl -L https://example.com

# Pass auth token
curl -H "Authorization: Bearer mytoken" https://api.example.com/data

# Test your own API locally
curl http://localhost:8080/health
curl http://localhost:8080/api/users | python3 -m json.tool
```

---

## 8. `wget` — Download Files

```bash
# Download a file
wget https://example.com/file.tar.gz

# Download to specific location
wget -O /tmp/app.tar.gz https://example.com/file.tar.gz

# Continue interrupted download
wget -c https://example.com/large-file.tar.gz

# Download in background
wget -b https://example.com/huge-file.tar.gz

# Mirror a website
wget --mirror https://example.com
```

---

## 9. Checking Bandwidth and Traffic

```bash
# How much data is flowing through interfaces?
iftop                        # live bandwidth monitor (sudo apt install iftop)
nethogs                      # per-process bandwidth (sudo apt install nethogs)
nload                        # simple bandwidth graph

# Total data sent/received
ip -s link show eth0         # cumulative stats
cat /proc/net/dev            # raw stats

# Watch network traffic in real time
tcpdump -i eth0              # all traffic (needs root)
tcpdump -i eth0 port 80      # just HTTP traffic
tcpdump -i eth0 host 1.2.3.4 # traffic to/from specific IP
```

---

## 10. Firewall Quick Check

```bash
# Check if firewall is active (Ubuntu/Debian)
sudo ufw status

# Check iptables rules
sudo iptables -L -n -v

# Check if a port is reachable from THIS machine
nc -zv localhost 80          # is port 80 open locally?
nc -zv google.com 443        # is remote port 443 reachable?
```

---

## 11. Real World Diagnostic Workflow

**"Users can't reach the website":**
```bash
# Step 1: Is nginx running?
sudo systemctl status nginx

# Step 2: Is it listening on port 80?
ss -tlnp | grep :80

# Step 3: Can we reach it locally?
curl -I http://localhost

# Step 4: Is the firewall blocking it?
sudo ufw status
sudo iptables -L INPUT -n | grep 80

# Step 5: Is DNS resolving correctly?
dig mywebsite.com

# Step 6: Can we reach it from outside? (use another machine)
curl -I http://my-server-ip
```

---

## 12. Summary

```
IP and interfaces:
  ip addr               show all IPs and interfaces
  hostname -I           quick: my IPs

Connectivity:
  ping -c 4 host        test reachability
  traceroute host       trace the path

Ports and connections:
  ss -tlnp              listening TCP ports + process
  ss -anp               all connections

DNS:
  dig domain            DNS lookup
  cat /etc/resolv.conf  what DNS am I using?

HTTP:
  curl -I url           check response headers
  curl -X POST ...      send POST request
  wget url              download a file

Traffic:
  tcpdump -i eth0 port 80   capture HTTP traffic
  iftop                      live bandwidth
```

---

**[🏠 Back to README](../../README.md)**

**Prev:** [← Jobs and Daemons](../05_processes/jobs_and_daemons.md) &nbsp;|&nbsp; **Next:** [SSH →](./ssh.md)

**Related Topics:** [SSH](./ssh.md) · [Firewall](./firewall.md)
