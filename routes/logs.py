"""
Activity Logs resource — admin-only audit trail viewer.

Endpoints
---------
    GET    /api/logs           List audit log entries (admin only).
    DELETE /api/logs/cleanup   Purge entries older than N days (admin only).

FIX #13 — from_date and to_date are now validated as ISO-8601 dates before
being passed to PostgreSQL. An invalid value now returns a clean 400 instead
of an unhandled DataError / 500.
"""

import logging
from datetime import date
from flask import Blueprint, jsonify, request
from sqlalchemy import text

from db import managed_connection
from routes.utils.decorators import require_role, require_auth
from routes.utils.log_utils import purge_old_logs

logger = logging.getLogger(__name__)

logs_bp = Blueprint("logs", __name__, url_prefix="/api/logs")


def _require_admin(f):
    return require_auth(require_role("admin")(f))


def _parse_date(value: str, field_name: str):
    """
    Parse an ISO-8601 date string (YYYY-MM-DD).
    Returns (date_obj, None) on success, (None, error_response) on failure.

    FIX #13: replaces unchecked pass-through to PostgreSQL that caused an
    unhandled DataError / 500 for invalid date strings.
    """
    try:
        return date.fromisoformat(value), None
    except ValueError:
        return None, (
            jsonify({"error": f"{field_name} must be a valid ISO-8601 date (YYYY-MM-DD), got: {value!r}"}),
            400,
        )


# ── GET /api/logs ──────────────────────────────────────────────────────────────

@logs_bp.get("")
@_require_admin
def list_logs():
    """
    List audit log entries (admin only).
    ---
    tags:
      - Logs
    security:
      - Bearer: []
    parameters:
      - name: page
        in: query
        type: integer
        default: 1
        description: Page number (1-based)
      - name: per_page
        in: query
        type: integer
        default: 50
        description: Entries per page (max 200)
      - name: username
        in: query
        type: string
        description: Filter by exact username
      - name: action
        in: query
        type: string
        description: Partial, case-insensitive match on the action field
      - name: target_type
        in: query
        type: string
        description: "Filter by target type: product | activity | user | session"
      - name: from_date
        in: query
        type: string
        description: "ISO-8601 date (e.g. 2026-01-01) — only return entries on or after this date"
      - name: to_date
        in: query
        type: string
        description: "ISO-8601 date (e.g. 2026-06-30) — only return entries on or before this date"
    responses:
      200:
        description: Paginated list of audit log entries
      400:
        description: Invalid query parameters
      403:
        description: Admin access required
    """
    try:
        page     = max(1, request.args.get("page", 1, type=int))
        per_page = min(request.args.get("per_page", 50, type=int), 200)
    except (ValueError, TypeError):
        return jsonify({"error": "page and per_page must be integers"}), 400

    offset = (page - 1) * per_page

    filter_username    = (request.args.get("username")    or "").strip() or None
    filter_action      = (request.args.get("action")      or "").strip() or None
    filter_target_type = (request.args.get("target_type") or "").strip() or None
    filter_from_date   = (request.args.get("from_date")   or "").strip() or None
    filter_to_date     = (request.args.get("to_date")     or "").strip() or None

    # FIX #13: validate date strings up front — bad input → 400, not 500
    if filter_from_date:
        _, err = _parse_date(filter_from_date, "from_date")
        if err:
            return err

    if filter_to_date:
        _, err = _parse_date(filter_to_date, "to_date")
        if err:
            return err

    conditions = []
    params: dict = {"limit": per_page, "offset": offset}

    if filter_username:
        conditions.append("username = :username")
        params["username"] = filter_username

    if filter_action:
        conditions.append("action ILIKE :action")
        params["action"] = f"%{filter_action}%"

    if filter_target_type:
        conditions.append("target_type = :target_type")
        params["target_type"] = filter_target_type

    if filter_from_date:
        # Use explicit cast via PostgreSQL function to avoid space-before-:: ambiguity
        conditions.append("logged_at >= :from_date::timestamptz")
        params["from_date"] = filter_from_date

    if filter_to_date:
        conditions.append("logged_at < (:to_date::date + INTERVAL '1 day')")
        params["to_date"] = filter_to_date

    where_sql = ("WHERE " + " AND ".join(conditions)) if conditions else ""

    with managed_connection() as conn:
        count_result = conn.execute(
            text(f"SELECT COUNT(*) AS total FROM activity_logs {where_sql}"),
            params,
        )
        total = count_result.mappings().first()["total"]

        rows = conn.execute(
            text(
                f"""
                SELECT
                    id,
                    TO_CHAR(logged_at AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS UTC') AS logged_at,
                    username,
                    user_role,
                    action,
                    description,
                    target_type,
                    target_id,
                    ip_address,
                    extra
                FROM activity_logs
                {where_sql}
                ORDER BY logged_at DESC
                LIMIT :limit OFFSET :offset
                """
            ),
            params,
        ).mappings().all()

    entries = []
    for row in rows:
        entry = dict(row)
        if entry.get("extra") and isinstance(entry["extra"], str):
            import json
            try:
                entry["extra"] = json.loads(entry["extra"])
            except Exception:
                pass
        entries.append(entry)

    return jsonify({
        "page":        page,
        "per_page":    per_page,
        "total":       total,
        "total_pages": max(1, -(-total // per_page)),
        "logs":        entries,
    }), 200


# ── DELETE /api/logs/cleanup ───────────────────────────────────────────────────

@logs_bp.delete("/cleanup")
@_require_admin
def cleanup_logs():
    """
    Purge log entries older than N days (default: 90).
    ---
    tags:
      - Logs
    security:
      - Bearer: []
    parameters:
      - name: days
        in: query
        type: integer
        default: 90
        description: Delete entries older than this many days
    responses:
      200:
        description: Cleanup complete
      400:
        description: Invalid days parameter
      403:
        description: Admin access required
    """
    try:
        days = int(request.args.get("days", 90))
        if days < 1:
            raise ValueError
    except (ValueError, TypeError):
        return jsonify({"error": "days must be a positive integer"}), 400

    deleted = purge_old_logs(days=days)

    from flask import g
    from routes.utils.log_utils import log_action
    log_action(
        action="Purged old logs",
        description=(
            f"{g.current_user.username} deleted {deleted} audit log "
            f"entries older than {days} days."
        ),
        target_type="logs",
        extra={"days_threshold": days, "rows_deleted": deleted},
    )

    return jsonify({
        "message":        f"Deleted {deleted} log entries older than {days} days.",
        "rows_deleted":   deleted,
        "days_threshold": days,
    }), 200