"""
Flask decorators for authentication and RBAC authorization.

Decorators
----------
    @require_auth
        Ensures the request carries a valid JWT. Injects
        `g.current_user` (User instance) and `g.current_token` (payload dict).

    @require_role("superuser", "admin")
        Requires @require_auth first. Then checks that the authenticated
        user's role is one of the allowed roles. Returns 403 otherwise.

Usage Examples
--------------
    @items_bp.get("/items")
    @require_auth
    def search_items():
        # g.current_user and g.current_token are available here
        ...

    @items_bp.post("/items")
    @require_role("superuser", "admin")
    def create_item():
        # Only superuser or admin can reach this
        ...

    @some_bp.get("/admin/logs")
    @require_role("admin")
    def view_logs():
        # Only admin can reach this
        ...
"""

import logging
from functools import wraps

from flask import jsonify, g, request

from routes.utils.auth_utils import get_token_from_header, decode_access_token
from routes.models import User, get_db_session

logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# @require_auth — validates JWT and loads the user
# -----------------------------------------------------------------------------

def require_auth(f):
    """
    Verify that the request includes a valid JWT access token.

    On success, attaches to Flask's `g` object:
        g.current_user  -> User ORM instance (or None if user deleted)
        g.current_token -> Decoded JWT payload dict

    On failure, returns 401 with a JSON error body. The decorated route
    function is NOT called.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        # 1. Extract token from Authorization header
        auth_header = request.headers.get("Authorization", "")
        token = get_token_from_header(auth_header)

        if not token:
            return jsonify({"error": "Authentication required. Provide a Bearer token in the Authorization header."}), 401

        # 2. Decode and validate the JWT
        payload = decode_access_token(token)
        if not payload:
            return jsonify({"error": "Invalid or expired token."}), 401

        # 3. Load the user from the database
        try:
            user_id = int(payload["sub"])
        except (ValueError, TypeError, KeyError):
            return jsonify({"error": "Invalid token payload."}), 401

        session = get_db_session()
        try:
            user = session.query(User).filter_by(id=user_id).first()
        finally:
            session.close()

        if user is None:
            return jsonify({"error": "User not found."}), 401

        if not user.is_active:
            return jsonify({"error": "Account is disabled."}), 403

        # 4. Attach to Flask's application context
        g.current_user = user
        g.current_token = payload

        # 5. Call the actual route
        return f(*args, **kwargs)

    return decorated


# -----------------------------------------------------------------------------
# @require_role — restricts access by RBAC role
# -----------------------------------------------------------------------------

def require_role(*allowed_roles):
    """
    Restrict access to users whose role is one of *allowed_roles*.

    This decorator MUST be used AFTER @require_auth (it depends on
    g.current_user being set).

    Parameters
    ----------
    *allowed_roles : str
        One or more role names from {"user", "superuser", "admin"}.

    Example
    -------
        @items_bp.post("/items")
        @require_auth
        @require_role("superuser", "admin")
        def create_item():
            ...
    """
    allowed = set(allowed_roles)

    def decorator(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            # Ensure @require_auth ran first
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
# Convenience composites (optional — reduces repetition)
# -----------------------------------------------------------------------------

def require_admin(f):
    """Shorthand for @require_auth + @require_role('admin')."""
    return require_auth(require_role("admin")(f))


def require_superuser_or_admin(f):
    """Shorthand for @require_auth + @require_role('superuser', 'admin')."""
    return require_auth(require_role("superuser", "admin")(f))