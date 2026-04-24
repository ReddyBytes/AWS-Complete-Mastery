# Linux — TLS/SSL and openssl

> TLS is the reason you can type a credit card number into a browser and trust that only the bank sees it. It's not magic — it's math, and openssl lets you inspect every part of it.

---

## 1. What TLS Does and Why It Matters

**TLS** (Transport Layer Security, formerly SSL) solves three distinct problems in one protocol:

```
Problem 1: Authentication  — Am I really talking to my bank, or an imposter?
Problem 2: Encryption      — Can anyone intercept and read what I'm sending?
Problem 3: Integrity       — Has anything been modified in transit?
```

The notary analogy makes this concrete. When you sign a legal document, a notary:
1. Checks your ID to confirm who you are (authentication)
2. Witnesses the signing so no one can dispute it (integrity)
3. Seals the document so tampering is obvious (integrity again)

TLS does the same thing for every network connection. The **certificate** is the identity document. The **CA** (Certificate Authority) is the notary. The **handshake** is the moment both parties verify each other's credentials before any data flows.

```
TLS Connection Flow:

  Client                              Server
    │                                   │
    │──── ClientHello (TLS version) ───►│
    │◄─── ServerHello + Certificate ────│
    │     (Server proves identity)       │
    │──── Key Exchange ─────────────────►│
    │     (Both derive shared secret)    │
    │◄═══════ Encrypted Data ══════════►│
    │     (All traffic now encrypted)    │
```

TLS 1.3 (current standard) simplified this — the full handshake takes one round trip.

---

## 2. Key Concepts

### Certificates and Keys

A **certificate** is a public document that says "this server is who it claims to be, and here is its public key." A **private key** is the secret that proves ownership of that certificate.

```
Relationship:
  Private Key (secret, never shared)
      │
      └── used to generate ──► Certificate Signing Request (CSR)
                                    │
                                    └── CA signs it ──► Certificate (public)
```

The private key signs data. Anyone with the certificate's public key can verify the signature — but only the private key holder could have created it.

### Certificate Chain

No browser trusts a single certificate directly. Trust flows from a **Root CA** (built into operating systems and browsers) down through **Intermediate CAs** to the server certificate.

```
Chain of Trust:

  Root CA Certificate                (trusted by OS/browser, self-signed)
      │  signed
      ▼
  Intermediate CA Certificate        (issued by Root, signs end-entity certs)
      │  signed
      ▼
  Server Certificate                 (your cert for api.example.com)
      │  presented by
      ▼
  Your Server (example.com)
```

When a server presents an incomplete chain (missing the intermediate), browsers show "certificate verify failed" even though the server cert itself is valid.

### File Formats

| Extension | Content | Notes |
|---|---|---|
| `.pem` | Base64-encoded, human-readable | Most common on Linux. Can contain cert, key, or both. |
| `.crt` | Usually PEM-encoded certificate | Same as `.pem` when it holds a cert |
| `.key` | Usually PEM-encoded private key | Keep permissions at `600` |
| `.csr` | Certificate Signing Request | Send this to CA; keep the key |
| `.p12` / `.pfx` | Binary format, holds cert + key + chain | Used on Windows, Java, some AWS exports |
| `.der` | Binary DER-encoded certificate | Used on Java and some embedded systems |

```bash
# Convert PEM to DER
openssl x509 -in cert.pem -outform DER -out cert.der

# Convert P12 to PEM
openssl pkcs12 -in bundle.p12 -out bundle.pem -nodes
```

### Certificate Fields

```bash
openssl x509 -in cert.pem -text -noout | grep -A2 "Subject\|SAN\|Validity\|Key Usage"
```

```
Subject: CN=api.example.com           ← Common Name (legacy, less important now)
Subject Alternative Names (SAN):      ← The field browsers actually check
  DNS: api.example.com
  DNS: www.example.com
  DNS: *.example.com                  ← wildcard — covers one subdomain level
Validity:
  Not Before: Jan  1 00:00:00 2025
  Not After : Jan  1 00:00:00 2026
Key Usage: Digital Signature, Key Encipherment
```

Modern browsers ignore `CN` entirely and only validate against **SAN** entries. A certificate without SANs will fail in Chrome, Firefox, and curl.

---

## 3. openssl Essentials

### Check Your openssl Version

```bash
openssl version -a          # version, build date, and compile-time options
```

### Inspect a Live Server's Certificate

This is the most-used openssl command in production debugging:

```bash
openssl s_client -connect api.example.com:443

# More readable output — just the cert details
openssl s_client -connect api.example.com:443 < /dev/null 2>/dev/null \
  | openssl x509 -text -noout
```

Key things to look for in the output:

