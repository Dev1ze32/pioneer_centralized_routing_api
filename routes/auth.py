"""
Authentication blueprint — registration and login.

Endpoints
---------
    POST /api/auth/register
        Anyone can register as a default 'user' role.
        Only an existing 'admin' can create 'superuser' or 'admin' accounts.

    POST /api/auth/login
        Authenticate with username + password, receive a JWT access token.

    GET  /api/auth/me
        Return the currently authenticated user's details.

Dependencies
------------
    pip install argon2-cffi pyjwt
"""

import logging

from flask import Blueprint, jsonify, request, g

from routes.auth_utils import (
    hash_password,
    verify_password,
    check_needs_rehash,
    create_access_token,
)
from routes.decorators import require_auth, require_role
from routes.models import User, get_db_session, managed_db_session

logger = logging.getLogger(__name__)

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")


# -----------------------------------------------------------------------------
# POST /api/auth/register
# -----------------------------------------------------------------------------

@auth_bp.post("/register")
def register():
    """
    Register a new user account.

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
              description: Only admins can set roles other than 'user'
    responses:
      201:
        description: User created successfully
      400:
        description: Missing or invalid fields
      409:
        description: Username already exists
      403:
        description: Only admins can create privileged accounts
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    # --- Validate required fields ---
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

    # --- Determine requested role ---
    requested_role = (body.get("role") or "user").strip().lower()
    if requested_role not in User.ROLES:
        return jsonify({"error": f"Invalid role. Must be one of: {sorted(User.ROLES)}"}), 400

    # --- RBAC: Only admins can create superuser or admin accounts ---
    if requested_role in ("superuser", "admin"):
        # Check if an admin is making this request
        auth_header = request.headers.get("Authorization", "")
        from routes.auth_utils import get_token_from_header, decode_access_token

        token = get_token_from_header(auth_header)
        is_admin = False

        if token:
            payload = decode_access_token(token)
            if payload and payload.get("role") == "admin":
                is_admin = True

        if not is_admin:
            return jsonify({
                "error": "Permission denied. Only admin users can create accounts with 'superuser' or 'admin' roles."
            }), 403

    # --- Create the user ---
    password_hash = hash_password(password)

    with managed_db_session() as session:
        # Check for existing username
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
        session.flush()  # Populate new_user.id before commit

        # Build response BEFORE the session closes
        user_id = new_user.id
        user_role = new_user.role

    # --- Return success (no sensitive data) ---
    return jsonify({
        "message": "User registered successfully",
        "user_id": user_id,
        "username": username,
        "role": user_role,
    }), 201


# -----------------------------------------------------------------------------
# POST /api/auth/login
# -----------------------------------------------------------------------------

@auth_bp.post("/login")
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
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    username = (body.get("username") or "").strip()
    password = body.get("password") or ""

    if not username or not password:
        return jsonify({"error": "username and password are required"}), 400

    # Look up user
    session = get_db_session()
    try:
        user = session.query(User).filter_by(username=username).first()
    finally:
        session.close()

    if user is None:
        # Generic error to avoid username enumeration
        return jsonify({"error": "Invalid username or password"}), 401

    if not user.is_active:
        return jsonify({"error": "Account is disabled"}), 403

    # Verify password
    if not verify_password(password, user.password_hash):
        return jsonify({"error": "Invalid username or password"}), 401

    # Transparent rehash if Argon2 parameters have changed
    if check_needs_rehash(user.password_hash):
        new_hash = hash_password(password)
        with managed_db_session() as session:
            refreshed = session.query(User).filter_by(id=user.id).first()
            if refreshed:
                refreshed.password_hash = new_hash

    # Issue JWT
    token = create_access_token(user_id=user.id, role=user.role)

    return jsonify({
        "message": "Login successful",
        "access_token": token,
        "token_type": "Bearer",
        "user": {
            "id": user.id,
            "username": user.username,
            "role": user.role,
        },
    }), 200


# -----------------------------------------------------------------------------
# GET /api/auth/me
# -----------------------------------------------------------------------------

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