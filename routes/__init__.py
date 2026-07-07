"""
Blueprint registration — imported by app.py's create_app().

Add new blueprints here; order only matters if two blueprints define
overlapping URL rules (they shouldn't).
"""

from flask import Flask


def register_blueprints(app: Flask) -> None:
    from routes.health           import health_bp
    from routes.auth             import auth_bp
    from routes.items            import items_bp
    from routes.update           import update_bp
    from routes.logs             import logs_bp
    from routes.production_lines import production_lines_bp
    from routes.archive          import archive_bp   # ← revision history
    from routes.export           import export_bp
    from routes.approvals        import approvals_bp

    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp)
    app.register_blueprint(items_bp)
    app.register_blueprint(update_bp)
    app.register_blueprint(logs_bp)
    app.register_blueprint(production_lines_bp)
    app.register_blueprint(archive_bp)
    app.register_blueprint(export_bp)
    app.register_blueprint(approvals_bp)