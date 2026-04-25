# 03 — Guide: Deploy JWT Auth API to EC2

This guide walks you through deploying a FastAPI JWT authentication API to EC2, step by step. Each step has a hint you can expand, and a full answer if you're stuck.

---

## Step 1 — Launch the EC2 Instance

Go to EC2 → Launch Instance in the AWS Console.

Settings to use:
- AMI: Ubuntu Server 22.04 LTS
- Instance type: t2.micro (free tier)
- Key pair: create new or use existing (save the `.pem` file)
- Security group: create new — allow SSH (port 22) from your IP, HTTP (80) and HTTPS (443) from anywhere
- Storage: 8 GB gp3 (default is fine)

Once launched, note the **Public IPv4 address**.

<details>
<summary>💡 Hint: Can't connect via SSH?</summary>

Check two things: (1) your security group has port 22 open for your current IP — your IP may have changed, and (2) you're using the right username. For Ubuntu AMIs it's `ubuntu`, not `ec2-user`.

```bash
ssh -i /path/to/key.pem ubuntu@<public-ip>
```

If the key permission is wrong:
```bash
chmod 400 /path/to/key.pem
```
</details>

<details>
<summary>✅ Answer: Launch via AWS CLI</summary>

```bash
# Create security group
aws ec2 create-security-group \
  --group-name myapp-sg \
  --description "JWT API security group"

# Add rules
aws ec2 authorize-security-group-ingress --group-name myapp-sg --protocol tcp --port 22 --cidr $(curl -s ifconfig.me)/32
aws ec2 authorize-security-group-ingress --group-name myapp-sg --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name myapp-sg --protocol tcp --port 443 --cidr 0.0.0.0/0

# Launch instance
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \  # Ubuntu 22.04 us-east-1
  --instance-type t2.micro \
  --key-name your-key-pair \
  --security-groups myapp-sg \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jwt-api}]'
```
</details>

---

## Step 2 — SSH In and Install Dependencies

SSH into your instance and install everything you'll need.

```bash
ssh -i /path/to/key.pem ubuntu@<public-ip>
```

<details>
<summary>💡 Hint: What packages do you need?</summary>

You need: Python 3.11+, pip, python3-venv (for isolated environments), nginx (reverse proxy), certbot and its nginx plugin (SSL certificates).
</details>

<details>
<summary>✅ Answer: Full install commands</summary>

```bash
sudo apt-get update -y
sudo apt-get install -y python3.11 python3.11-venv python3-pip nginx certbot python3-certbot-nginx
```
</details>

---

## Step 3 — Copy the App to /opt/myapp

Create the application directory and place your code there. `/opt` is the Linux convention for optional/third-party software.

<details>
<summary>💡 Hint: Directory structure to create</summary>

```
/opt/myapp/
├── app/
│   ├── main.py
│   ├── auth.py
│   └── requirements.txt
```

Set ownership so the app runs as a non-root user:
```bash
sudo mkdir -p /opt/myapp/app
sudo chown -R ubuntu:ubuntu /opt/myapp
```
</details>

<details>
<summary>✅ Answer: Write the FastAPI app inline</summary>

```bash
sudo mkdir -p /opt/myapp/app
sudo chown -R ubuntu:ubuntu /opt/myapp

cat > /opt/myapp/app/main.py << 'EOF'
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

SECRET_KEY = "change-me-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

app = FastAPI(title="JWT Auth API")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# Fake user database
fake_users = {
    "alice": {"username": "alice", "hashed_password": pwd_context.hash("secret")}
}

class Token(BaseModel):
    access_token: str
    token_type: str

def create_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/token", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = fake_users.get(form_data.username)
    if not user or not pwd_context.verify(form_data.password, user["hashed_password"]):
        raise HTTPException(status_code=400, detail="Incorrect credentials")
    token = create_token({"sub": form_data.username}, timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    return {"access_token": token, "token_type": "bearer"}

@app.get("/me")
def read_me(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    return {"username": username}
EOF

cat > /opt/myapp/app/requirements.txt << 'EOF'
fastapi==0.111.0
uvicorn[standard]==0.29.0
gunicorn==22.0.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
EOF
```
</details>

---

## Step 4 — Create Python Virtual Environment and Install Requirements

Python virtual environments isolate your app's dependencies from the system Python. This prevents version conflicts and is the correct way to manage Python apps on Linux.

<details>
<summary>💡 Hint: venv commands</summary>

Create the venv at `/opt/myapp/venv`, then activate it and pip install.
</details>

<details>
<summary>✅ Answer</summary>

```bash
cd /opt/myapp
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r app/requirements.txt
deactivate
```

Test the app starts:
```bash
cd /opt/myapp
venv/bin/gunicorn -w 2 -k uvicorn.workers.UvicornWorker app.main:app --bind 127.0.0.1:8000
# ctrl+c to stop — we'll use systemd next
```
</details>

---

## Step 5 — Write the systemd Unit File

A **systemd unit file** tells the OS how to run your app: what command to execute, what user to run as, when to start, and what to do on failure.

