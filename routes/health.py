"""
Health check resource.
"""

from flask import Blueprint, jsonify

health_bp = Blueprint("health", __name__, url_prefix="/api")


@health_bp.get("/health")
def health():
    """
    Health check
    ---
    tags:
      - Health
    responses:
      200:
        description: API is up
        examples:
          application/json: {"status": "ok"}
    """
    return jsonify({"status": "ok"})