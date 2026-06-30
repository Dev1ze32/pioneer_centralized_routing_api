"""
Waitress production server for the ACU Routing API.

Usage
-----
    python server.py

Waitress is a pure-Python WSGI server that runs on Windows, Linux, and macOS.
It uses a thread-pool model (no separate worker processes), which means the
single in-memory rate-limiter (Flask-Limiter memory://) works correctly —
all threads share one counter.

All tunables are read from environment variables via config.py:
    WAITRESS_THREADS  — number of threads in the pool (default 8)
    WAITRESS_PORT     — port to bind to (default 5000)
"""

import logging
from logging.handlers import RotatingFileHandler
import sys
import os

from waitress import serve
from whitenoise import WhiteNoise

from app import create_app
from config import Config

# ── Logging ───────────────────────────────────────────────────────────────────
# Stream handler always active (captured by Docker logs).
# File handler is a bonus for bare-metal / local dev runs.
stream_handler = logging.StreamHandler(sys.stdout)
handlers = [stream_handler]

try:
    file_handler = RotatingFileHandler(
        "api_server.log",
        maxBytes=10 * 1024 * 1024,  # 10 MB
        backupCount=5,
    )
    handlers.append(file_handler)
except OSError:
    # Non-root container users may not have write access to the working dir.
    # Logging to stdout is sufficient in Docker — skip the file handler silently.
    pass

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    handlers=handlers,
)

logger = logging.getLogger(__name__)

# ── App factory ───────────────────────────────────────────────────────────────
app = create_app()

# ── Static file serving via WhiteNoise ────────────────────────────────────────
# WhiteNoise serves the frontend directly from the Python process.
# autorefresh=False is correct for production — files don't change at runtime.
# In Docker the frontend is baked into the image at build time.
app_with_static = WhiteNoise(
    app,
    root=os.path.join(os.path.dirname(__file__), "frontend", "asd"),
    index_file=True,
    autorefresh=True,  # Re-reads files from disk; keeps static up-to-date without restart
)

# ── Server ────────────────────────────────────────────────────────────────────
host    = "0.0.0.0"
port    = Config.WAITRESS_PORT
threads = Config.WAITRESS_THREADS

logger.info(
    "Starting ACU Routing API + Frontend with Waitress — host=%s port=%d threads=%d",
    host, port, threads,
)

serve(
    app_with_static,
    host=host,
    port=port,
    threads=threads,
    connection_limit=1000,
    url_scheme="http",
    channel_timeout=120,
    max_request_header_size=131072,
    max_request_body_size=1048576,
)