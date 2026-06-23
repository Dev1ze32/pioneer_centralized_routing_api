"""
Audit logging utility.

FIX #4 — purge_old_logs() no longer interpolates `days` directly into the
SQL string.  PostgreSQL's INTERVAL literal cannot use a plain bind parameter,
but it CAN be written as  INTERVAL '1 day' * :days  which is fully
parameterised and safe against any future refactoring that might loosen the
int() cast.

Only meaningful, irreversible actions are logged:
  - Product created / updated / deleted
  - Activity added / updated / deleted
  - User account created (admin action)
  - Audit log purged

log_action() reads g.current_user and the client IP automatically.
It is fire-and-forget: a failure will NOT break the API response.
"""

import json
import logging
from typing import Optional

from flask import g, request
from sqlalchemy import text

from db import managed_connection

logger = logging.getLogger(__name__)


def log_action(
    action: str,
    description: str,
    target_type: Optional[str] = None,
    target_id: Optional[str] = None,
    extra: Optional[dict] = None,
    user_id: Optional[int] = None,
    username: Optional[str] = None,
    user_role: Optional[str] = None,
) -> None:
    """
    Write one audit entry to activity_logs. Never raises.

    Parameters
    ----------
    action      : Short label shown in the admin log view.
    description : Full human-readable sentence of what happened.
    target_type : "product" | "activity" | "user" | "logs"
    target_id   : The affected object's identifier.
    extra       : Optional dict stored as JSONB.
    user_id / username / user_role : Override g.current_user when needed.
    """
    try:
        current_user = getattr(g, "current_user", None)

        resolved_user_id   = user_id   if user_id   is not None else (current_user.id      if current_user else None)
        resolved_username  = username  if username  is not None else (current_user.username if current_user else "unknown")
        resolved_user_role = user_role if user_role is not None else (current_user.role     if current_user else "unknown")

        ip = (
            request.headers.get("X-Forwarded-For", "").split(",")[0].strip()
            or request.remote_addr
            or "unknown"
        )

        extra_json = json.dumps(extra) if extra else None

        with managed_connection() as conn:
            conn.execute(
                text(
                    """
                    INSERT INTO activity_logs
                        (user_id, username, user_role,
                         action, description,
                         target_type, target_id,
                         ip_address, extra)
                    VALUES
                        (:user_id, :username, :user_role,
                         :action, :description,
                         :target_type, :target_id,
                         :ip_address, :extra)
                    """
                ),
                {
                    "user_id":     resolved_user_id,
                    "username":    resolved_username,
                    "user_role":   resolved_user_role,
                    "action":      action,
                    "description": description,
                    "target_type": target_type,
                    "target_id":   str(target_id) if target_id is not None else None,
                    "ip_address":  ip,
                    "extra":       extra_json,
                },
            )

    except Exception as exc:
        logger.error("audit log write failed: %s", exc, exc_info=True)


def purge_old_logs(days: int = 90) -> int:
    """
    Delete log entries older than *days* days. Returns the row count deleted.

    FIX #4: uses a fully parameterised expression for the interval instead of
    f-string interpolation.  INTERVAL '1 day' * :days is valid PostgreSQL and
    keeps the value in a bind parameter.
    """
    try:
        with managed_connection() as conn:
            result = conn.execute(
                text(
                    "DELETE FROM activity_logs "
                    "WHERE logged_at::date <= CURRENT_DATE - :days"
                ),
                {"days": int(days)},
            )
            return result.rowcount
    except Exception as exc:
        logger.error("audit log purge failed: %s", exc, exc_info=True)
        return 0