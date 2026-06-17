"""
Shared PostgreSQL connection helper — SQLAlchemy Core.

Connection pooling
-------------------
A single Engine (and its QueuePool) is created once at import time via
_get_engine(). pool_size=2 / max_overflow=18 gives the same effective
ceiling of 20 connections as the previous psycopg2 ThreadedConnectionPool
(minconn=2, maxconn=20); the pool now grows/shrinks lazily rather than
pre-opening two connections, which is the normal SQLAlchemy behaviour.

Usage
-----
    with managed_connection() as conn:
        result = conn.execute(text("SELECT ..."), {"param": value})
        row = result.mappings().first()      # dict-like row, or None
        rows = result.mappings().all()       # list of dict-like rows

The context manager commits on success and rolls back + releases the
connection on error — equivalent to the old try/commit/except/rollback/
finally/release pattern.

get_connection() / release_connection() are kept as a thin pair for call
sites that prefer the previous explicit try/except/finally shape rather
than the context manager.
"""

import contextlib
import logging
from typing import Optional

from sqlalchemy import create_engine
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.engine.url import URL

from config import Config

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Engine — created once when the module is first imported. The Engine owns
# the connection pool; there is no separate pool object to manage by hand.
# ---------------------------------------------------------------------------
_engine: Optional[Engine] = None


def _get_engine() -> Engine:
    """Return the shared engine, creating it (and its pool) on first call."""
    global _engine
    if _engine is None:
        url = URL.create(
            drivername="postgresql+psycopg2",
            username=Config.DB_USER,
            password=Config.DB_PASSWORD,
            host=Config.DB_HOST,
            port=int(Config.DB_PORT),
            database=Config.DB_NAME,
        )
        _engine = create_engine(
            url,
            pool_size=2,         # matches previous ThreadedConnectionPool minconn
            max_overflow=18,     # 2 + 18 = 20, matches previous maxconn
            pool_pre_ping=True,  # transparently recycles dropped/stale connections
        )
        logger.info("SQLAlchemy engine created (pool_size=2, max_overflow=18).")
    return _engine


def get_connection() -> Connection:
    """Borrow a connection from the pool.

    The caller is responsible for calling release_connection() when done —
    use the managed_connection() context manager to handle this automatically.
    """
    return _get_engine().connect()


def release_connection(conn: Connection) -> None:
    """Return a connection to the pool."""
    try:
        conn.close()
    except Exception:
        pass


@contextlib.contextmanager
def managed_connection():
    """Context manager that borrows, commits/rolls-back, and returns a connection.

    Usage:
        with managed_connection() as conn:
            result = conn.execute(text(...), {...})
            # commit happens automatically on exit
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