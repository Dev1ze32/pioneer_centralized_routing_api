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
from flask import Blueprint, jsonify, request, g
from sqlalchemy import text

from db import managed_connection
from routes.utils.decorators import require_superuser_or_admin, require_admin
from routes.utils.log_utils import log_action

# Import update helpers for the approve logic
from routes.update import (
    _fetch_product, _increment_revision, _build_set_clause, 
    UPDATABLE_PRODUCT_FIELDS, snapshot_product
)

logger = logging.getLogger(__name__)

approvals_bp = Blueprint("approvals", __name__, url_prefix="/api")


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
            payload = existing["payload"]
            
            # --- APPLY TO LIVE TABLES ---
            if action == "ADD":
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
                
                # Update revision
                conn.execute(
                    text("UPDATE products SET revision = :new_revision WHERE inventory_id = :canonical_id"),
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
            # Check if exists and is pending
            existing = conn.execute(
                text("SELECT id FROM pending_approvals WHERE id = :id AND status = 'PENDING'"),
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

        return jsonify({"message": "Approval rejected successfully"}), 200

    except Exception as e:
        logger.exception("Error rejecting approval")
        return jsonify({"error": "Internal server error"}), 500
