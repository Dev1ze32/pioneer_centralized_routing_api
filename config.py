"""
Centralized configuration.
Loads environment variables from .env once.

All tunables live here so no deployment setting is buried in code.
Copy .env.example → .env and fill in values for your server.
"""

import logging
import os
from datetime import timedelta

from dotenv import load_dotenv

load_dotenv()


def _safe_int(key: str, default: str) -> int:
    """Parse an env var as int, falling back to *default* on bad input."""
    raw = os.getenv(key, default)
    try:
        return int(raw)
    except (ValueError, TypeError):
        logging.getLogger(__name__).warning(
            "Invalid value '%s' for %s — using default %s.", raw, key, default
        )
        return int(default)


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
    DB_POOL_SIZE            = _safe_int("DB_POOL_SIZE",            "20")
    DB_MAX_OVERFLOW         = _safe_int("DB_MAX_OVERFLOW",         "10")
    # Seconds to wait for a free pool slot before raising TimeoutError (→ 503)
    DB_POOL_TIMEOUT         = _safe_int("DB_POOL_TIMEOUT",         "10")
    # Recycle connections older than N seconds (prevents silent stale-TCP drops)
    DB_POOL_RECYCLE         = _safe_int("DB_POOL_RECYCLE",         "1800")
    # Seconds to wait when opening a fresh DB connection
    DB_CONNECT_TIMEOUT      = _safe_int("DB_CONNECT_TIMEOUT",      "5")
    # Milliseconds before Postgres cancels a running statement
    DB_STATEMENT_TIMEOUT_MS = _safe_int("DB_STATEMENT_TIMEOUT_MS", "30000")

    # ── JWT ───────────────────────────────────────────────────────────────────
    # IMPORTANT: set a strong random value in .env.
    # auth_utils.py emits a loud warning on startup if this is left as-is.
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "dev-secret-change-in-production")

    JWT_ACCESS_TOKEN_EXPIRES = timedelta(
        hours=_safe_int("JWT_ACCESS_TOKEN_EXPIRES_HOURS", "24")
    )

    # ── Rate limiting ─────────────────────────────────────────────────────────
    # Flask-Limiter format: "N/period" where period = second | minute | hour | day
    RATE_LIMIT_LOGIN    = os.getenv("RATE_LIMIT_LOGIN",    "10/minute")
    RATE_LIMIT_REGISTER = os.getenv("RATE_LIMIT_REGISTER", "5/minute")
    # Low-Risk fix: raised from 300/minute → 2000/minute.
    # The bulk-update endpoint means a full save is now 1 request, but 3-4
    # concurrent users from the same office IP could still hit the old limit.
    # The login endpoint keeps its own strict 10/minute limit unchanged.
    RATE_LIMIT_DEFAULT  = os.getenv("RATE_LIMIT_DEFAULT",  "2000/minute")

    # ── Waitress (read by waitress_server.py) ─────────────────────────────────
    WAITRESS_THREADS = _safe_int("WAITRESS_THREADS", "8")
    WAITRESS_PORT    = _safe_int("WAITRESS_PORT",    "5000")