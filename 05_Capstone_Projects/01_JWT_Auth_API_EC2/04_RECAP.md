# 04 — Recap: JWT Auth API on EC2

## What You Built

You deployed a Python API the production way — not "click deploy" but the real stack: a systemd-managed process, Nginx as the public face, and a real TLS certificate. This is the mental model under every PaaS platform.

---

## 3 Key Concepts

### 1. systemd as a Process Manager

Before systemd, keeping a process running after a server reboot required cron hacks or init.d scripts. systemd gives you a clean declarative model.

The critical insight: `ExecStart` is not a shell command — it's a direct exec. That's why you need the full path to gunicorn (`/opt/myapp/venv/bin/gunicorn`) rather than relying on `PATH`. `Restart=always` means systemd restarts the process if it exits for any reason — crash, OOM, segfault, whatever.

```
[Service]
Restart=always        # ← restart even on clean exit (exit code 0)
RestartSec=5          # ← wait 5s before restarting (avoid restart storm)
```

### 2. Nginx as a Reverse Proxy

Nginx does three things in this setup:

- **SSL termination**: decrypts HTTPS, forwards plain HTTP to your app on port 8000
- **Header injection**: adds `X-Real-IP`, `X-Forwarded-Proto` so your app knows the real client IP and whether the original request was HTTPS
- **Port separation**: your app only ever binds to `127.0.0.1:8000` (localhost only), never to a public port

The proxy pattern also lets you run multiple apps on the same server with different `server_name` blocks.

### 3. certbot and the ACME Protocol

Let's Encrypt uses the **ACME protocol** to prove you control a domain before issuing a certificate. The `--nginx` plugin does this by temporarily placing a challenge file in a well-known URL on your server, then verifying it over HTTP. Once verified, it writes the cert and private key to `/etc/letsencrypt/live/` and modifies your Nginx config.

Auto-renewal: certbot installs a systemd timer (`certbot.timer`) that runs `certbot renew` twice daily. Certificates expire in 90 days; renewal happens at 60 days.

---

## Common Failures and Fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| `systemctl status` shows `failed` | gunicorn can't find the app module | Check `WorkingDirectory` and `ExecStart` paths |
| Nginx returns 502 Bad Gateway | App not running on port 8000 | `systemctl restart myapp` |
| certbot fails: "Problem binding to port 80" | Nginx is using port 80 | Use `--nginx` plugin, not standalone |
| Cert works but app returns 401 | JWT secret key mismatch | Make sure `SECRET_KEY` matches what signed the token |

---

## Extend It

Once you've completed the base project, try these enhancements:

**Replace SQLite with RDS**
SQLite is fine for one instance but can't handle multiple EC2 instances. Add an RDS Postgres instance in the same VPC and swap the SQLAlchemy connection string. Adds ~$15/month but teaches VPC networking.

**Add CloudWatch Agent**
Install the CloudWatch agent, point it at `/var/log/myapp/*.log`, and ship logs to CloudWatch Logs. Enables searching, alerting, and retention beyond the instance's lifetime.

**Use an Elastic IP**
By default, EC2 public IPs change on stop/start. Allocate an Elastic IP and associate it — then update your DNS record once and it never changes.

**Add failure alerting**
In the systemd unit file, add:
```
OnFailure=notify-failure@%n.service
```
Then create a `notify-failure@.service` that sends an email or Slack webhook when the app crashes.

---

## ✅ What you mastered
- Deploying a Python service as a managed systemd unit
- Nginx reverse proxy configuration with SSL termination
- Let's Encrypt certificate issuance via certbot

## 🔨 What to build next
- Add a deploy script that does zero-downtime restart (`systemctl restart` has a gap — use `gunicorn --reload` or a blue/green swap instead)

## ➡️ Next project
Move from manual EC2 to infrastructure-as-code: [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md)

---

## 📂 Navigation

**Next:** [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
