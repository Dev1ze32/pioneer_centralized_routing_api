"""
Waitress production server for the ACU Routing API.

Usage
-----
    python waitress_server.py

Waitress is a pure-Python WSGI server that runs on Windows, Linux, and macOS.
It uses a thread-pool model (no separate worker processes).

All tunables are read from .env via config.py:
    WAITRESS_THREADS  — number of threads in the pool (default 8)
    WAITRESS_PORT     — port to bind to (default 8080)
"""

import logging

from waitress import serve

from app import create_app
from config import Config

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
)

logger = logging.getLogger(__name__)

if __name__ == "__main__":
    app = create_app()

    host = "0.0.0.0"
    port = Config.WAITRESS_PORT
    threads = Config.WAITRESS_THREADS

    logger.info(
        "Starting ACU Routing API with Waitress — host=%s port=%d threads=%d",
        host, port, threads,
    )

    serve(
        app,
        host=host,
        port=port,
        threads=threads,
        url_scheme="http",
        # Channel timeout: seconds to wait for request data before closing
        channel_timeout=120,
        # Max request header size (128 KB — generous for Swagger)
        max_request_header_size=131072,
        # Max request body size (100 MB — adjust if you accept large uploads)
        max_request_body_size=104857600,
    )