```
Verify return code: 0 (ok)          ← full chain verified successfully
Verify return code: 21 (unable to verify the first certificate)  ← missing intermediate

Certificate chain
 0 s:CN = api.example.com           ← server certificate (depth 0)
 1 s:CN = Example Intermediate CA   ← intermediate CA (depth 1)
 2 s:CN = Example Root CA           ← root CA (depth 2)
```

### Show the Full Certificate Chain

```bash
openssl s_client -connect api.example.com:443 -showcerts
# ← prints every certificate in the chain, in PEM format
```

### Read a Certificate File

```bash
openssl x509 -in cert.pem -text -noout     # full certificate details
openssl x509 -in cert.pem -subject -noout  # just the subject
openssl x509 -in cert.pem -issuer -noout   # who signed it
openssl x509 -in cert.pem -enddate -noout  # expiry date only
openssl x509 -in cert.pem -fingerprint -noout  # SHA fingerprint
```

### Verify a Certificate Chain

```bash
# Verify server cert against a CA bundle
openssl verify -CAfile ca-bundle.crt server.crt

# Verify with intermediate CA explicitly
openssl verify -CAfile root-ca.crt -untrusted intermediate.crt server.crt
```

A successful verification returns `server.crt: OK`.

---

## 4. Generating Keys and CSRs

### Generate a Private Key

```bash
# RSA 4096-bit key (strong, compatible)
openssl genrsa -out private.key 4096

# RSA 2048-bit key (acceptable, faster)
openssl genrsa -out private.key 2048

# Encrypted private key (password-protected)
openssl genrsa -aes256 -out private.key 4096
# ← prompts for passphrase; required on every server start
# ← omit -aes256 for automated services (no interactive passphrase)

# View key details
openssl rsa -in private.key -text -noout
```

Set permissions immediately after generating:

```bash
chmod 600 private.key   # ← readable only by owner — never 644 or 755
```

### Generate a CSR

The **Certificate Signing Request** contains your public key and the domain information. You send this to your CA. They sign it and return your certificate.

```bash
openssl req -new -key private.key -out request.csr

# Non-interactive, specify subject inline
openssl req -new -key private.key -out request.csr \
  -subj "/C=US/ST=California/L=San Francisco/O=Example Corp/CN=api.example.com"
```

### Inspect a CSR

```bash
openssl req -text -noout -in request.csr
```

Check that the `CN` and any SANs are correct before sending to the CA.

### Self-Signed Certificate for Testing

A **self-signed certificate** is signed by the same key that owns it — no CA is involved. Browsers will warn about it, but it's useful for internal services and local development.

```bash
# Generate key and self-signed cert in one command (valid for 365 days)
openssl req -x509 -newkey rsa:4096 -keyout private.key -out cert.pem \
  -days 365 -nodes \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

# -nodes      ← no passphrase on the key
# -x509       ← output a self-signed cert instead of a CSR
# -addext     ← add SANs (required for modern TLS clients)
```

---

## 5. Checking Certificate Expiry

Certificate expiry is the most common cause of production TLS outages. A cert that expired at 3am will kill your service until someone notices.

```bash
# Check expiry of a local certificate file
openssl x509 -enddate -noout -in cert.pem
# notAfter=Jan  1 00:00:00 2026 GMT

# Check expiry of a live server
echo | openssl s_client -connect api.example.com:443 2>/dev/null \
  | openssl x509 -noout -enddate

# Human-readable expiry with days remaining
echo | openssl s_client -connect api.example.com:443 2>/dev/null \
  | openssl x509 -noout -dates
```

### Automated Expiry Monitoring (Bash)

```bash
#!/bin/bash
# cert-check.sh — exit code 1 if cert expires within THRESHOLD days

HOST="api.example.com"
PORT="443"
THRESHOLD=30    # ← alert if expiring within 30 days

EXPIRY=$(echo | openssl s_client -connect "$HOST:$PORT" 2>/dev/null \
  | openssl x509 -noout -enddate \
  | cut -d= -f2)

EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

if [ "$DAYS_LEFT" -lt "$THRESHOLD" ]; then
  echo "WARNING: $HOST cert expires in $DAYS_LEFT days ($EXPIRY)"
  exit 1
else
  echo "OK: $HOST cert expires in $DAYS_LEFT days"
  exit 0
fi
```

Run via cron daily and alert to Slack/PagerDuty.

---

## 6. Certificate Chain Debugging

### The Most Common TLS Error

```
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

This means the server is presenting a certificate but the client cannot build a chain up to a trusted Root CA. The server is almost always missing the **intermediate CA certificate** from its chain.

```
What the server should send:
  Server Cert (depth 0)
  Intermediate CA (depth 1)    ← this is what's missing

