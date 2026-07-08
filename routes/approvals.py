"""
Approvals resource for Super User workflow.

Endpoints
---------
POST /api/approvals              Submit a pending add/update
GET  /api/approvals              List pending approvals
POST /api/approvals/<id>/approve Approve a pending request
POST /api/approvals/<id>/reject  Reject a pending request
"""

import json
import logging
import queue
import threading
from flask import Blueprint, jsonify, request, g, Response, stream_with_context
from sqlalchemy import text

from db import managed_connection
from routes.utils.decorators import require_superuser_or_admin, require_admin
from routes.utils.validators import validate_product_payload
from routes.utils.log_utils import log_action

# Import update helpers for the approve logic
from routes.update import (
    _fetch_product, _increment_revision, _build_set_clause, 
    UPDATABLE_PRODUCT_FIELDS, snapshot_product
)

logger = logging.getLogger(__name__)

approvals_bp = Blueprint("approvals", __name__, url_prefix="/api")


# -- SSE: real-time pending-approval notifications for admins --------------
#
# In-memory pub/sub: every connected admin dashboard registers a Queue here.
# Whenever an approval is submitted / approved / rejected, we push the fresh
# pending count into every subscriber's queue and the generator in
# approvals_stream() writes it out as an SSE "data:" line.
#
# NOTE: this is process-local. It works because the app runs as a single
# Waitress process (single in-memory rate limiter, single ORM engine -- see
# extension.py / db.py). If this app is ever scaled to multiple processes or
# machines, this pub/sub needs to move to something shared (e.g. Redis
# pub/sub), the same way Flask-Limiter's storage_uri would need to change.
#
# Also note: each open SSE connection holds one Waitress worker thread for
# its lifetime. With the default WAITRESS_THREADS=8, keep an eye on this if
# many admins keep the dashboard open at once -- bump WAITRESS_THREADS in
# .env if needed.

_sse_subscribers = set()
_sse_lock = threading.Lock()
_SSE_HEARTBEAT_SECONDS = 25


def _get_pending_approvals_count():
    """Read the current PENDING count directly from the DB."""
    with managed_connection() as conn:
        row = conn.execute(
            text("SELECT COUNT(*) AS cnt FROM pending_approvals WHERE status = 'PENDING'")
        ).mappings().first()
        return row["cnt"] if row else 0


def _broadcast_approvals_changed():
    """
    Push the fresh pending-approvals count to every connected SSE client.

    Called after every mutation (submit / approve / reject) so open admin
    dashboards update their badge instantly instead of waiting on a poll.
    Never raises -- a broadcast failure should never break the API response.
    """
    try:
        count = _get_pending_approvals_count()
    except Exception:
        logger.exception("Failed to compute pending approvals count for SSE broadcast")
        return

    message = json.dumps({"type": "approvals_changed", "count": count})

    with _sse_lock:
        dead = []
        for client_queue in _sse_subscribers:
            try:
                client_queue.put_nowait(message)
            except queue.Full:
                dead.append(client_queue)
        for client_queue in dead:
            _sse_subscribers.discard(client_queue)


