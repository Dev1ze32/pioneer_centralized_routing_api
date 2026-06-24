"""
ACU Routing API — application factory.

Production entry point
----------------------
    python waitress_server.py

Development entry point (single-threaded, do NOT use in production)
--------------------------------------------------------------------
    python app.py
"""

import logging

from flask import Flask, jsonify
from flasgger import Swagger
from flask_cors import CORS
from sqlalchemy.exc import TimeoutError as SATimeoutError, OperationalError

from config import Config
from extension import limiter          # ← imported from extension.py, not defined here
from routes import register_blueprints


def _init_database():
    """
    Ensure all ORM tables exist and seed the first admin user if needed.

    - create_all() is idempotent when run alone, but in concurrent startup
      scenarios there is a race on CREATE TABLE / sequence.
      We catch IntegrityError so the losing thread doesn't crash.
    - The admin seed only runs when the users table is completely empty,
      so it won't interfere with an already-populated database.
    """
    from db import _get_engine
    from routes.models import Base, User, managed_db_session
    from sqlalchemy.exc import IntegrityError, ProgrammingError
    from sqlalchemy import inspect as sa_inspect

    engine = _get_engine()
    log = logging.getLogger(__name__)

    # ── Create tables (race-safe) ─────────────────────────────────────────────
    try:
        Base.metadata.create_all(engine, checkfirst=True)
        log.info("Database tables verified / created.")
    except (IntegrityError, ProgrammingError):
        # Another thread/process already created the tables — that's fine.
        log.info("Database tables already created by another worker.")

    # Verify the table actually exists before trying to seed
    inspector = sa_inspect(engine)
    if not inspector.has_table("users"):
        log.warning(
            "'users' table not yet visible — another worker may still be "
            "creating it. Skipping admin seed for this worker."
        )
        return

    # ── Seed initial admin (race-safe) ────────────────────────────────────────
    import os
    admin_user = os.getenv("INITIAL_ADMIN_USERNAME", "")
    admin_pass = os.getenv("INITIAL_ADMIN_PASSWORD", "")

    if admin_user and admin_pass:
        try:
            with managed_db_session() as session:
                if session.query(User).count() == 0:
                    from routes.utils.auth_utils import hash_password
                    session.add(User(
                        username=admin_user,
                        password_hash=hash_password(admin_pass),
                        role="admin",
                        is_active=True,
                    ))
                    log.info("Seeded initial admin user '%s'.", admin_user)
                else:
                    log.info("Users table is not empty — skipping admin seed.")
        except IntegrityError:
            # Another worker already inserted the admin — that's fine.
            log.info("Admin user already seeded by another worker.")


def create_app() -> Flask:
    app = Flask(__name__)

    # ── Database — create tables + seed admin on first run ─────────────────────
    _init_database()

    # ── CORS ──────────────────────────────────────────────────────────────────
    CORS(app)

    # ── Swagger UI ────────────────────────────────────────────────────────────
    app.config["SWAGGER"] = {
        "title": "ACU Routing API",
        "uiversion": 3,
        "specs_route": "/docs/",
    }

    # ── Rate limiter — binds the already-created limiter to this app ──────────
    limiter.init_app(app)

    # ── Blueprints (must come before Swagger so routes are registered first) ──
    register_blueprints(app)
    Swagger(app)

    # ── Global error handlers ─────────────────────────────────────────────────

    @app.errorhandler(SATimeoutError)
    def handle_pool_timeout(e):
        """Connection pool exhausted — tell the client to retry."""
        logging.getLogger(__name__).error("DB pool timeout: %s", e)
        return jsonify({
            "error": "Server is under heavy load. Please retry in a moment.",
            "code":  "db_pool_exhausted",
        }), 503

    @app.errorhandler(OperationalError)
    def handle_db_operational_error(e):
        """DB unreachable or statement timeout hit."""
        logging.getLogger(__name__).error("DB operational error: %s", e)
        return jsonify({
            "error": "Database temporarily unavailable. Please retry.",
            "code":  "db_unavailable",
        }), 503

    @app.errorhandler(429)
    def handle_rate_limit(e):
        """Flask-Limiter fires this when a limit is exceeded."""
        return jsonify({
            "error": "Too many requests. Please slow down and try again.",
            "code":  "rate_limited",
        }), 429

    @app.errorhandler(500)
    def handle_internal_error(e):
        logging.getLogger(__name__).exception("Unhandled 500: %s", e)
        return jsonify({"error": "An internal server error occurred."}), 500

    return app


# ── Dev runner — waitress_server.py is the production entry point ─────────────
if __name__ == "__main__":
    import warnings
    warnings.warn(
        "Running with Flask's built-in dev server. "
        "This is single-threaded and NOT suitable for production. "
        "Use:  python waitress_server.py",
        stacklevel=1,
    )
    app = create_app()
    app.run(host="0.0.0.0", debug=False, port=Config.WAITRESS_PORT)