What a correct nginx config looks like:
  ssl_certificate /etc/ssl/server.crt;
  # server.crt should contain: server cert + intermediate cert concatenated

# Build the full chain file:
cat server.crt intermediate.crt > fullchain.crt
```

### Reading Chain Verification Output

```bash
openssl s_client -connect api.example.com:443 -showcerts
```

Look for the `Verify return:` line at each level:

```
depth=2 CN = DigiCert Global Root CA
verify return:1                     ← root CA trusted
depth=1 CN = DigiCert TLS RSA SHA256 2020 CA1
verify return:1                     ← intermediate trusted
depth=0 CN = api.example.com
verify return:1                     ← server cert trusted — chain is complete
```

If any `verify return:0`, the chain is broken at that level.

### Download and Inspect an Intermediate CA Manually

When a server is missing its intermediate, you can fetch it from the cert's `Authority Information Access` extension:

```bash
# Find the intermediate CA URL from the server cert
openssl s_client -connect api.example.com:443 2>/dev/null \
  | openssl x509 -text -noout | grep "CA Issuers"
# URI:http://cacerts.digicert.com/DigiCertTLSRSASHA2562020CA1-1.crt

# Download the intermediate CA
curl -s http://cacerts.digicert.com/DigiCertTLSRSASHA2562020CA1-1.crt \
  | openssl x509 -inform DER -out intermediate.crt

# Concatenate to build the full chain
cat server.crt intermediate.crt > fullchain.crt
```

---

## 7. AWS Certificate Manager (ACM)

**AWS ACM** manages TLS certificates for AWS services. It handles issuance, renewal, and deployment automatically — no private key management, no renewal cron jobs.

```
ACM vs the alternatives:

  ACM (AWS)       ← Free for AWS resources, auto-renews, no key management
                     Can only be deployed to: ALB, CloudFront, API Gateway, AppRunner
                     Cannot export the private key (AWS holds it)

  Let's Encrypt   ← Free, open CA, 90-day certs, auto-renewal via certbot
                     Works anywhere: Nginx, Apache, self-managed servers
                     You hold the private key

  Self-signed     ← Free, instant, no CA
                     Useful for: internal services, dev/test, mTLS
                     Browsers and most clients reject them without explicit trust
```

### ACM Workflow

```bash
# Request a public certificate (via AWS CLI)
aws acm request-certificate \
  --domain-name api.example.com \
  --validation-method DNS \
  --subject-alternative-names www.example.com

# List certificates
aws acm list-certificates

# Describe a certificate (shows validation status, expiry)
aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:123:certificate/abc
```

ACM validates domain ownership either via DNS (add a CNAME record) or email. DNS validation is recommended — it enables automatic renewal.

### ACM with Load Balancers

```hcl
# Terraform: attach ACM cert to an ALB listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"   # ← TLS 1.3 preferred
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

ACM certificates attached to ALBs renew automatically with no downtime.

---

## 8. Let's Encrypt / certbot

**Let's Encrypt** is a free, automated CA. **certbot** is the official client that automates certificate issuance and renewal.

### Installation

```bash
# Ubuntu/Debian
sudo apt install certbot python3-certbot-nginx

# RHEL/Amazon Linux
sudo dnf install certbot python3-certbot-nginx
```

### Issue a Certificate

```bash
# Automatic: certbot configures Nginx for you
sudo certbot --nginx -d api.example.com -d www.example.com

# Automatic: certbot configures Apache for you
sudo certbot --apache -d api.example.com

# Manual: get cert only, configure web server yourself
sudo certbot certonly --standalone -d api.example.com
# ← binds port 80 temporarily for the ACME challenge
# ← your web server must not be running on port 80 during this
```

### Certificate Locations

```
/etc/letsencrypt/live/api.example.com/
├── cert.pem        ← server certificate only
├── chain.pem       ← intermediate CA certificate
├── fullchain.pem   ← server cert + intermediate (use this in Nginx/Apache)
└── privkey.pem     ← private key (chmod 600, readable only by root)
```

Nginx configuration:

```nginx
ssl_certificate     /etc/letsencrypt/live/api.example.com/fullchain.pem;  # ← not cert.pem
ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;
```

Using `cert.pem` instead of `fullchain.pem` in Nginx causes "missing intermediate" errors for some clients.

### Renewal

Let's Encrypt certificates expire after **90 days**. Certbot installs a renewal timer automatically:

```bash
# Test renewal without making changes
sudo certbot renew --dry-run

# Force renewal now
sudo certbot renew --force-renewal

# Check the systemd timer certbot installs
systemctl status certbot.timer
systemctl list-timers | grep certbot
```

If you prefer cron:

