"""
Flask decorators for authentication and RBAC authorization.

FIX #6 — require_auth now uses managed_db_session() so the scoped session
is properly released via .remove() on every request, preventing the
thread-local session from being reused in a closed/dirty state.
"""

import logging
from functools import wraps

from flask import jsonify, g, request

from routes.utils.auth_utils import get_token_from_header, decode_access_token
from routes.models import User, managed_db_session

logger = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# @require_auth — validates JWT and loads the user
# -----------------------------------------------------------------------------

def require_auth(f):
    """
    Verify that the request includes a valid JWT access token.

    On success, attaches to Flask's `g` object:
        g.current_user  -> User ORM instance
        g.current_token -> Decoded JWT payload dict

    On failure, returns 401/403 with a JSON error body.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        token = get_token_from_header(auth_header)

        if not token:
            return jsonify({"error": "Authentication required. Provide a Bearer token in the Authorization header."}), 401

        payload = decode_access_token(token)
        if not payload:
            return jsonify({"error": "Invalid or expired token."}), 401

        try:
            user_id = int(payload["sub"])
        except (ValueError, TypeError, KeyError):
            return jsonify({"error": "Invalid token payload."}), 401

        # FIX #6: managed_db_session() calls factory.remove() on exit,
        # ensuring the scoped session is fully released after each request.
        user = None
        with managed_db_session() as session:
            user = session.query(User).filter_by(id=user_id).first()
            if user is not None:
                session.expunge(user)   # detach so it survives session close

        if user is None:
            return jsonify({"error": "User not found."}), 401

        if not user.is_active:
            return jsonify({"error": "Account is disabled."}), 403

        g.current_user = user
        g.current_token = payload

        return f(*args, **kwargs)

    return decorated


# -----------------------------------------------------------------------------
# @require_role — restricts access by RBAC role
# -----------------------------------------------------------------------------

def require_role(*allowed_roles):
    """
    Restrict access to users whose role is one of *allowed_roles*.

    Must be applied AFTER @require_auth (depends on g.current_user).
    """
    allowed = set(allowed_roles)

    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            current_user = getattr(g, "current_user", None)
            if current_user is None:
                return jsonify({"error": "Authentication required."}), 401

            if not current_user.has_role(*allowed):
                return jsonify({
                    "error": "Permission denied.",
                    "required_roles": sorted(allowed),
                    "your_role": current_user.role,
                }), 403

            return f(*args, **kwargs)
        return decorated
    return decorator


# -----------------------------------------------------------------------------
# Convenience composites
# -----------------------------------------------------------------------------

def require_admin(f):
    """Shorthand for @require_auth + @require_role('admin')."""
    return require_auth(require_role("admin")(f))


def require_superuser_or_admin(f):
    """Shorthand for @require_auth + @require_role('superuser', 'admin')."""
    return require_auth(require_role("superuser", "admin")(f))