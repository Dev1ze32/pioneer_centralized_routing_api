"""
Authentication utilities — Argon2 password hashing and JWT token handling.

Dependencies
------------
    pip install argon2-cffi pyjwt

Usage
-----
    # Hash a password
    hash = hash_password("my-secret")

    # Verify a password
    ok = verify_password("my-secret", stored_hash)

    # Create a JWT for a logged-in user
    token = create_access_token(user_id=42, role="superuser")

    # Decode and validate a JWT from an Authorization header
    payload = decode_access_token("Bearer eyJ0eXAiOiJKV1Qi...")
    # -> {"sub": 42, "role": "superuser", "type": "access", ...}
"""

import logging
import secrets
import time
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

# Argon2id is the recommended variant (OWASP, Password Hashing Competition).
# Parameters: time_cost=3, memory_cost=65536 KiB (64 MiB), parallelism=4
# These are conservative defaults suitable for most server environments.
_phaser = PasswordHasher(
    time_cost=3,        # t=3   — number of iterations
    memory_cost=65536,  # m=64M — memory usage in KiB
    parallelism=4,      # p=4   — parallel threads
    hash_len=32,        # output hash length
    salt_len=16,        # random salt length
    type=Type.ID,
)


# -----------------------------------------------------------------------------
# Password Hashing & Verification
# -----------------------------------------------------------------------------

def hash_password(plain_password: str) -> str:
    """
    Hash a plain-text password with Argon2id.

    Returns
    -------
    str
        The Argon2-encoded hash string (includes salt + params).
        Safe to store directly in the DB password_hash column.
    """
    return _phaser.hash(plain_password)


def verify_password(plain_password: str, password_hash: str) -> bool:
    """
    Verify a plain-text password against an Argon2 hash.

    Returns
    -------
    bool
        True if the password matches the hash, False otherwise.
        Also returns False if the hash is malformed/invalid.
    """
    try:
        _phaser.verify(password_hash, plain_password)
        return True
    except (VerifyMismatchError, InvalidHashError):
        return False
    except Exception as e:
        logger.warning(f"Password verification raised unexpected error: {e}")
        return False


def check_needs_rehash(password_hash: str) -> bool:
    """
    Check whether the hash was produced with the current Argon2 parameters.

n    Use this after a successful verify() to transparently upgrade old hashes
    when you change hashing parameters:

        if verify_password(pw, hash) and check_needs_rehash(hash):
            user.password_hash = hash_password(pw)
            save(user)
    """
    try:
        return _phaser.check_needs_rehash(password_hash)
    except Exception:
        return False


# -----------------------------------------------------------------------------
# JWT Configuration
# -----------------------------------------------------------------------------

# Load from env or generate a cryptographically secure fallback.
# In production, ALWAYS set JWT_SECRET_KEY explicitly in your .env.
_JWT_SECRET = getattr(Config, "JWT_SECRET_KEY", None) or secrets.token_hex(32)

# Token lifetime: 24 hours for access tokens
_JWT_ACCESS_EXPIRY = getattr(Config, "JWT_ACCESS_TOKEN_EXPIRES", timedelta(hours=24))

# Algorithm — HS256 is fast and sufficient for server-side symmetric signing
_JWT_ALGORITHM = "HS256"


def _get_expiry_seconds() -> int:
    """Convert the configured expiry timedelta to integer seconds."""
    if isinstance(_JWT_ACCESS_EXPIRY, timedelta):
        return int(_JWT_ACCESS_EXPIRY.total_seconds())
    return int(_JWT_ACCESS_EXPIRY)


# -----------------------------------------------------------------------------
# JWT Token Creation & Decoding
# -----------------------------------------------------------------------------

def create_access_token(user_id: int, role: str, extra_claims: Optional[dict] = None) -> str:
    """
    Create a signed JWT access token for an authenticated user.

    Parameters
    ----------
    user_id : int
        The user's primary key (stored in the 'sub' claim).
    role : str
        The user's RBAC role (stored in the 'role' claim).
    extra_claims : dict, optional
        Additional claims to embed in the token payload.

    Returns
    -------
    str
        A compact-serialized JWT string.
    """
    now = datetime.now(timezone.utc)
    payload = {
        "sub":  str(user_id),          # subject = user id
        "role": role,                  # RBAC role
        "type": "access",              # token type discriminator
        "iat":  now,                   # issued at
        "exp":  now + _JWT_ACCESS_EXPIRY,  # expiration
        "jti":  secrets.token_hex(8),  # unique token ID (revocation support)
    }
    if extra_claims:
        payload.update(extra_claims)

    return jwt.encode(payload, _JWT_SECRET, algorithm=_JWT_ALGORITHM)


def decode_access_token(token: str) -> Optional[dict]:
    """
    Decode and validate a JWT access token.

    Parameters
    ----------
    token : str
        The JWT string. May optionally include the "Bearer " prefix.

    Returns
    -------
    dict or None
        The decoded payload if valid, None if the token is expired,
        malformed, or signature verification fails.
    """
    # Strip "Bearer " prefix if present
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
        # Extra guard: only accept access tokens
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
    """
    Extract the raw JWT string from an Authorization header value.

    Returns
    -------
    str or None
        The token string without the "Bearer " prefix, or None if the
        header is missing or malformed.
    """
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    return auth_header[7:].strip()