@approvals_bp.post("/approvals")
@require_superuser_or_admin
def submit_approval():
    """Submit a new pending approval (Add or Update)."""
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid JSON"}), 400

    inventory_id = body.get("inventory_id")
    action = body.get("action")  # 'ADD' or 'UPDATE'
    payload = body.get("payload")

    if not inventory_id or not action or not payload:
        return jsonify({"error": "Missing required fields (inventory_id, action, payload)"}), 400

    if action not in ("ADD", "UPDATE"):
        return jsonify({"error": "Action must be ADD or UPDATE"}), 400

    username = getattr(getattr(g, "current_user", None), "username", "unknown")

    try:
        with managed_connection() as conn:
            if action == "ADD":
                cleaned_payload, error_msg, status_code = validate_product_payload(payload, conn)
                if error_msg:
                    return jsonify({"error": error_msg}), status_code
                payload = cleaned_payload
                # Ensure the outer inventory_id matches the cleaned payload
                inventory_id = payload["inventory_id"]
            # Check if there is already a pending approval for this inventory_id
            existing = conn.execute(
                text("SELECT id FROM pending_approvals WHERE inventory_id = :iid AND status = 'PENDING'"),
                {"iid": inventory_id}
            ).fetchone()

            if existing:
                return jsonify({
                    "error": f"A pending approval already exists for item {inventory_id}. Please wait for it to be resolved."
                }), 409

            # Insert into pending_approvals
            result = conn.execute(
                text("""
                    INSERT INTO pending_approvals (inventory_id, action, requested_by, status, payload)
                    VALUES (:iid, :act, :req_by, 'PENDING', :payload)
                    RETURNING id
                """),
                {
                    "iid": inventory_id,
                    "act": action,
                    "req_by": username,
                    "payload": json.dumps(payload)
                }
            )
            new_id = result.scalar()

            log_action(
                action="submit_approval",
                description=f"Submitted {action} request for {inventory_id}",
                target_type="approval",
                target_id=str(new_id),
                extra={"inventory_id": inventory_id, "action": action}
            )

        # SSE: notify any connected admin dashboards that the pending count changed.
        _broadcast_approvals_changed()

        return jsonify({"message": "Approval request submitted successfully", "id": new_id}), 201

    except Exception as e:
        logger.exception("Error submitting approval")
        return jsonify({"error": "Internal server error"}), 500


@approvals_bp.get("/approvals")
@require_admin
def list_approvals():
    """List all pending approvals."""
    try:
        with managed_connection() as conn:
            rows = conn.execute(
                text("""
                    SELECT id, inventory_id, action, requested_by, status, created_at, payload
                    FROM pending_approvals
                    WHERE status = 'PENDING'
                    ORDER BY created_at ASC
                """)
            ).mappings().all()

            results = []
            for row in rows:
                r = dict(row)
                r["created_at"] = r["created_at"].isoformat() if r["created_at"] else None
                results.append(r)

            return jsonify(results), 200

    except Exception as e:
        logger.exception("Error listing approvals")
        return jsonify({"error": "Internal server error"}), 500


@approvals_bp.get("/approvals/stream")
@require_admin
def approvals_stream():
    """
    Server-Sent Events stream of pending-approval count updates. Admin only.

    Emits one event immediately on connect (current count), then one more
    event any time an approval is submitted, approved, or rejected by anyone.
    Sends a heartbeat comment every ~25s on top of that to keep the
    connection alive through proxies/load balancers.

    Only admins can approve/reject, so only admins are meaningfully served
    by this stream -- hence @require_admin rather than
    @require_superuser_or_admin.
    ---
    tags:
      - Approvals
    security:
      - Bearer: []
    responses:
      200:
        description: >
          text/event-stream. Each event's `data` field is a JSON object:
          {"type": "approvals_changed", "count": <int>}
      401:
        description: Missing or invalid token
      403:
        description: Admin access required
    """
    client_queue = queue.Queue(maxsize=50)
    with _sse_lock:
        _sse_subscribers.add(client_queue)

    def generate():
        try:
            # Send the current count right away so the badge is correct the
            # instant the connection opens, without waiting for a change.
            #
            # IMPORTANT: this must never raise. An exception here happens
            # mid-WSGI-iteration (before any bytes are flushed), which
            # bypasses Flask's normal error handlers entirely and just
            # kills the connection with a bare 500 -- the client then sees
            # a failed connect and retries in a loop. So on any DB hiccup
            # we log it and degrade to count 0 instead of raising.
            try:
                initial_count = _get_pending_approvals_count()
            except Exception:
                logger.exception("SSE: failed to read initial pending count")
                initial_count = 0

            initial = json.dumps({"type": "approvals_changed", "count": initial_count})
            yield f"data: {initial}\n\n"

            while True:
                try:
                    message = client_queue.get(timeout=_SSE_HEARTBEAT_SECONDS)
                    yield f"data: {message}\n\n"
                except queue.Empty:
                    yield ": heartbeat\n\n"
        except GeneratorExit:
            raise
        except Exception:
            # Catch-all: never let an unhandled exception escape the
            # generator once the stream is open -- log it and end the
            # stream cleanly. The client's reconnect loop will retry.
            logger.exception("SSE: approvals_stream generator crashed")
        finally:
            with _sse_lock:
                _sse_subscribers.discard(client_queue)

    return Response(
        stream_with_context(generate()),
        mimetype="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            # NOTE: do NOT set "Connection" here -- it's a hop-by-hop header
            # per PEP 3333, and Waitress raises an AssertionError if a WSGI
            # app tries to set it directly (Waitress manages it itself).
            # Disable buffering if this app is ever put behind nginx.
            "X-Accel-Buffering": "no",
        },
    )


