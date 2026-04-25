# 01 — Mission: Deploy JWT Auth API to EC2

## The Scenario

You've built a JWT authentication API in Python. It works perfectly on your laptop. Now a teammate asks: "Can I hit it from the internet?"

That's the gap this project closes. Not "deploy to Heroku with a git push" — but the real manual-but-correct way that every AWS engineer needs to understand: provision a server, install your app as a **systemd service**, put **Nginx** in front of it as a reverse proxy, and lock it down with a real **SSL certificate** from Let's Encrypt.

Once you've done this once by hand, you'll understand what platforms like Heroku and Elastic Beanstalk are actually doing for you — and you'll be able to debug them when they break.

---

## What You'll Build

A production-ready EC2 deployment with:

- A FastAPI app serving JWT auth endpoints (`/token`, `/me`, `/refresh`)
- The app running as a **systemd service** — it restarts on failure and starts on boot
- **Nginx** as the public-facing reverse proxy on ports 80 and 443
- A valid **TLS certificate** from Let's Encrypt via certbot
- Proper **security group** rules (only necessary ports open)

---

## Skills You'll Practice

| Skill | What you'll do |
|---|---|
| EC2 setup | Launch, configure, SSH into an Ubuntu instance |
| Linux system administration | Install packages, manage files, set permissions |
| systemd | Write a unit file, enable/start/troubleshoot a service |
| Nginx | Write a reverse proxy config with SSL passthrough |
| certbot | Obtain and auto-renew a Let's Encrypt certificate |
| Security groups | Apply least-privilege firewall rules |

---

## Prerequisites

Before starting, you should be comfortable with:

- Launching an EC2 instance in the AWS Console
- SSH with a key pair (`ssh -i key.pem ubuntu@<ip>`)
- Basic Linux commands (`cd`, `ls`, `sudo`, `systemctl`)
- Python virtual environments (`python3 -m venv`)

If any of those are shaky, review sections 03 (Linux) and 04 (AWS) first.

---

## Project Metadata

| Field | Value |
|---|---|
| Difficulty | 🟢 Fully Guided |
| Estimated time | 3 hours |
| AWS cost | ~$0.01/hr (t2.micro free tier eligible) |
| Stack | EC2 (Ubuntu 22.04), Python 3.11, FastAPI, Gunicorn, Nginx, certbot |

---

## Acceptance Criteria

You've succeeded when:

1. `curl https://your-domain/health` returns `{"status": "ok"}`
2. `curl -X POST https://your-domain/token -d "username=alice&password=secret"` returns a JWT
3. `systemctl status myapp` shows `active (running)`
4. The certificate is valid (browser shows padlock, or `curl -v` shows TLS handshake)
5. Rebooting the instance (`sudo reboot`) brings the app back up automatically

---

## 📂 Navigation

**Next:** [02 — Terraform Full AWS Stack](../02_Terraform_AWS_Stack/01_MISSION.md)

**Section:** [05 Capstone Projects](../) &nbsp;&nbsp; **Repo:** [Linux-Terraform-AWS-Mastery](../../README.md)
