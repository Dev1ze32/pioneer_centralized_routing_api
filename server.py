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
from logging.handlers import RotatingFileHandler
import sys
import os

from waitress import serve
from whitenoise import WhiteNoise # 1. Import WhiteNoise

from app import create_app
from config import Config

# Setup file handler alongside stream handler
file_handler = RotatingFileHandler(
    "api_server.log",
    maxBytes=10 * 1024 * 1024,  # 10 MB limit
    backupCount=5               # Keep 5 backup logs
)
stream_handler = logging.StreamHandler(sys.stdout)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    handlers=[file_handler, stream_handler]
)

logger = logging.getLogger(__name__)

if __name__ == "__main__":
    # Add scripts directory to path so we can import the IP updater
    sys.path.append(os.path.join(os.path.dirname(__file__), 'scripts'))
    from update_ip import update_env_ip

    # Dynamically update the .env file with the server's current IP before booting
    update_env_ip()
    
    app = create_app()

    # 2. Wrap your app with WhiteNoise. 
    # Point 'root' to your website folder (e.g., the 'frontend' folder we ignored in Git)
    # index_file=True tells it to automatically serve index.html when people visit the base URL
    app_with_static = WhiteNoise(app, root=os.path.join("frontend", "Routing-Frontend"), index_file=True)

    host = "0.0.0.0"
    port = Config.WAITRESS_PORT
    threads = Config.WAITRESS_THREADS

    logger.info(
        "Starting ACU Routing API and Frontend with Waitress — host=%s port=%d threads=%d",
        host, port, threads,
    )

    # 3. Pass the wrapped app to Waitress instead of the raw API app
    serve(
        app_with_static, 
        host=host,
        port=port,
        threads=threads,
        connection_limit=1000, # Increased from default 100
        url_scheme="http",
        channel_timeout=120,
        max_request_header_size=131072,
        max_request_body_size=1048576,
    )