@approvals_bp.post("/approvals/<int:approval_id>/approve")
@require_admin
def approve_request(approval_id):
    """Approve a pending request and apply it to live tables."""
    username = getattr(getattr(g, "current_user", None), "username", "unknown")
    try:
        with managed_connection() as conn:
            existing = conn.execute(
                text("SELECT inventory_id, action, payload FROM pending_approvals WHERE id = :id AND status = 'PENDING' FOR UPDATE"),
                {"id": approval_id}
            ).mappings().fetchone()
            
            if not existing:
                return jsonify({"error": "Pending approval not found"}), 404
                
            inventory_id = existing["inventory_id"]
            action = existing["action"]
            raw_payload = existing["payload"]

            # FIX I4: Guard against double-encoded JSONB. psycopg3 auto-
            # deserialises JSONB → dict, but if the INSERT used json.dumps()
            # the column may contain a JSON string literal. Normalise here
            # so downstream .get() calls always work on a real dict.
            if isinstance(raw_payload, str):
                payload = json.loads(raw_payload)
            else:
                payload = raw_payload
            
            # --- APPLY TO LIVE TABLES ---
            if action == "ADD":
                cleaned_payload, error_msg, status_code = validate_product_payload(payload, conn)
                if error_msg:
                    return jsonify({"error": f"Cannot approve ADD: {error_msg}"}), status_code
                payload = cleaned_payload
                
                # Make sure it doesn't already exist
                check = conn.execute(
                    text("SELECT inventory_id FROM products WHERE UPPER(inventory_id) = UPPER(:iid)"),
                    {"iid": inventory_id}
                ).fetchone()
                if check:
                    return jsonify({"error": f"Cannot approve ADD: item {inventory_id} already exists."}), 409
                    
                # Insert product
                conn.execute(
                    text("""
                        INSERT INTO products
                            (inventory_id, revision_descr, revision, quantity, product_type,
                             fg_production_line, fg_production_line_code,
                             bm_production_line, bm_production_line_code, notes,
                             total_run_time, total_labor_min, total_mc_min,
                             total_dl_units, total_dl, total_voh, total_foh,
                             created_at, updated_at)
                        VALUES (:inventory_id, :revision_descr, :revision, :quantity, :product_type,
                                :fg_production_line, :fg_production_line_code,
                                :bm_production_line, :bm_production_line_code, :notes,
                                :total_run_time, :total_labor_min, :total_mc_min,
                                :total_dl_units, :total_dl, :total_voh, :total_foh,
                                NOW(), NOW())
                    """),
                    {
                        "inventory_id":            inventory_id,
                        "revision_descr":          payload.get("revision_descr", ""),
                        "revision":                "00",
                        "quantity":                float(payload.get("quantity") or 0.0),
                        "product_type":            payload.get("product_type", ""),
                        "fg_production_line":      payload.get("fg_production_line"),
                        "fg_production_line_code": payload.get("fg_production_line_code"),
                        "bm_production_line":      payload.get("bm_production_line"),
                        "bm_production_line_code": payload.get("bm_production_line_code"),
                        "notes":                   payload.get("notes"),
                        "total_run_time":  payload.get("total_run_time",  0.0),
                        "total_labor_min": payload.get("total_labor_min", 0.0),
                        "total_mc_min":    payload.get("total_mc_min",    0.0),
                        "total_dl_units":  payload.get("total_dl_units",  0.0),
                        "total_dl":        payload.get("total_dl",        0.0),
                        "total_voh":       payload.get("total_voh",       0.0),
                        "total_foh":       payload.get("total_foh",       0.0),
                    }
                )
                # Insert activities
                activities = payload.get("activities", [])
                for idx, act in enumerate(activities):
                    conn.execute(
                        text("""
                            INSERT INTO activities
                                (inventory_id, type, item_id, activity_name, class, class_1,
                                 pax, machine, time_min, sort_order, run_time, labor_min,
                                 mc_min, dl_units, dl, voh, foh)
                            VALUES (:inventory_id, :type, :item_id, :activity_name, :class_, :class_1,
                                    :pax, :machine, :time_min, :sort_order, :run_time, :labor_min,
                                    :mc_min, :dl_units, :dl, :voh, :foh)
                        """),
                        {
                            "inventory_id":  inventory_id,
                            "type":          act.get("type"),
                            "item_id":       act.get("item_id"),
                            "activity_name": act.get("activity_name", ""),
                            "class_":        act.get("class"),
                            "class_1":       act.get("class_1"),
                            "pax":           act.get("pax", 0) if act.get("pax") != "" else 0,
                            "machine":       act.get("machine", 0) if act.get("machine") != "" else 0,
                            "time_min":      act.get("time_min", 0.0) if act.get("time_min") != "" else 0.0,
                            "sort_order":    idx + 1,
                            "run_time":      act.get("run_time", 0.0) if act.get("run_time") != "" else 0.0,
                            "labor_min":     act.get("labor_min", 0.0) if act.get("labor_min") != "" else 0.0,
                            "mc_min":        act.get("mc_min", 0.0) if act.get("mc_min") != "" else 0.0,
                            "dl_units":      act.get("dl_units", 0.0) if act.get("dl_units") != "" else 0.0,
                            "dl":            act.get("dl", 0.0) if act.get("dl") != "" else 0.0,
                            "voh":           act.get("voh", 0.0) if act.get("voh") != "" else 0.0,
                            "foh":           act.get("foh", 0.0) if act.get("foh") != "" else 0.0,
                        }
                    )
            elif action == "UPDATE":
                product = _fetch_product(conn, inventory_id, for_update=True)
                if not product:
                    return jsonify({"error": f"Cannot approve UPDATE: item {inventory_id} not found."}), 404

                # FIX C2: Validate production line codes still exist at approval time.
                # Between submission and approval, a line code could have been deleted.
                for code_field in ("fg_production_line_code", "bm_production_line_code"):
                    code = payload.get(code_field)
                    if code:
                        row = conn.execute(
                            text("SELECT 1 FROM production_lines WHERE production_line_code = :c"),
                            {"c": code},
                        ).first()
                        if not row:
                            return jsonify({"error": f"Cannot approve UPDATE: {code_field} '{code}' no longer exists."}), 400

                old_revision = product["revision"]
                new_revision = _increment_revision(old_revision)
                
                # Snapshot before applying
                snapshot_product(conn, inventory_id, old_revision, archived_by=username)
                
                # Update product metadata
                updates = {k: v for k, v in payload.items() if k in UPDATABLE_PRODUCT_FIELDS}
                if "quantity" in updates and updates["quantity"] in (None, ""):
                    updates["quantity"] = 0.0
                
                set_clause = _build_set_clause(updates)
                if set_clause:
                    params = {**updates, "canonical_id": inventory_id}
                    conn.execute(
                        text(f"UPDATE products SET {set_clause} WHERE inventory_id = :canonical_id"),
                        params,
                    )
                
                # FIX C1: Update revision AND updated_at to match the direct-edit
                # path in update.py's _bump_revision(), so approved products don't
                # keep a stale timestamp.
                conn.execute(
                    text("UPDATE products SET revision = :new_revision, updated_at = NOW() WHERE inventory_id = :canonical_id"),
                    {"new_revision": new_revision, "canonical_id": inventory_id},
                )
                
                # Replace all activities
                conn.execute(text("DELETE FROM activities WHERE inventory_id = :iid"), {"iid": inventory_id})
                activities = payload.get("activities", [])
                for idx, act in enumerate(activities):
                    conn.execute(
                        text("""
                            INSERT INTO activities
                                (inventory_id, type, item_id, activity_name, class, class_1,
                                 pax, machine, time_min, sort_order, run_time, labor_min,
                                 mc_min, dl_units, dl, voh, foh)
                            VALUES (:inventory_id, :type, :item_id, :activity_name, :class_, :class_1,
                                    :pax, :machine, :time_min, :sort_order, :run_time, :labor_min,
                                    :mc_min, :dl_units, :dl, :voh, :foh)
                        """),
                        {
                            "inventory_id":  inventory_id,
                            "type":          act.get("type"),
                            "item_id":       act.get("item_id"),
                            "activity_name": act.get("activity_name", ""),
                            "class_":        act.get("class"),
                            "class_1":       act.get("class_1"),
                            "pax":           act.get("pax", 0) if act.get("pax") != "" else 0,
                            "machine":       act.get("machine", 0) if act.get("machine") != "" else 0,
                            "time_min":      act.get("time_min", 0.0) if act.get("time_min") != "" else 0.0,
                            "sort_order":    idx + 1,
                            "run_time":      act.get("run_time", 0.0) if act.get("run_time") != "" else 0.0,
                            "labor_min":     act.get("labor_min", 0.0) if act.get("labor_min") != "" else 0.0,
                            "mc_min":        act.get("mc_min", 0.0) if act.get("mc_min") != "" else 0.0,
                            "dl_units":      act.get("dl_units", 0.0) if act.get("dl_units") != "" else 0.0,
                            "dl":            act.get("dl", 0.0) if act.get("dl") != "" else 0.0,
                            "voh":           act.get("voh", 0.0) if act.get("voh") != "" else 0.0,
                            "foh":           act.get("foh", 0.0) if act.get("foh") != "" else 0.0,
                        }
                    )

            # Mark approval as APPROVED
            conn.execute(
                text("""
                    UPDATE pending_approvals 
                    SET status = 'APPROVED', resolved_at = NOW(), resolved_by = :username
                    WHERE id = :id
                """),
                {"id": approval_id, "username": username}
            )
            
            log_action(
                action="approve_request",
                description=f"Approved {action} request for {inventory_id}",
                target_type="approval",
                target_id=str(approval_id),
            )

        # SSE: pending count just dropped by one — push the update.
        _broadcast_approvals_changed()

        return jsonify({"message": "Approval processed successfully"}), 200

    except Exception as e:
        logger.exception("Error processing approval")
        return jsonify({"error": "Internal server error"}), 500


