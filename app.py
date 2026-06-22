"""
ACU Routing API — application factory.

Production entry point
----------------------
    gunicorn "app:create_app()" -c gunicorn.conf.py

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
from routes import register_blueprints
from extension import limiter


def create_app() -> Flask:
    app = Flask(__name__)

    # ── CORS ──────────────────────────────────────────────────────────────────
    CORS(app)

    # ── Swagger UI ────────────────────────────────────────────────────────────
    app.config["SWAGGER"] = {
        "title": "ACU Routing API",
        "uiversion": 3,
        "specs_route": "/docs/",
    }

    # ── Rate limiter ──────────────────────────────────────────────────────────
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


# ── Dev runner — gunicorn ignores this block entirely ─────────────────────────
if __name__ == "__main__":
    import warnings
    warnings.warn(
        "Running with Flask's built-in dev server. "
        "This is single-threaded and NOT suitable for production. "
        "Use:  gunicorn 'app:create_app()' -c gunicorn.conf.py",
        stacklevel=1,
    )
    app = create_app()
    app.run(host="0.0.0.0", debug=False, port=Config.GUNICORN_PORT)