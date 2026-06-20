"""
SQLAlchemy ORM models for the ACU Routing API.

FIX #17 — Single engine: this module now imports and reuses _get_engine()
from db.py instead of creating its own engine. Both Core (db.py) and ORM
(models.py) share one pool, keeping the total connection ceiling at 20.

FIX #5 / #6 — Scoped session lifecycle: managed_db_session() now calls
session.remove() (not session.close()) so the scoped-session registry
releases the session properly and the next call in the same thread gets a
fresh session. Direct callers of get_db_session() are expected to call
_session_factory.remove() when done; the managed context manager handles
this automatically.
"""

import logging
from contextlib import contextmanager

from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import declarative_base, scoped_session, sessionmaker
from sqlalchemy.sql import func

from db import _get_engine   # FIX #17: reuse the shared engine

logger = logging.getLogger(__name__)

Base = declarative_base()


# -----------------------------------------------------------------------------
# User Model
# -----------------------------------------------------------------------------

class User(Base):
    """
    Application user for authentication and RBAC.

    Fields
    ------
    id : int
        Auto-increment primary key.
    username : str
        Unique login name (case-sensitive, max 50 chars).
    password_hash : str
        Argon2id hash of the user's password. Never store plain text.
    role : str
        One of 'user', 'superuser', 'admin'. Defaults to 'user'.
    is_active : bool
        Set to False to soft-disable an account without deleting it.
    created_at : datetime
        UTC timestamp of account creation.
    updated_at : datetime
        UTC timestamp of last modification (auto-updated by trigger + SQLA).
    """

    __tablename__ = "users"

    id            = Column(Integer, primary_key=True, autoincrement=True)
    username      = Column(String(50), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role          = Column(String(20), nullable=False, default="user")
    is_active     = Column(Boolean, nullable=False, default=True)
    created_at    = Column(DateTime(timezone=True), server_default=func.now())
    updated_at    = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Valid RBAC roles — kept in sync with the DB CHECK constraint
    ROLES = {"user", "superuser", "admin"}

    # Role hierarchy for quick permission checks (higher = more access)
    ROLE_LEVEL = {
        "user":      1,
        "superuser": 2,
        "admin":     3,
    }

    def has_role(self, *required_roles: str) -> bool:
        """Return True if the user's role is one of *required_roles*."""
        return self.role in required_roles

    def has_minimum_role(self, minimum_role: str) -> bool:
        """Return True if the user's role level is >= *minimum_role*."""
        return self.ROLE_LEVEL.get(self.role, 0) >= self.ROLE_LEVEL.get(minimum_role, 0)

    def to_dict(self, include_sensitive: bool = False) -> dict:
        """Serialize the user to a dictionary."""
        data = {
            "id":         self.id,
            "username":   self.username,
            "role":       self.role,
            "is_active":  self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_sensitive:
            data["password_hash"] = self.password_hash
        return data

    def __repr__(self) -> str:
        return f"<User(id={self.id}, username='{self.username}', role='{self.role}', active={self.is_active})>"


# -----------------------------------------------------------------------------
# ORM Session Factory — binds to the shared engine from db.py
# FIX #17: no second engine; FIX #5/#6: use .remove() not .close()
# -----------------------------------------------------------------------------

_session_factory: scoped_session | None = None


def _get_session_factory() -> scoped_session:
    global _session_factory
    if _session_factory is None:
        _session_factory = scoped_session(
            sessionmaker(bind=_get_engine())
        )
        logger.info("ORM scoped_session factory created (bound to shared engine).")
    return _session_factory


def get_db_session():
    """
    Return the scoped ORM session for the current thread.

    IMPORTANT: always call _get_session_factory().remove() (or use
    managed_db_session()) when finished so the scoped-session registry
    releases the session and returns the underlying connection to the pool.
    """
    return _get_session_factory()()


@contextmanager
def managed_db_session():
    """
    Context manager for ORM sessions.

    Commits on success, rolls back on error, and always removes the session
    from the scoped-session registry so the connection is returned to the pool.

    FIX #5/#6: calls session_factory.remove() instead of session.close(),
    which is the correct way to release a scoped_session.

    Usage
    -----
        with managed_db_session() as session:
            user = session.query(User).filter_by(username="alice").first()
    """
    factory = _get_session_factory()
    session = factory()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        factory.remove()   # FIX #5/#6: properly releases scope + connection