@approvals_bp.post("/approvals/<int:approval_id>/reject")
@require_admin
def reject_approval(approval_id):
    """Reject a pending approval."""
    username = getattr(getattr(g, "current_user", None), "username", "unknown")
    try:
        with managed_connection() as conn:
            # FIX I1: Add FOR UPDATE to prevent double-reject race.
            # Without it, two simultaneous reject clicks both see PENDING,
            # both update to REJECTED, and both return 200.
            existing = conn.execute(
                text("SELECT id FROM pending_approvals WHERE id = :id AND status = 'PENDING' FOR UPDATE"),
                {"id": approval_id}
            ).fetchone()
            
            if not existing:
                return jsonify({"error": "Pending approval not found"}), 404

            conn.execute(
                text("""
                    UPDATE pending_approvals 
                    SET status = 'REJECTED', resolved_at = NOW(), resolved_by = :username
                    WHERE id = :id
                """),
                {"id": approval_id, "username": username}
            )

            log_action(
                action="reject_approval",
                description=f"Rejected approval request {approval_id}",
                target_type="approval",
                target_id=str(approval_id),
            )

        # SSE: pending count just dropped by one — push the update.
        _broadcast_approvals_changed()

        return jsonify({"message": "Approval rejected successfully"}), 200

    except Exception as e:
        logger.exception("Error rejecting approval")
        return jsonify({"error": "Internal server error"}), 500