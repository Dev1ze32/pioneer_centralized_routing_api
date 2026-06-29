"""
Shared PostgreSQL connection helper — SQLAlchemy Core.

All pool and timeout settings come from Config so they can be tuned per
environment without touching code.

Pool sizing guide
-----------------
pool_size     — connections kept open permanently (should equal workers × threads)
max_overflow  — extra connections allowed under burst load (returned to pool after use)
pool_timeout  — seconds to wait for a free slot before raising (callers catch → 503)
pool_recycle  — recycle connections older than N seconds (avoids silent TCP drops)
pool_pre_ping — run "SELECT 1" before handing a connection out (catches stale sockets)

connect_args
    connect_timeout       — TCP handshake timeout when opening a new connection
    options statement_timeout — Postgres cancels any query running longer than N ms

Usage
-----
    with managed_connection() as conn:
        result = conn.execute(text("SELECT ..."), {"param": value})
        row    = result.mappings().first()   # dict-like or None
        rows   = result.mappings().all()     # list of dict-like rows

    # Explicit style (for code paths that prefer try/except/finally):
    conn = get_connection()
    try:
        ...
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        release_connection(conn)
"""

import contextlib
import logging
from typing import Optional

from sqlalchemy import create_engine
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.engine.url import URL

from config import Config

logger = logging.getLogger(__name__)

_engine: Optional[Engine] = None


def _get_engine() -> Engine:
    """Return the single shared engine, creating it on first call."""
    global _engine
    if _engine is None:
        url = URL.create(
            drivername="postgresql+psycopg",
            username=Config.DB_USER,
            password=Config.DB_PASSWORD,
            host=Config.DB_HOST,
            port=int(Config.DB_PORT),
            database=Config.DB_NAME,
        )
        _engine = create_engine(
            url,
            pool_size=Config.DB_POOL_SIZE,
            max_overflow=Config.DB_MAX_OVERFLOW,
            pool_timeout=Config.DB_POOL_TIMEOUT,
            pool_recycle=Config.DB_POOL_RECYCLE,
            pool_pre_ping=True,
            connect_args={
                "connect_timeout": Config.DB_CONNECT_TIMEOUT,
                "options": f"-c statement_timeout={Config.DB_STATEMENT_TIMEOUT_MS}",
            },
        )
        logger.info(
            "SQLAlchemy engine created — pool_size=%d max_overflow=%d "
            "pool_timeout=%ds pool_recycle=%ds statement_timeout=%dms",
            Config.DB_POOL_SIZE,
            Config.DB_MAX_OVERFLOW,
            Config.DB_POOL_TIMEOUT,
            Config.DB_POOL_RECYCLE,
            Config.DB_STATEMENT_TIMEOUT_MS,
        )
    return _engine


def get_connection() -> Connection:
    """Borrow a connection from the pool (caller must release it)."""
    return _get_engine().connect()


def release_connection(conn: Connection) -> None:
    """Return a connection to the pool."""
    try:
        conn.close()
    except Exception:
        pass


@contextlib.contextmanager
def managed_connection():
    """
    Context manager: borrow → yield → commit/rollback → return to pool.

    Raises sqlalchemy.exc.TimeoutError if the pool is exhausted and no slot
    becomes free within DB_POOL_TIMEOUT seconds.  The global error handler in
    app.py converts that to a 503 response.
    """
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        release_connection(conn)