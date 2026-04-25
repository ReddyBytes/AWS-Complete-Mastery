#!/usr/bin/env bash
# =============================================================================
# Project 01: JWT Auth API on EC2 — SOLUTION SCRIPT
# =============================================================================
# Complete deployment script for a FastAPI JWT Auth API on Ubuntu EC2.
# Run this on a fresh Ubuntu 22.04 EC2 instance.
#
# Prerequisites:
#   - Ubuntu 22.04 EC2 with ports 22, 80, 443 open
#   - A domain or <ip>.nip.io pointing to the instance
#
# Usage:
#   chmod +x solution.sh
#   DOMAIN=54.123.45.67.nip.io ./solution.sh
# =============================================================================

set -euo pipefail

DOMAIN="${DOMAIN:-$(curl -s ifconfig.me).nip.io}"  # ← use env var or fall back to nip.io
APP_DIR="/opt/myapp"
SERVICE_NAME="myapp"
APP_USER="ubuntu"
EMAIL="${EMAIL:-admin@example.com}"  # ← used by certbot for renewal alerts

echo "==> [1/8] Installing system dependencies"
sudo apt-get update -y
sudo apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3-pip \
    nginx \
    certbot \
    python3-certbot-nginx

echo "==> [2/8] Creating application directory structure"
sudo mkdir -p "${APP_DIR}/app"
sudo mkdir -p /var/log/myapp
sudo chown -R "${APP_USER}:${APP_USER}" "${APP_DIR}"
sudo chown -R "${APP_USER}:${APP_USER}" /var/log/myapp

echo "==> [3/8] Writing the FastAPI application"

cat > "${APP_DIR}/app/main.py" << 'PYEOF'
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

# ── Configuration ────────────────────────────────────────────────────────────
SECRET_KEY = "change-me-in-production-use-a-real-secret"  # ← rotate this!
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

app = FastAPI(title="JWT Auth API", version="1.0.0")
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# ── Fake user store (replace with SQLAlchemy + RDS in production) ─────────────
fake_users_db = {
    "alice": {
        "username": "alice",
        "hashed_password": pwd_context.hash("secret"),
        "email": "alice@example.com",
    }
}

class Token(BaseModel):
    access_token: str
    token_type: str

class User(BaseModel):
    username: str
    email: str

def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/health")
def health_check():
    """Liveness probe — used by load balancers and monitoring."""
    return {"status": "ok", "timestamp": datetime.utcnow().isoformat()}

@app.post("/token", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends()):
    """Exchange username/password for a JWT access token."""
    user = fake_users_db.get(form_data.username)
    if not user or not pwd_context.verify(form_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = create_access_token(
        data={"sub": form_data.username},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": token, "token_type": "bearer"}

@app.get("/me", response_model=User)
def read_current_user(token: str = Depends(oauth2_scheme)):
    """Return the currently authenticated user's profile."""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token payload")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token validation failed")

    user = fake_users_db.get(username)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return {"username": user["username"], "email": user["email"]}
PYEOF

cat > "${APP_DIR}/app/requirements.txt" << 'EOF'
fastapi==0.111.0
uvicorn[standard]==0.29.0
gunicorn==22.0.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
EOF

echo "==> [4/8] Creating Python virtual environment and installing requirements"
cd "${APP_DIR}"
python3.11 -m venv venv
venv/bin/pip install --upgrade pip --quiet
venv/bin/pip install -r app/requirements.txt --quiet

echo "==> [5/8] Writing systemd unit file"
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=JWT Auth API (FastAPI + Gunicorn)
Documentation=https://fastapi.tiangolo.com
After=network.target
Wants=network-online.target

[Service]
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${APP_DIR}
Environment="PATH=${APP_DIR}/venv/bin"
ExecStart=${APP_DIR}/venv/bin/gunicorn \\
    --workers 2 \\
    --worker-class uvicorn.workers.UvicornWorker \\
    app.main:app \\
    --bind 127.0.0.1:8000 \\
    --access-logfile /var/log/myapp/access.log \\
    --error-logfile /var/log/myapp/error.log \\
    --log-level info
Restart=always
RestartSec=5
StandardOutput=append:/var/log/myapp/stdout.log
StandardError=append:/var/log/myapp/stderr.log

[Install]
WantedBy=multi-user.target
EOF

echo "==> [6/8] Enabling and starting systemd service"
sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl start "${SERVICE_NAME}"

# Wait a moment for the service to start
sleep 3

# Verify it's running
if sudo systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "    Service is running ✓"
    curl -s http://127.0.0.1:8000/health | python3 -m json.tool
else
    echo "    ERROR: service failed to start"
    sudo journalctl -u "${SERVICE_NAME}" -n 30 --no-pager
    exit 1
fi

echo "==> [7/8] Configuring Nginx reverse proxy"
sudo tee /etc/nginx/sites-available/${SERVICE_NAME} > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};

    # Pass requests to Gunicorn
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 90s;
    }

    # Nginx access logs separate from app logs
    access_log /var/log/nginx/${SERVICE_NAME}-access.log;
    error_log  /var/log/nginx/${SERVICE_NAME}-error.log;
}
EOF

# Enable site, remove default, reload nginx
sudo ln -sf /etc/nginx/sites-available/${SERVICE_NAME} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

echo "==> [8/8] Obtaining SSL certificate from Let's Encrypt"
sudo certbot --nginx \
    -d "${DOMAIN}" \
    --non-interactive \
    --agree-tos \
    -m "${EMAIL}" \
    --redirect  # ← automatically adds HTTP→HTTPS redirect in nginx config

echo ""
echo "============================================================"
echo " Deployment complete!"
echo "============================================================"
echo ""
echo " Test commands:"
echo ""
echo "   # Health check"
echo "   curl https://${DOMAIN}/health"
echo ""
echo "   # Get a JWT token"
echo "   TOKEN=\$(curl -s -X POST https://${DOMAIN}/token \\"
echo "     -H 'Content-Type: application/x-www-form-urlencoded' \\"
echo "     -d 'username=alice&password=secret' | jq -r '.access_token')"
echo ""
echo "   # Use the token"
echo "   curl -H \"Authorization: Bearer \$TOKEN\" https://${DOMAIN}/me"
echo ""
echo " Service management:"
echo "   sudo systemctl status ${SERVICE_NAME}"
echo "   sudo journalctl -u ${SERVICE_NAME} -f"
echo "   sudo tail -f /var/log/myapp/access.log"
