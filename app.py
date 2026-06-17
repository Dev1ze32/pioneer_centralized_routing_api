"""
ACU Routing API
---------------
Thin entrypoint that creates the Flask app and wires blueprints together.

Run:
    python app.py
"""

from flask import Flask
from flasgger import Swagger

from routes import register_blueprints
from flask_cors import CORS


def create_app() -> Flask:
    app = Flask(__name__)
    CORS(app)

    app.config["SWAGGER"] = {
        "title": "ACU Routing API",
        "uiversion": 3,
        "specs_route": "/docs/",
    }

    # Register resource blueprints
    register_blueprints(app)

    # Initialize Swagger after routes are registered
    Swagger(app)

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(debug=True, port=5000)