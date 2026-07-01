"""
Authentication blueprint — registration and login.

Rate limits (applied per remote IP via Flask-Limiter):
    POST /api/auth/login     — Config.RATE_LIMIT_LOGIN    (default 10/minute)
    POST /api/auth/register  — Config.RATE_LIMIT_REGISTER (default 5/minute)
"""

import logging

from flask import Blueprint, jsonify, request, g, send_file, abort
import os

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


# ── POST /api/auth/verify-password ────────────────────────────────────────────

@auth_bp.post("/verify-password")
@require_auth
@limiter.limit(Config.RATE_LIMIT_LOGIN)
def verify_password_endpoint():
    """
    Verify the currently authenticated user's password without issuing a new token.
    Used for confirming identity before destructive actions.

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
          required: [password]
          properties:
            password:
              type: string
              example: SecurePass123!
    responses:
      200:
        description: Password verified
      400:
        description: Missing password
      401:
        description: Invalid password or missing token
      429:
        description: Too many attempts
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    password = body.get("password") or ""
    if not password:
        return jsonify({"error": "password is required"}), 400

    user = g.current_user
    if not verify_password(password, user.password_hash):
        return jsonify({"error": "Incorrect password"}), 401

    return jsonify({"message": "Password verified"}), 200


# ── GET /api/auth/users ───────────────────────────────────────────────────────

@auth_bp.get("/users")
@_require_admin
def get_users():
    """
    Get a list of all users. Admin only.

    ---
    tags:
      - Authentication
    security:
      - Bearer: []
    responses:
      200:
        description: List of users
      401:
        description: Missing or invalid token
      403:
        description: Admin access required
    """
    with managed_db_session() as session:
        users = session.query(User).order_by(User.username).all()
        # BUG-04 FIX: Expunge all ORM objects before the session closes so
        # that to_dict() cannot lazy-load anything after session teardown.
        # This prevents DetachedInstanceError if relationships are ever added.
        session.expunge_all()
        return jsonify([u.to_dict() for u in users]), 200


# ── PATCH /api/auth/users/<user_id> ───────────────────────────────────────────

# BUG-09 FIX: Use <int:user_id> so Flask coerces and validates the path
# parameter. Sending a non-integer (e.g. /users/abc) now returns 404
# from Flask's URL matcher instead of a 500 DataError from SQLAlchemy.
@auth_bp.patch("/users/<int:user_id>")
@_require_admin
def update_user(user_id):
    """
    Update a user's details (password, role, active status). Admin only.

    ---
    tags:
      - Authentication
    security:
      - Bearer: []
    parameters:
      - name: user_id
        in: path
        type: string
        required: true
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            password:
              type: string
              minLength: 8
            role:
              type: string
              enum: [user, superuser, admin]
            is_active:
              type: boolean
    responses:
      200:
        description: User updated successfully
      400:
        description: Invalid fields
      401:
        description: Missing or invalid token
      403:
        description: Admin access required
      404:
        description: User not found
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    new_password = body.get("password")
    new_role = body.get("role")
    new_is_active = body.get("is_active")

    with managed_db_session() as session:
        user = session.query(User).filter_by(id=user_id).first()
        if not user:
            return jsonify({"error": "User not found"}), 404

        changes = []

        if new_password:
            if len(new_password) < 8:
                return jsonify({"error": "password must be at least 8 characters"}), 400
            user.password_hash = hash_password(new_password)
            changes.append("password reset")

        if new_role:
            requested_role = new_role.strip().lower()
            if requested_role not in User.ROLES:
                return jsonify({"error": f"Invalid role. Must be one of: {sorted(User.ROLES)}"}), 400
            if user.role != requested_role:
                changes.append(f"role changed from {user.role} to {requested_role}")
                user.role = requested_role

        if new_is_active is not None:
            active_bool = bool(new_is_active)
            if user.is_active != active_bool:
                status = "enabled" if active_bool else "disabled"
                changes.append(f"account {status}")
                user.is_active = active_bool

        if not changes:
            return jsonify({"message": "No changes requested"}), 200

        session.flush()

        admin = g.current_user
        log_action(
            action="Updated user account",
            description=f"Admin '{admin.username}' updated user '{user.username}': {', '.join(changes)}.",
            target_type="user",
            target_id=str(user.id),
            extra={"changes": changes},
        )

        return jsonify({
            "message": "User updated successfully",
            "user": user.to_dict()
        }), 200


# ── DELETE /api/auth/users/<user_id> ──────────────────────────────────────────

@auth_bp.delete("/users/<int:user_id>")
@_require_admin
def delete_user(user_id):
    """
    Delete a user account. Admin only.

    ---
    tags:
      - Authentication
    security:
      - Bearer: []
    parameters:
      - name: user_id
        in: path
        type: string
        required: true
    responses:
      200:
        description: User deleted successfully
      400:
        description: Cannot delete the last admin
      401:
        description: Missing or invalid token
      403:
        description: Admin access required
      404:
        description: User not found
    """
    with managed_db_session() as session:
        user = session.query(User).filter_by(id=user_id).first()
        if not user:
            return jsonify({"error": "User not found"}), 404

        if user.role == "admin":
            admin_count = session.query(User).filter_by(role="admin").count()
            if admin_count <= 1:
                return jsonify({"error": "Cannot delete the last admin account."}), 400

        # Log action before deleting
        admin = g.current_user
        log_action(
            action="Deleted user account",
            description=f"Admin '{admin.username}' deleted user '{user.username}' (role: {user.role}).",
            target_type="user",
            target_id=str(user.id),
        )

        session.delete(user)
        session.commit()
        return jsonify({"message": "User deleted"}), 200

# ── GET /api/auth/docs/deployment ─────────────────────────────────────────────

@auth_bp.get("/docs/deployment")
@_require_admin
def download_deployment_manual():
    """
    Securely download the deployment and maintenance manual.
    Must be an authenticated Admin.
    """
    # The file is in the root directory, one level up from the 'routes' folder
    root_dir = os.path.dirname(os.path.dirname(__file__))
    file_path = os.path.join(root_dir, "ACU_Routing_Deployment_Maintenance_Manual.pdf")
    
    if not os.path.exists(file_path):
        logger.error(f"Manual not found at {file_path}")
        return jsonify({"error": "Manual file is missing from the server"}), 404

    return send_file(
        file_path,
        as_attachment=True,
        download_name="ACU_Routing_Deployment_Maintenance_Manual.pdf",
        mimetype="application/pdf"
    )