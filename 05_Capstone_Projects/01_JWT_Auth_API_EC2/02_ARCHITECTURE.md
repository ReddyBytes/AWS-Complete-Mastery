# 02 — Architecture: JWT Auth API on EC2

## How Traffic Flows

Think of Nginx as a hotel concierge. Every guest (HTTP request) arrives at the front desk (port 443). The concierge checks credentials (SSL termination), then routes the guest to the right room (your FastAPI app on port 8000). The app never talks directly to the internet.

```
Internet
    |
    | HTTPS :443
    v
+----------------------------------+
|          EC2 Instance            |
|  +----------------------------+  |
|  |          Nginx             |  |
|  |  (reverse proxy + SSL)     |  |
|  +----------------------------+  |
|       | HTTP :8000 (internal)    |
|       v                          |
|  +----------------------------+  |
|  |   systemd: myapp.service   |  |
|  |   (gunicorn process mgr)   |  |
|  +----------------------------+  |
|       |                          |
|       v                          |
|  +----------------------------+  |
|  |   FastAPI Application      |  |
|  |   /token /me /refresh      |  |
|  +----------------------------+  |
|       |                          |
|       v                          |
|  +----------------------------+  |
|  |   SQLite (local DB)        |  |
|  |   /opt/myapp/app.db        |  |
|  +----------------------------+  |
+----------------------------------+
    ^
    | DNS A record
    |
your-domain.com (or <ip>.nip.io)
```

---

## Boot Sequence: How the App Starts Automatically

systemd is Linux's init system — it's PID 1, the first process the kernel starts. Everything else is a child of systemd. When you write a unit file and `enable` it, you're telling systemd: "Start this service after the network is up, and restart it if it crashes."

```
Kernel boots
    |
    v
systemd starts (PID 1)
    |
    v
network.target reached
    |
    v
myapp.service starts     <- your unit file triggers here
    |
    v
ExecStart: gunicorn      <- starts 2 worker processes
    |
    v
workers import FastAPI app
    |
    v
listening on 127.0.0.1:8000
    |
    v
nginx forwards :443 → :8000
```

---

## Security Group Rules

Security groups are EC2's virtual firewall. They're stateful — if you allow inbound on port 443, the response traffic is automatically allowed out.

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP only | SSH access |
| 80 | TCP | 0.0.0.0/0 | HTTP (certbot challenge + redirect to HTTPS) |
| 443 | TCP | 0.0.0.0/0 | HTTPS (main traffic) |

Note: port 8000 is NOT open to the internet. Only Nginx (running on the same instance) talks to it via `127.0.0.1:8000`.

---

## Deployment Layers

```
Layer 1: Infrastructure
    EC2 instance + Security Group + Elastic IP (optional)

Layer 2: OS + Runtime
    Ubuntu 22.04 + Python 3.11 + pip packages

Layer 3: Application
    /opt/myapp/
    ├── app/
    │   ├── main.py          (FastAPI app)
    │   ├── auth.py          (JWT logic)
    │   └── models.py        (SQLAlchemy models)
    ├── venv/                (Python virtualenv)
    └── app.db               (SQLite database)

Layer 4: Process Management
    /etc/systemd/system/myapp.service
    (runs gunicorn, auto-restarts, starts on boot)

Layer 5: Reverse Proxy + TLS
    /etc/nginx/sites-available/myapp
    /etc/letsencrypt/live/your-domain/  (certbot certs)
```

---

## Tech Stack Summary

| Component | Role | Why This Choice |
|---|---|---|
| FastAPI | Web framework | Fast, async, auto-generates OpenAPI docs |
| Gunicorn | WSGI/ASGI server | Production-grade, manages worker processes |
| systemd | Process manager | Native Linux, survives reboots, structured logging |
| Nginx | Reverse proxy | Handles SSL termination, static files, load balancing |
| certbot | Certificate manager | Free TLS certs from Let's Encrypt, auto-renews |
| SQLite | Database | Zero config for this demo; replace with RDS in production |

---

## 📂 Navigation

**Next:** [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
