# Docker Deployment Guide for Linux (Ubuntu)

This project has been fully containerized and is designed to be deployed on an **Ubuntu Linux Server**. Everything from the API to the Database to the Automated Backups runs inside isolated Docker containers.

## Prerequisites for IT

The host server must have the following installed:
1. **Ubuntu Server LTS** (22.04 or 24.04 recommended)
2. **Docker Engine** and **Docker Compose**
   - Official installation guide: [Get Docker Engine - Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

---

## 1. Initial Setup

1. **Clone or copy** this entire project folder to your Ubuntu server.
2. Ensure you have your `.env` file present in the project root. It MUST contain your database credentials and secret keys.
   ```bash
   cp .env.example .env
   nano .env
   ```
3. *(Optional)* If you have an existing database dump (e.g. `routing_db_backup.sql`), place it inside the `init-db/` folder.
   > [!IMPORTANT]  
   > Docker will automatically ingest this `.sql` file **only on the very first boot** of a new database volume. If you accidentally boot without it and need to restart the ingestion, you MUST delete the existing empty database volume using `docker compose down -v` first.

## 2. Booting the Server

To build the images and start the entire stack in the background:

```bash
docker compose up -d --build
```

**What this does:**
- Downloads the official **PostgreSQL 18** image (upgraded to v18 to support modern pg_dumps from Windows machines).
- Builds the `api` container and forces binding to `0.0.0.0` to ensure network accessibility.
- Builds the `backup` container.
- Creates an isolated internal network.

## 3. Accessing the Website & Network Rules

Once the `api` container is running, it binds to port **8080** (or whatever `WAITRESS_PORT` is set to in your `.env`) on all network interfaces (`0.0.0.0`). 

If you are developing locally on a Windows machine using WSL2/Ubuntu, the IP addresses behave specifically:

- **`http://localhost:8080`** — **(Recommended for local dev)** Docker automatically bridges this securely to your Windows browser.
- **`http://192.168.x.x:8080`** — **(Required for LAN access)** Use your physical Windows Wi-Fi or Ethernet IP if you want to access the app from your phone or another computer in the office. You may need to Allow Port 8080 in Windows Defender Firewall.
- **`http://172.19.x.x:8080`** — **(Not recommended)** This is the WSL virtual network IP. Windows Firewall treats this as a "Public" adapter and will actively block browser traffic to it from the Windows side (`ERR_CONNECTION_REFUSED`).

---

## 4. Daily Operations Cheat Sheet

Here are the essential commands you need to manage the Docker stack. **Run all commands from inside the project folder.**

### View Live Logs
To see exactly what the API is doing (traffic, errors, console output):
```bash
docker compose logs -f api
```
*(Press `Ctrl+C` to exit the log view)*

To check if backups are running properly:
```bash
docker compose logs -f backup
```

### Deploying a Code Update
If you pull new code from Git, you need to rebuild the API container. This command does it seamlessly without tearing down your database:
```bash
docker compose up -d --build api
```

### Stopping the Server
To safely turn everything off (your database data is perfectly safe and preserved in a Docker Volume):
```bash
docker compose down
```

### 🔴 Danger: Full Factory Reset
If you want to completely wipe the server and **delete all database data**, run this command:
```bash
docker compose down -v
```

---

## 5. Automated Backups System

This stack includes a custom-built automated backup container that runs in the background.

- **Weekly Backups**: Runs every Sunday at 1:00 AM. (Retained for 90 days).
- **Monthly Backups**: Runs on the 1st of every month at 2:00 AM. (Retained for 360 days).

All backups are securely compressed (`.sql.gz`) and saved to the `backups/` folder directly on your host machine. You do not need to do anything to maintain this; it is entirely self-cleaning.