<details>
<summary>💡 Hint: Key directives to include</summary>

- `[Unit]` section: `Description`, `After=network.target` (don't start until network is up)
- `[Service]` section: `User`, `WorkingDirectory`, `ExecStart` (full path to gunicorn), `Restart=always`
- `[Install]` section: `WantedBy=multi-user.target` (start in normal boot mode)
</details>

<details>
<summary>✅ Answer: Full unit file</summary>

```bash
sudo tee /etc/systemd/system/myapp.service << 'EOF'
[Unit]
Description=JWT Auth API (FastAPI + Gunicorn)
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/opt/myapp
Environment="PATH=/opt/myapp/venv/bin"
ExecStart=/opt/myapp/venv/bin/gunicorn \
    -w 2 \
    -k uvicorn.workers.UvicornWorker \
    app.main:app \
    --bind 127.0.0.1:8000 \
    --access-logfile /var/log/myapp/access.log \
    --error-logfile /var/log/myapp/error.log
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create log directory
sudo mkdir -p /var/log/myapp
sudo chown ubuntu:ubuntu /var/log/myapp
```
</details>

---

## Step 6 — Enable and Start the Service

With the unit file in place, tell systemd to load it and start it.

<details>
<summary>💡 Hint: systemctl commands</summary>

You need three commands in order: `daemon-reload` (reload unit files from disk), `enable` (start on boot), `start` (start now).
</details>

<details>
<summary>✅ Answer</summary>

```bash
sudo systemctl daemon-reload
sudo systemctl enable myapp
sudo systemctl start myapp
sudo systemctl status myapp   # should show "active (running)"

# Check the app is responding on port 8000
curl http://127.0.0.1:8000/health
# Expected: {"status":"ok"}
```

If it fails, check logs:
```bash
sudo journalctl -u myapp -n 50 --no-pager
```
</details>

---

## Step 7 — Configure Nginx as a Reverse Proxy

Nginx sits in front of your app, handling SSL termination and forwarding traffic to port 8000.

<details>
<summary>💡 Hint: Key Nginx directives</summary>

You need a `server` block listening on port 80 (certbot will add port 443 later). Inside it: `location /` with `proxy_pass http://127.0.0.1:8000` and the standard proxy headers.
</details>

<details>
<summary>✅ Answer: Full Nginx config</summary>

```bash
sudo tee /etc/nginx/sites-available/myapp << 'EOF'
server {
    listen 80;
    server_name your-domain.com;       # replace with your domain or <ip>.nip.io

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the site (symlink to sites-enabled)
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default   # remove default site

# Test config and reload
sudo nginx -t
sudo systemctl reload nginx
```
</details>

---

## Step 8 — Point Your Domain to the EC2 IP

Let's Encrypt requires a real domain name to issue a certificate. If you don't have one, use **nip.io** — a free DNS service that maps `<ip>.nip.io` directly to that IP.

<details>
<summary>💡 Hint: Using nip.io (no domain needed)</summary>

If your EC2 IP is `54.123.45.67`, your domain is `54.123.45.67.nip.io`. Update the `server_name` in your Nginx config to match, then reload Nginx.
</details>

<details>
<summary>✅ Answer: Update and reload</summary>

```bash
# Replace 'your-domain.com' with e.g. '54.123.45.67.nip.io'
sudo sed -i 's/your-domain.com/54.123.45.67.nip.io/' /etc/nginx/sites-available/myapp
sudo systemctl reload nginx

# Verify HTTP works before getting the cert
curl http://54.123.45.67.nip.io/health
```
</details>

---

## Step 9 — Run Certbot for SSL

Certbot handles the entire ACME challenge flow: it proves you control the domain, downloads the certificate, and modifies your Nginx config to enable HTTPS.

<details>
<summary>💡 Hint: certbot command structure</summary>

Use `certbot --nginx -d your-domain.com`. It will ask for an email (for expiry alerts) and whether to redirect HTTP to HTTPS (say yes).
</details>

<details>
<summary>✅ Answer</summary>

```bash
sudo certbot --nginx -d 54.123.45.67.nip.io --non-interactive --agree-tos -m you@email.com --redirect

# Verify auto-renewal is configured
sudo certbot renew --dry-run
```

After certbot runs, your Nginx config will have been updated to include SSL directives and the HTTP→HTTPS redirect.
</details>

---

## Step 10 — Test End-to-End

<details>
<summary>✅ Answer: Full test suite</summary>

```bash
# 1. Health check over HTTPS
curl https://54.123.45.67.nip.io/health

# 2. Get a JWT token
TOKEN=$(curl -s -X POST https://54.123.45.67.nip.io/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=alice&password=secret" | jq -r '.access_token')

echo "Token: $TOKEN"

# 3. Use the token
curl -H "Authorization: Bearer $TOKEN" https://54.123.45.67.nip.io/me

# 4. Verify service survives reboot
sudo reboot
# Wait 30 seconds, then:
curl https://54.123.45.67.nip.io/health
```
</details>

---

## 📂 Navigation

**Next:** [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
