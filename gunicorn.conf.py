"""
Gunicorn configuration for the ACU Routing API.

All values can be overridden via environment variables (see config.py).
Run with:
    gunicorn "app:create_app()" -c gunicorn.conf.py

Worker math
-----------
A common rule of thumb for sync workers with threading:
    workers = (2 × CPU cores) + 1   — for I/O-bound workloads (DB calls)
    threads = 2–4 per worker

With 4 workers × 4 threads you get 16 concurrent request slots.
The DB pool (pool_size=20, max_overflow=10) comfortably covers that.

If your server has more cores, increase GUNICORN_WORKERS in .env;
also increase DB_POOL_SIZE to match (workers × threads).
"""

import multiprocessing
import os

from dotenv import load_dotenv
load_dotenv()

# ── Binding ───────────────────────────────────────────────────────────────────
port    = int(os.getenv("GUNICORN_PORT",    "5000"))
bind    = f"0.0.0.0:{port}"

# ── Workers ───────────────────────────────────────────────────────────────────
workers = int(os.getenv("GUNICORN_WORKERS", "4"))
threads = int(os.getenv("GUNICORN_THREADS", "4"))
worker_class = "gthread"   # sync worker + threads — best for DB-heavy workloads

# ── Timeouts ──────────────────────────────────────────────────────────────────
# Worker is killed and restarted if it goes silent for this many seconds.
# Should be longer than DB_STATEMENT_TIMEOUT_MS / 1000 + a few seconds buffer.
timeout      = int(os.getenv("GUNICORN_TIMEOUT",       "60"))
# Seconds to wait for the next request on a keep-alive connection
keepalive    = int(os.getenv("GUNICORN_KEEPALIVE",      "5"))
# Seconds for graceful shutdown (finish in-flight requests before dying)
graceful_timeout = int(os.getenv("GUNICORN_GRACEFUL_TIMEOUT", "30"))

# ── Logging ───────────────────────────────────────────────────────────────────
accesslog  = "-"   # stdout — collected by systemd / docker logs
errorlog   = "-"   # stderr
loglevel   = os.getenv("GUNICORN_LOG_LEVEL", "info")
access_log_format = (
    '%(h)s "%(r)s" %(s)s %(b)s %(D)sµs'   # IP, request, status, bytes, latency
)

# ── Process naming (visible in ps/top) ───────────────────────────────────────
proc_name = "acu-routing-api"

# ── Pre-fork hook — log startup config ───────────────────────────────────────
def on_starting(server):
    server.log.info(
        "Starting ACU Routing API — workers=%d threads=%d port=%d timeout=%ds",
        workers, threads, port, timeout,
    )

def worker_exit(server, worker):
    """Log when a worker exits so restarts are visible in the log."""
    server.log.info("Worker %s exited (pid %d)", worker, worker.pid)