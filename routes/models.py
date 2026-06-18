"""
SQLAlchemy ORM models for the ACU Routing API.

This module provides the declarative User model used by the auth system.
It uses a separate ORM session/scoped_session from the Core engine in db.py
so that both patterns (Core for existing routes, ORM for auth) can coexist.

Usage
-----
    from routes.models import User, get_db_session
    session = get_db_session()
    user = session.query(User).filter_by(username="alice").first()
"""

import logging
from contextlib import contextmanager

from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime
from sqlalchemy.orm import declarative_base, scoped_session, sessionmaker
from sqlalchemy.sql import func

from config import Config

logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# Shared declarative base
# -----------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    # Helpers
    # -------------------------------------------------------------------------

    def has_role(self, *required_roles: str) -> bool:
        """Return True if the user's role is one of *required_roles*."""
        return self.role in required_roles

    def has_minimum_role(self, minimum_role: str) -> bool:
        """
        Return True if the user's role level is >= *minimum_role*.

        Example
        -------
            user.has_minimum_role("superuser")  # True for superuser and admin
        """
        return self.ROLE_LEVEL.get(self.role, 0) >= self.ROLE_LEVEL.get(minimum_role, 0)

    def to_dict(self, include_sensitive: bool = False) -> dict:
        """Serialize the user to a dictionary."""
        data = {
            "id":        self.id,
            "username":  self.username,
            "role":      self.role,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_sensitive:
            data["password_hash"] = self.password_hash
        return data

    def __repr__(self) -> str:
        return f"<User(id={self.id}, username='{self.username}', role='{self.role}', active={self.is_active})>"


# -----------------------------------------------------------------------------
# ORM Session Factory (scoped, thread-safe)
# -----------------------------------------------------------------------------

_engine = None
_session_factory = None

def _get_orm_engine():
    """Create or return the shared ORM engine (mirrors db.py's Core engine)."""
    global _engine
    if _engine is None:
        db_url = (
            f"postgresql+psycopg2://{Config.DB_USER}:{Config.DB_PASSWORD}"
            f"@{Config.DB_HOST}:{Config.DB_PORT}/{Config.DB_NAME}"
        )
        _engine = create_engine(
            db_url,
            pool_size=2,
            max_overflow=18,
            pool_pre_ping=True,
        )
        logger.info("Auth ORM engine created.")
    return _engine


def get_db_session():
    """
    Return a new scoped ORM session.

n    The caller must call session.close() when done, or use
    managed_db_session() as a context manager.
    """
    global _session_factory
    if _session_factory is None:
        _session_factory = scoped_session(
            sessionmaker(bind=_get_orm_engine())
        )
    return _session_factory()


@contextmanager
def managed_db_session():
    """
    Context manager for ORM sessions.

    Commits on success, rolls back on error, always closes the session.

    Usage
    -----
        with managed_db_session() as session:
            user = session.query(User).filter_by(username="alice").first()
    """
    session = get_db_session()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()