```bash
# /etc/cron.d/certbot
0 0,12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
# ← runs twice daily, reloads Nginx only if a cert was actually renewed
```

---

## 9. mTLS — Mutual TLS

Standard TLS is one-way: the client verifies the server. **mTLS** (mutual TLS) is two-way: both sides present and verify certificates.

```
Standard TLS:                   mTLS:
  Client ──verify server──► OK    Client ──verify server──► OK
                                  Client ◄──verify client── OK
                                  (server also validates client cert)
```

mTLS use cases:
- Service-to-service communication in Kubernetes (Istio/Linkerd handle this automatically)
- API authentication without passwords (each API client has a certificate)
- Zero Trust network access

### Testing mTLS with openssl

```bash
# Connect presenting a client certificate
openssl s_client \
  -connect api.example.com:443 \
  -cert client.crt \
  -key client.key

# If the server requires client cert and you don't provide one:
# "tlsv13 alert certificate required" or "handshake failure"
```

### Issuing a Client Certificate (for testing)

```bash
# Create client key and CSR
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=my-service"

# Sign with your own CA (for internal use)
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt -days 365
```

---

## 10. Common Production Scenarios

### "certificate verify failed" in curl or code

```bash
# Step 1: confirm the error
curl -v https://api.example.com 2>&1 | grep -i "verify\|error\|certificate"

# Step 2: check if the chain is complete
openssl s_client -connect api.example.com:443

# Step 3: check expiry
echo | openssl s_client -connect api.example.com:443 2>/dev/null \
  | openssl x509 -noout -dates

# Step 4: check if the cert's SAN matches the hostname
echo | openssl s_client -connect api.example.com:443 2>/dev/null \
  | openssl x509 -noout -text | grep -A2 "Subject Alternative"
```

### "certificate has expired" in Production

```bash
# Confirm expiry
echo | openssl s_client -connect api.example.com:443 2>/dev/null \
  | openssl x509 -noout -enddate

# If using certbot: force-renew
sudo certbot renew --force-renewal

# If using ACM: check in AWS Console — it should auto-renew if DNS validation is set up
aws acm describe-certificate --certificate-arn arn:aws:acm:... \
  | jq '.Certificate.RenewalEligibility'
```

### Wrong Hostname (CN/SAN Mismatch)

```bash
curl: (60) SSL: no alternative certificate subject name matches target hostname

# The cert's SANs don't include the hostname you're connecting to
# Check what SANs the cert has:
echo | openssl s_client -connect api.example.com:443 2>/dev/null \
  | openssl x509 -noout -text | grep DNS:

# Fix: reissue the certificate with the correct SANs
```

### Mixed Content / Partial Chain

If a client shows the cert as valid but another shows it as invalid, the server is usually not sending the intermediate CA. Different OS/browser TLS stacks have different intermediate CA caches — some will have it, some won't.

```bash
# Confirm by checking depth in s_client output
openssl s_client -connect api.example.com:443 2>&1 | grep "depth\|verify"

# Only depth=0 means only the server cert was sent — missing intermediate
```

---

## 11. Common Mistakes

| Mistake | Why it's wrong | Fix |
|---|---|---|
| Certificate has no SANs (only CN) | Modern browsers (Chrome 58+, curl) reject certs without SAN entries, even if CN matches | Always include `subjectAltName` in CSR or cert generation |
| Not including intermediate CA in chain | Clients without a cached intermediate fail with "unable to get local issuer" | Concatenate `server.crt + intermediate.crt` into `fullchain.crt` |
| Private key permissions are 644 | Any system user can read the key, compromising all past and future traffic if captured | `chmod 600 private.key` — readable only by owner |
| Using SHA-1 signature algorithm | SHA-1 is cryptographically broken and rejected by browsers since 2017 | Use SHA-256 (`-sha256` flag) or let the CA choose — modern CAs default to SHA-256 |
| Pointing Nginx to `cert.pem` instead of `fullchain.pem` | `cert.pem` contains only the server cert — clients that haven't cached the intermediate will fail | Always use `fullchain.pem` for `ssl_certificate` |
| Not automating renewal | 90-day Let's Encrypt certs expire fast; manual renewal always gets forgotten | Use certbot's systemd timer or cron with `--post-hook "systemctl reload nginx"` |
| Testing with `curl -k` (skip verification) | Masks the actual TLS error — you may never know the cert is broken | Use `openssl s_client` to diagnose; fix the root cause |

---

## Navigation

- Back to: [README](../../../README.md)
- Previous: [SSH](./ssh.md)
- Next: [Network Commands](./network_commands.md)
- Related: [AWS CLI Advanced](../../03_AWS/aws_cli_advanced.md)
