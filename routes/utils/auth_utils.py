"""
Authentication utilities — Argon2 password hashing and JWT token handling.

FIX #22 — JWT secret is now validated at import time.  If JWT_SECRET_KEY is
not set in the environment (or is left as the dev placeholder), the app logs
a loud warning.  In a multi-worker or restarting deployment an ephemeral
secret would invalidate every live token on every restart; operators must set
the env var explicitly.  The fallback is still provided so unit tests and
local dev work without a .env, but the warning makes the misconfiguration
visible rather than silent.
"""

import logging
import secrets
import warnings
from datetime import datetime, timezone, timedelta
from typing import Optional

import jwt
from argon2 import PasswordHasher, Type
from argon2.exceptions import VerifyMismatchError, InvalidHashError

from config import Config

logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# Argon2 Password Hasher
# -----------------------------------------------------------------------------

_phaser = PasswordHasher(
    time_cost=3,
    memory_cost=65536,  # 64 MiB
    parallelism=4,
    hash_len=32,
    salt_len=16,
    type=Type.ID,
)


# -----------------------------------------------------------------------------
# Password Hashing & Verification
# -----------------------------------------------------------------------------

def hash_password(plain_password: str) -> str:
    """Hash a plain-text password with Argon2id."""
    return _phaser.hash(plain_password)


def verify_password(plain_password: str, password_hash: str) -> bool:
    """Verify a plain-text password against an Argon2 hash."""
    try:
        _phaser.verify(password_hash, plain_password)
        return True
    except (VerifyMismatchError, InvalidHashError):
        return False
    except Exception as e:
        logger.warning(f"Password verification raised unexpected error: {e}")
        return False


def check_needs_rehash(password_hash: str) -> bool:
    """Return True if the hash was produced with outdated Argon2 parameters."""
    try:
        return _phaser.check_needs_rehash(password_hash)
    except Exception:
        return False


# -----------------------------------------------------------------------------
# JWT Configuration
# FIX #22: warn loudly when JWT_SECRET_KEY is not explicitly set so that
# multi-worker / restarting deployments don't silently rotate secrets and
# invalidate all live tokens.
# -----------------------------------------------------------------------------

_DEV_PLACEHOLDER = "dev-secret-change-in-production"

_raw_secret = getattr(Config, "JWT_SECRET_KEY", None)

if not _raw_secret or _raw_secret == _DEV_PLACEHOLDER:
    _fallback = secrets.token_hex(32)
    warnings.warn(
        "JWT_SECRET_KEY is not set or is the dev placeholder. "
        "A random secret has been generated for this process. "
        "All tokens will be invalidated on every restart and will not be "
        "valid across multiple workers. "
        "Set JWT_SECRET_KEY in your .env file for production use.",
        stacklevel=2,
    )
    logger.warning(
        "JWT_SECRET_KEY missing or using dev placeholder — "
        "tokens are ephemeral and will not survive a process restart."
    )
    _JWT_SECRET = _fallback
else:
    _JWT_SECRET = _raw_secret

_JWT_ACCESS_EXPIRY = getattr(Config, "JWT_ACCESS_TOKEN_EXPIRES", timedelta(hours=24))
_JWT_ALGORITHM = "HS256"


def _get_expiry_seconds() -> int:
    if isinstance(_JWT_ACCESS_EXPIRY, timedelta):
        return int(_JWT_ACCESS_EXPIRY.total_seconds())
    return int(_JWT_ACCESS_EXPIRY)


# -----------------------------------------------------------------------------
# JWT Token Creation & Decoding
# -----------------------------------------------------------------------------

def create_access_token(user_id: int, role: str, extra_claims: Optional[dict] = None) -> str:
    """Create a signed JWT access token for an authenticated user."""
    now = datetime.now(timezone.utc)
    payload = {
        "sub":  str(user_id),
        "role": role,
        "type": "access",
        "iat":  now,
        "exp":  now + _JWT_ACCESS_EXPIRY,
        "jti":  secrets.token_hex(8),
    }
    if extra_claims:
        payload.update(extra_claims)
    return jwt.encode(payload, _JWT_SECRET, algorithm=_JWT_ALGORITHM)


def decode_access_token(token: str) -> Optional[dict]:
    """Decode and validate a JWT access token. Returns None if invalid."""
    if token.startswith("Bearer "):
        token = token[7:]
    token = token.strip()

    try:
        payload = jwt.decode(
            token,
            _JWT_SECRET,
            algorithms=[_JWT_ALGORITHM],
            options={
                "require": ["sub", "role", "type", "exp"],
                "verify_signature": True,
                "verify_exp": True,
                "verify_iat": True,
            },
        )
        if payload.get("type") != "access":
            return None
        return payload
    except jwt.ExpiredSignatureError:
        logger.debug("JWT expired")
        return None
    except jwt.InvalidTokenError as e:
        logger.debug(f"JWT invalid: {e}")
        return None
    except Exception as e:
        logger.warning(f"JWT decode raised unexpected error: {e}")
        return None


def get_token_from_header(auth_header: Optional[str]) -> Optional[str]:
    """Extract the raw JWT string from an Authorization header value."""
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    return auth_header[7:].strip()