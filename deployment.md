# ACU Routing API — Deployment Guide

Two deployment paths:

| Path | When to use |
|---|---|
| **Docker Compose** (recommended) | Windows Server data center, any machine with Docker Desktop or Docker Engine |
| **Bare metal / systemd** | Linux server without Docker |

---

## Docker Compose deployment (recommended for Windows server)

### Prerequisites on the Windows server

1. Install **Docker Desktop for Windows** (requires WSL2 — the installer handles this)
   https://docs.docker.com/desktop/install/windows-install/
2. Make sure Docker Desktop is running (system tray icon)

### First deployment

```powershell
# 1. Copy the project folder to the server (USB, network share, git clone, etc.)
#    Then open PowerShell in that folder:

# 2. Create your .env file
copy .env.example .env
notepad .env        # fill in DB_PASSWORD and JWT_SECRET_KEY at minimum

# 3. Copy your schema file into init-db/ so Postgres initializes correctly
copy schema.sql init-db\01_schema.sql

# 4. Build and start everything
docker compose up -d --build

# 5. Check everything is healthy
docker compose ps
# Both "acu-routing-db" and "acu-routing-api" should show "healthy" or "running"

# 6. Load your data (first time only)
docker compose exec api python load_data.py acu_routing_parsed.json

# 7. Test it
# Open browser: http://localhost:5000/api/health  → should return {"status": "ok"}
# Swagger UI:   http://localhost:5000/docs/
```

### Day-to-day operations

```powershell
# Live logs
docker compose logs -f api      # API logs
docker compose logs -f db       # Postgres logs

# Restart the API (e.g. after a config change in .env)
docker compose restart api

# Deploy a code update
docker compose up -d --build api    # rebuilds only the api image, zero db downtime

# Stop everything (DB data is preserved in the postgres_data volume)
docker compose down

# Full reset — WARNING: deletes all database data
docker compose down -v
docker compose up -d --build
```

### Access from other machines on the network

By default the API listens on port 5000 on all interfaces.
Other machines on the same network can reach it at:

    http://<server-ip-address>:5000/api/health

If Windows Firewall blocks it:
```powershell
# Run as Administrator
netsh advfirewall firewall add rule `
    name="ACU Routing API" `
    dir=in action=allow protocol=TCP localport=5000
```

---

## Bare metal / systemd deployment (Linux only)

### Prerequisites
```bash
sudo apt install python3.12 python3.12-venv libpq-dev   # Debian/Ubuntu
sudo useradd -r -s /bin/false appuser
```

### Install
```bash
sudo mkdir -p /opt/acu-routing-api
sudo chown appuser:appuser /opt/acu-routing-api
sudo -u appuser cp -r . /opt/acu-routing-api/
cd /opt/acu-routing-api
sudo -u appuser python3 -m venv venv
sudo -u appuser venv/bin/pip install -r requirements.txt
sudo -u appuser cp .env.example .env && nano .env
sudo -u appuser venv/bin/python load_data.py acu_routing_parsed.json
```

### Install as a system service
```bash
# Edit User=, WorkingDirectory=, ExecStart= paths in the file first
sudo cp acu-routing-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now acu-routing-api
sudo systemctl status acu-routing-api
sudo journalctl -u acu-routing-api -f   # live logs
```

---

## Scaling / tuning reference

| Variable | Default | Rule of thumb |
|---|---|---|
| `GUNICORN_WORKERS` | 4 | `(2 × CPU cores) + 1` |
| `GUNICORN_THREADS` | 4 | 2–4 per worker |
| `DB_POOL_SIZE` | 20 | = workers × threads |
| `DB_MAX_OVERFLOW` | 10 | burst headroom on top of pool |
| `DB_POOL_TIMEOUT` | 10s | seconds before queued request gets a 503 |
| `DB_STATEMENT_TIMEOUT_MS` | 30000 | Postgres kills queries longer than this |
| `RATE_LIMIT_LOGIN` | 10/minute | per IP — raise if internal tools need more |
| `RATE_LIMIT_DEFAULT` | 300/minute | per IP across all other endpoints |

**Pool sizing example for a 4-core machine:**
```
GUNICORN_WORKERS=9    # (2×4)+1
GUNICORN_THREADS=4
DB_POOL_SIZE=36       # 9×4
DB_MAX_OVERFLOW=10
```

After changing `.env`, restart with:
```powershell
docker compose up -d --build api   # Docker
# or
sudo systemctl restart acu-routing-api   # systemd
```