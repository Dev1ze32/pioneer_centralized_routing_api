"""
Centralized configuration.
Loads environment variables from .env once.

All tunables live here so no deployment setting is buried in code.
Copy .env.example → .env and fill in values for your server.
"""

import os
from datetime import timedelta

from dotenv import load_dotenv

load_dotenv()


class Config:
    # ── PostgreSQL ────────────────────────────────────────────────────────────
    DB_HOST     = os.getenv("DB_HOST",     "localhost")
    DB_PORT     = os.getenv("DB_PORT",     "5432")
    DB_NAME     = os.getenv("DB_NAME",     "routing_db")
    DB_USER     = os.getenv("DB_USER",     "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

    # ── Connection pool ───────────────────────────────────────────────────────
    # Rule of thumb: pool_size >= number of server threads.
    # Default tuned for waitress with 8 threads.
    # max_overflow gives burst headroom; total max DB connections = pool_size + max_overflow.
    DB_POOL_SIZE            = int(os.getenv("DB_POOL_SIZE",            "20"))
    DB_MAX_OVERFLOW         = int(os.getenv("DB_MAX_OVERFLOW",         "10"))
    # Seconds to wait for a free pool slot before raising TimeoutError (→ 503)
    DB_POOL_TIMEOUT         = int(os.getenv("DB_POOL_TIMEOUT",         "10"))
    # Recycle connections older than N seconds (prevents silent stale-TCP drops)
    DB_POOL_RECYCLE         = int(os.getenv("DB_POOL_RECYCLE",         "1800"))
    # Seconds to wait when opening a fresh DB connection
    DB_CONNECT_TIMEOUT      = int(os.getenv("DB_CONNECT_TIMEOUT",      "5"))
    # Milliseconds before Postgres cancels a running statement
    DB_STATEMENT_TIMEOUT_MS = int(os.getenv("DB_STATEMENT_TIMEOUT_MS", "30000"))

    # ── JWT ───────────────────────────────────────────────────────────────────
    # IMPORTANT: set a strong random value in .env.
    # auth_utils.py emits a loud warning on startup if this is left as-is.
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "dev-secret-change-in-production")

    JWT_ACCESS_TOKEN_EXPIRES = timedelta(
        hours=int(os.getenv("JWT_ACCESS_TOKEN_EXPIRES_HOURS", "24"))
    )

    # ── Rate limiting ─────────────────────────────────────────────────────────
    # Flask-Limiter format: "N/period" where period = second | minute | hour | day
    RATE_LIMIT_LOGIN    = os.getenv("RATE_LIMIT_LOGIN",    "10/minute")
    RATE_LIMIT_REGISTER = os.getenv("RATE_LIMIT_REGISTER", "5/minute")
    RATE_LIMIT_DEFAULT  = os.getenv("RATE_LIMIT_DEFAULT",  "300/minute")

    # ── Waitress (read by waitress_server.py) ─────────────────────────────────
    WAITRESS_THREADS = int(os.getenv("WAITRESS_THREADS", "8"))
    WAITRESS_PORT    = int(os.getenv("WAITRESS_PORT",    "5000"))