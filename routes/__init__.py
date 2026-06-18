"""
Blueprint registration helper.

All blueprints are registered here so app.py stays a thin factory.
"""

from flask import Flask

from .auth import auth_bp
from .health import health_bp
from .items import items_bp
from .production_lines import production_lines_bp
from .update import update_bp


def register_blueprints(app: Flask) -> None:
    app.register_blueprint(auth_bp)           # /api/auth/*
    app.register_blueprint(health_bp)         # /api/health
    app.register_blueprint(items_bp)          # /api/items
    app.register_blueprint(production_lines_bp)  # /api/production-lines
    app.register_blueprint(update_bp)         # /api/items (PATCH/DELETE)