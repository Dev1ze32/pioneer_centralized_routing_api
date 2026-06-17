"""
Blueprint registration helper.
"""

from flask import Flask

from .health import health_bp
from .items import items_bp
from .production_lines import production_lines_bp


def register_blueprints(app: Flask) -> None:
    app.register_blueprint(health_bp)
    app.register_blueprint(items_bp)
    app.register_blueprint(production_lines_bp)