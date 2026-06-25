"""
Authentication blueprint — registration and login.

Rate limits (applied per remote IP via Flask-Limiter):
    POST /api/auth/login     — Config.RATE_LIMIT_LOGIN    (default 10/minute)
    POST /api/auth/register  — Config.RATE_LIMIT_REGISTER (default 5/minute)
"""

import logging

from flask import Blueprint, jsonify, request, g

from extension import limiter          # ← extension.py, not app.py
from config import Config
from routes.utils.auth_utils import (
    hash_password,
    verify_password,
    check_needs_rehash,
    create_access_token,
)
from routes.utils.decorators import require_auth, require_role
from routes.utils.log_utils import log_action
from routes.models import User, managed_db_session

logger = logging.getLogger(__name__)

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


def _require_admin(f):
    return require_auth(require_role("admin")(f))


# ── POST /api/auth/register ───────────────────────────────────────────────────

@auth_bp.post("/register")
@_require_admin
@limiter.limit(Config.RATE_LIMIT_REGISTER)
def register():
    """
    Create a new user account. Admin only.

    ---
    tags:
      - Authentication
    security:
      - Bearer: []
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required: [username, password]
          properties:
            username:
              type: string
              minLength: 3
              maxLength: 50
              example: alice_smith
            password:
              type: string
              minLength: 8
              example: SecurePass123!
            role:
              type: string
              enum: [user, superuser, admin]
              default: user
    responses:
      201:
        description: User created successfully
      400:
        description: Missing or invalid fields
      401:
        description: Missing or invalid token
      403:
        description: Admin access required
      409:
        description: Username already exists
      429:
        description: Too many requests
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    username = (body.get("username") or "").strip()
    password = body.get("password") or ""

    if not username:
        return jsonify({"error": "username is required"}), 400
    if len(username) < 3 or len(username) > 50:
        return jsonify({"error": "username must be between 3 and 50 characters"}), 400
    if not password:
        return jsonify({"error": "password is required"}), 400
    if len(password) < 8:
        return jsonify({"error": "password must be at least 8 characters"}), 400

    requested_role = (body.get("role") or "user").strip().lower()
    if requested_role not in User.ROLES:
        return jsonify({"error": f"Invalid role. Must be one of: {sorted(User.ROLES)}"}), 400

    password_hash = hash_password(password)

    with managed_db_session() as session:
        existing = session.query(User).filter_by(username=username).first()
        if existing:
            return jsonify({"error": "Username already exists", "username": username}), 409

        new_user = User(
            username=username,
            password_hash=password_hash,
            role=requested_role,
            is_active=True,
        )
        session.add(new_user)
        session.flush()

        user_id   = new_user.id
        user_role = new_user.role

    admin = g.current_user
    log_action(
        action="Created user account",
        description=(
            f"Admin '{admin.username}' created a new '{requested_role}' "
            f"account for '{username}' (user ID {user_id})."
        ),
        target_type="user",
        target_id=str(user_id),
        extra={"new_username": username, "assigned_role": requested_role},
    )

    return jsonify({
        "message":  "User created successfully",
        "user_id":  user_id,
        "username": username,
        "role":     user_role,
    }), 201


# ── POST /api/auth/login ──────────────────────────────────────────────────────

@auth_bp.post("/login")
@limiter.limit(Config.RATE_LIMIT_LOGIN)
def login():
    """
    Authenticate and receive a JWT access token.

    ---
    tags:
      - Authentication
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required: [username, password]
          properties:
            username:
              type: string
              example: alice_smith
            password:
              type: string
              example: SecurePass123!
    responses:
      200:
        description: Login successful, JWT token returned
      400:
        description: Missing fields
      401:
        description: Invalid username or password
      403:
        description: Account is disabled
      429:
        description: Too many login attempts
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    username = (body.get("username") or "").strip()
    password = body.get("password") or ""

    if not username or not password:
        return jsonify({"error": "username and password are required"}), 400

    user = None
    with managed_db_session() as session:
        user = session.query(User).filter_by(username=username).first()
        if user is not None:
            session.expunge(user)

    if user is None:
        return jsonify({"error": "Invalid username or password"}), 401

    if not user.is_active:
        return jsonify({"error": "Account is disabled"}), 403

    if not verify_password(password, user.password_hash):
        return jsonify({"error": "Invalid username or password"}), 401

    if check_needs_rehash(user.password_hash):
        try:
            new_hash = hash_password(password)
            with managed_db_session() as s:
                refreshed = s.query(User).filter_by(id=user.id).first()
                if refreshed:
                    refreshed.password_hash = new_hash
        except Exception:
            logger.warning("Password rehash failed — login continues without rehash.")

    token = create_access_token(user_id=user.id, role=user.role)

    return jsonify({
        "message":      "Login successful",
        "access_token": token,
        "token_type":   "Bearer",
        "user": {
            "id":       user.id,
            "username": user.username,
            "role":     user.role,
        },
    }), 200


# ── GET /api/auth/me ──────────────────────────────────────────────────────────

@auth_bp.get("/me")
@require_auth
def me():
    """
    Get the currently authenticated user's details.

    ---
    tags:
      - Authentication
    security:
      - Bearer: []
    responses:
      200:
        description: Current user details
      401:
        description: Missing or invalid token
    """
    return jsonify(g.current_user.to_dict()), 200