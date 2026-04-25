#!/usr/bin/env bash
# =============================================================================
# Project 01: JWT Auth API on EC2 — STARTER SCRIPT
# =============================================================================
# This script scaffolds Steps 2-6 of the deployment guide.
# Fill in each TODO section to complete the deployment.
#
# Usage:
#   chmod +x starter.sh
#   ./starter.sh
# =============================================================================

set -euo pipefail

APP_DIR="/opt/myapp"
SERVICE_NAME="myapp"
APP_USER="ubuntu"

echo "==> Step 2: Install system dependencies"
# TODO: Run apt-get update and install:
#   - python3.11
#   - python3.11-venv
#   - python3-pip
#   - nginx
#   - certbot
#   - python3-certbot-nginx


echo "==> Step 3: Create application directory"
# TODO: Create /opt/myapp/app/ with sudo mkdir -p
# TODO: Change ownership to ubuntu:ubuntu with sudo chown -R


echo "==> Step 4: Write the FastAPI application files"
# TODO: Create /opt/myapp/app/main.py with a FastAPI app that has:
#   - GET /health  → {"status": "ok"}
#   - POST /token  → returns JWT on valid username/password
#   - GET /me      → returns username from JWT token

# TODO: Create /opt/myapp/app/requirements.txt with:
#   fastapi, uvicorn[standard], gunicorn, python-jose[cryptography],
#   passlib[bcrypt], python-multipart


echo "==> Step 5: Create Python virtual environment and install requirements"
# TODO: cd to $APP_DIR
# TODO: Create a venv at $APP_DIR/venv using python3.11
# TODO: Install requirements from app/requirements.txt using the venv pip


echo "==> Step 6: Create log directory"
# TODO: Create /var/log/myapp with sudo mkdir -p
# TODO: Change ownership to ubuntu:ubuntu


echo "==> Step 7: Write systemd unit file"
# TODO: Write /etc/systemd/system/myapp.service using sudo tee
# The unit file needs these key fields:
#   [Unit]    After=network.target
#   [Service] User=ubuntu, WorkingDirectory=$APP_DIR,
#             ExecStart=(path to gunicorn), Restart=always
#   [Install] WantedBy=multi-user.target
#
# Gunicorn command: $APP_DIR/venv/bin/gunicorn \
#   -w 2 -k uvicorn.workers.UvicornWorker app.main:app \
#   --bind 127.0.0.1:8000


echo "==> Step 8: Enable and start the service"
# TODO: Run: sudo systemctl daemon-reload
# TODO: Run: sudo systemctl enable $SERVICE_NAME
# TODO: Run: sudo systemctl start $SERVICE_NAME


echo "==> Verification"
echo "Run the following to check status:"
echo "  sudo systemctl status $SERVICE_NAME"
echo "  curl http://127.0.0.1:8000/health"
echo ""
echo "If the service failed, check logs with:"
echo "  sudo journalctl -u $SERVICE_NAME -n 50 --no-pager"
