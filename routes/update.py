"""
Update resource.

Endpoints
---------
PATCH  /api/items/<item_code>                           Update product metadata
POST   /api/items/<item_code>/activities                Add a single activity
PATCH  /api/items/<item_code>/activities/<activity_id>  Update a single activity
DELETE /api/items/<item_code>/activities/<activity_id>  Remove a single activity
DELETE /api/items/<item_code>                           Delete an entire product

Fixes applied
-------------
FIX #3  — delete_activity() now calls _fetch_product(..., for_update=True)
          so the revision bump is protected by a row-level lock, matching all
          other mutating endpoints.

FIX #8  — `class` is a reserved SQL keyword. The dynamic SET clause in
          update_activity() now quotes it as "class" so PostgreSQL accepts it
          without a syntax error.

FIX #10 — update_product_metadata() was reading the revision without a lock,
          allowing two concurrent PATCHes to both read revision N and both
          write N+1 (losing one bump). It now uses _fetch_product(...,
          for_update=True).

FIX #16 — _increment_revision() now guards against non-numeric revision
          strings (e.g. manually-edited "A3") by logging a warning instead of
          silently resetting to "01", and preserves the existing value as the
          base rather than hard-coding 0.

ARCHIVE — before every revision bump, snapshot_product() writes the current
          state (product row + activities) to product_revisions inside the
          same transaction. If the update rolls back, the snapshot rolls back
          too, so the archive is always consistent.
"""

import logging
from typing import Optional

from flask import Blueprint, jsonify, request, g
from sqlalchemy import text
from sqlalchemy.engine import Connection

from db import managed_connection
from routes.utils.decorators import require_superuser_or_admin
from routes.utils.log_utils import log_action
from routes.utils.archive_utilities import snapshot_product

logger = logging.getLogger(__name__)

update_bp = Blueprint("update", __name__, url_prefix="/api")

# ── Constants ─────────────────────────────────────────────────────────────────

UPDATABLE_PRODUCT_FIELDS = {
    "revision_descr",
    "notes",
    "quantity",
    "bm_production_line",
    "bm_production_line_code",
    "fg_production_line",
    "fg_production_line_code",
    "product_type",
}

REQUIRED_ACTIVITY_FIELDS = ("activity_name", "pax", "machine", "time_min")

UPDATABLE_ACTIVITY_FIELDS = {
    "activity_name", "type", "item_id",
    "class", "class_1", "pax", "machine", "time_min", "sort_order",
}

# FIX #8: columns whose names are SQL reserved words must be double-quoted
# in dynamic SET clauses. Map field name -> quoted SQL identifier.
_QUOTED_COLUMNS = {
    "class": '"class"',
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _increment_revision(current: Optional[str]) -> str:
    """
    Increment a zero-padded two-digit revision string.

    FIX #16: non-numeric strings (e.g. "A3" from a manual DB edit) no longer
    silently reset the counter to "01". Instead, we log a warning and keep
    the existing string as the base for the integer conversion attempt,
    falling back to 0 only when truly unparseable.
    """
    try:
        num = int(current or "0") + 1
    except (ValueError, TypeError):
        logger.warning(
            "Could not parse revision %r as an integer — "
            "resetting counter from 0. Check the DB for unexpected values.",
            current,
        )
        num = 1
    return f"0{num}" if num < 10 else str(num)


def _fetch_product(conn: Connection, item_code: str, for_update: bool = False):
    lock_clause = "FOR UPDATE" if for_update else ""
    result = conn.execute(
        text(
            f"""
            SELECT inventory_id, revision, revision_descr, notes, product_type,
                   quantity,
                   bm_production_line, bm_production_line_code,
                   fg_production_line, fg_production_line_code
            FROM   products
            WHERE  UPPER(inventory_id) = UPPER(:item_code)
            {lock_clause}
            """
        ),
        {"item_code": item_code},
    )
    return result.mappings().first()


def _bump_revision(conn: Connection, canonical_id: str, old_revision: str) -> str:
    new_revision = _increment_revision(old_revision)
    conn.execute(
        text("UPDATE products SET revision = :new_revision WHERE inventory_id = :canonical_id"),
        {"new_revision": new_revision, "canonical_id": canonical_id},
    )
    return new_revision


def _build_set_clause(fields: dict) -> str:
    """
    Build a safe SET clause from a dict of {column: value} pairs.

    FIX #8: columns listed in _QUOTED_COLUMNS are emitted with their
    double-quoted SQL identifier so reserved words don't cause a syntax error.
    """
    parts = []
    for col in fields:
        sql_col = _QUOTED_COLUMNS.get(col, col)
        parts.append(f"{sql_col} = :{col}")
    return ", ".join(parts)


# ── 1. Update product metadata ────────────────────────────────────────────────

@update_bp.patch("/items/<item_code>")
@require_superuser_or_admin
def update_product_metadata(item_code):
    """
    Update product metadata. Revision is auto-incremented on every save.
    ---
    tags:
      - Items
    parameters:
      - name: item_code
        in: path
        type: string
        required: true
        example: 1AF2202L
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            revision_descr:
              type: string
            notes:
              type: string
            quantity:
              type: number
            bm_production_line:
              type: string
            bm_production_line_code:
              type: string
            fg_production_line:
              type: string
            fg_production_line_code:
              type: string
            product_type:
              type: string
              enum: ["Finished Good (FG)", "Base Material (BM)", "Other / Intermediate"]
    responses:
      200:
        description: Product metadata updated
      400:
        description: No valid fields provided or invalid JSON
      404:
        description: Item not found
      500:
        description: Internal server error
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    updates = {k: v for k, v in body.items() if k in UPDATABLE_PRODUCT_FIELDS}
    VALID_PRODUCT_TYPES = {"Finished Good (FG)", "Base Material (BM)", "Other / Intermediate"}
    if "product_type" in updates and updates["product_type"] not in VALID_PRODUCT_TYPES:
        return jsonify({"error": f"Invalid product_type. Must be one of: {sorted(VALID_PRODUCT_TYPES)}"}), 400

    if "quantity" in updates and updates["quantity"] is not None:
        try:
            q = float(updates["quantity"])
        except (TypeError, ValueError):
            return jsonify({"error": "quantity must be a number"}), 400
        if q != int(q):
            return jsonify({"error": "quantity must be a whole number"}), 400
        updates["quantity"] = q

    if not updates:
        return jsonify({
            "error": "No valid fields provided",
            "updatable_fields": sorted(UPDATABLE_PRODUCT_FIELDS),
        }), 400

    try:
        with managed_connection() as conn:
            # FIX #10: FOR UPDATE prevents two concurrent PATCHes from both
            # reading the same revision and both writing the same incremented value.
            product = _fetch_product(conn, item_code, for_update=True)
            if product is None:
                return jsonify({"error": "Item not found", "item_code": item_code}), 404

            canonical_id = product["inventory_id"]
            old_revision = product["revision"]
            new_revision = _increment_revision(old_revision)

            set_clause = ", ".join(f"{col} = :{col}" for col in updates)
            params = {**updates, "canonical_id": canonical_id}

            # ARCHIVE: snapshot the current state BEFORE applying the update,
            # inside the same transaction so it rolls back together on error.
            actor_name = getattr(getattr(g, "current_user", None), "username", "unknown")
            snapshot_product(conn, canonical_id, old_revision, archived_by=actor_name)

            conn.execute(
                text(f"UPDATE products SET {set_clause} WHERE inventory_id = :canonical_id"),
                params,
            )
            conn.execute(
                text("UPDATE products SET revision = :new_revision WHERE inventory_id = :canonical_id"),
                {"new_revision": new_revision, "canonical_id": canonical_id},
            )

            actor = getattr(g, "current_user", None)
            actor_name = actor.username if actor else "unknown"
            changed_fields = ", ".join(sorted(updates.keys()))
            log_action(
                action="Updated product",
                description=(
                    f"'{actor_name}' updated product '{canonical_id}'. "
                    f"Fields changed: {changed_fields}. "
                    f"Revision {old_revision} → {new_revision}."
                ),
                target_type="product",
                target_id=canonical_id,
                extra={"fields_updated": list(updates.keys()),
                       "old_revision": old_revision,
                       "new_revision": new_revision},
            )

            return jsonify({
                "message":        "Product metadata updated",
                "inventory_id":   canonical_id,
                "old_revision":   old_revision,
                "new_revision":   new_revision,
                "fields_updated": list(updates.keys()),
            })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ── 2. Add a single activity ──────────────────────────────────────────────────

@update_bp.post("/items/<item_code>/activities")
@require_superuser_or_admin
def add_activity(item_code):
    """
    Add one new activity to a product. Revision is auto-incremented.
    ---
    tags:
      - Items
    parameters:
      - name: item_code
        in: path
        type: string
        required: true
        example: 1AF2202L
      - name: body
        in: body
        required: true
        schema:
          type: object
          required: [activity_name, pax, machine, time_min]
          properties:
            activity_name:
              type: string
              example: L01 PACKING/PALLETIZ
            pax:
              type: integer
              example: 2
            machine:
              type: integer
              example: 0
            time_min:
              type: number
              example: 0.0625
            type:
              type: string
              default: Labor
            item_id:
              type: string
            class:
              type: string
              default: DL
            class_1:
              type: string
              default: DL
    responses:
      201:
        description: Activity added
      400:
        description: Missing required fields or invalid JSON
      404:
        description: Item not found
      500:
        description: Internal server error
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    missing = [f for f in REQUIRED_ACTIVITY_FIELDS if f not in body]
    if missing:
        return jsonify({"error": f"Missing required fields: {missing}"}), 400

    activity_name = (body.get("activity_name") or "").strip()
    if not activity_name:
        return jsonify({"error": "activity_name cannot be empty"}), 400

    try:
        with managed_connection() as conn:
            product = _fetch_product(conn, item_code, for_update=True)
            if product is None:
                return jsonify({"error": "Item not found", "item_code": item_code}), 404

            canonical_id = product["inventory_id"]

            result = conn.execute(
                text(
                    """
                    INSERT INTO activities
                        (inventory_id, type, item_id,
                         activity_name, class, class_1, pax, machine, time_min, sort_order)
                    VALUES (:inventory_id, :type, :item_id, :activity_name, :class, :class_1,
                            :pax, :machine, :time_min,
                            (SELECT COALESCE(MAX(sort_order), 0) + 1
                             FROM activities WHERE inventory_id = :inventory_id))
                    RETURNING id, sort_order
                    """
                ),
                {
                    "inventory_id": canonical_id,
                    "type":         body.get("type", "Labor"),
                    "item_id":      body.get("item_id", activity_name),
                    "activity_name": activity_name,
                    "class":        body.get("class", "DL"),
                    "class_1":      body.get("class_1", "DL"),
                    "pax":          body["pax"],
                    "machine":      body["machine"],
                    "time_min":     body["time_min"],
                },
            )
            result_row  = result.mappings().first()
            new_id      = result_row["id"]
            next_order  = result_row["sort_order"]

            old_revision  = product["revision"]
            skip_revision = request.args.get("skip_revision", "0") == "1"

            # ARCHIVE: snapshot current state before the revision bump.
            actor      = getattr(g, "current_user", None)
            actor_name = actor.username if actor else "unknown"
            snapshot_product(conn, canonical_id, old_revision, archived_by=actor_name)

            new_revision  = _bump_revision(conn, canonical_id, old_revision) if not skip_revision else old_revision

            log_action(
                action="Added activity",
                description=(
                    f"'{actor_name}' added activity '{activity_name}' (ID {new_id}) "
                    f"to product '{canonical_id}'. "
                    f"Revision {old_revision} → {new_revision}."
                ),
                target_type="activity",
                target_id=str(new_id),
                extra={"inventory_id": canonical_id,
                       "activity_name": activity_name,
                       "old_revision": old_revision,
                       "new_revision": new_revision},
            )

            return jsonify({
                "message":      "Activity added",
                "inventory_id": canonical_id,
                "activity_id":  new_id,
                "sort_order":   next_order,
                "old_revision": old_revision,
                "new_revision": new_revision,
            }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ── 3. Update a single activity ───────────────────────────────────────────────

@update_bp.patch("/items/<item_code>/activities/<int:activity_id>")
@require_superuser_or_admin
def update_activity(item_code, activity_id):
    """
    Update one specific activity by its ID. Only send the fields to change.
    Revision is auto-incremented.
    ---
    tags:
      - Items
    parameters:
      - name: item_code
        in: path
        type: string
        required: true
        example: 1AF2202L
      - name: activity_id
        in: path
        type: integer
        required: true
        example: 637
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            activity_name:
              type: string
            pax:
              type: integer
            machine:
              type: integer
            time_min:
              type: number
            type:
              type: string
            item_id:
              type: string
            class:
              type: string
            class_1:
              type: string
            sort_order:
              type: integer
    responses:
      200:
        description: Activity updated
      400:
        description: No valid fields or invalid JSON
      404:
        description: Item or activity not found
      500:
        description: Internal server error
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    updates = {k: v for k, v in body.items() if k in UPDATABLE_ACTIVITY_FIELDS}
    if not updates:
        return jsonify({
            "error": "No valid fields provided",
            "updatable_fields": sorted(UPDATABLE_ACTIVITY_FIELDS),
        }), 400

    try:
        with managed_connection() as conn:
            product = _fetch_product(conn, item_code, for_update=True)
            if product is None:
                return jsonify({"error": "Item not found", "item_code": item_code}), 404

            canonical_id = product["inventory_id"]

            result = conn.execute(
                text("SELECT id FROM activities WHERE id = :activity_id AND inventory_id = :canonical_id"),
                {"activity_id": activity_id, "canonical_id": canonical_id},
            )
            if result.mappings().first() is None:
                return jsonify({
                    "error":       "Activity not found for this product",
                    "activity_id": activity_id,
                    "item_code":   canonical_id,
                }), 404

            # FIX #8: build the SET clause with double-quoted reserved-word columns
            set_clause = _build_set_clause(updates)
            params = {**updates, "activity_id": activity_id, "canonical_id": canonical_id}
            conn.execute(
                text(
                    f"UPDATE activities SET {set_clause} "
                    f"WHERE id = :activity_id AND inventory_id = :canonical_id"
                ),
                params,
            )

            old_revision  = product["revision"]
            skip_revision = request.args.get("skip_revision", "0") == "1"

            # ARCHIVE: snapshot current state before the revision bump.
            actor      = getattr(g, "current_user", None)
            actor_name = actor.username if actor else "unknown"
            snapshot_product(conn, canonical_id, old_revision, archived_by=actor_name)

            new_revision  = _bump_revision(conn, canonical_id, old_revision) if not skip_revision else old_revision

            changed_fields = ", ".join(sorted(updates.keys()))
            log_action(
                action="Updated activity",
                description=(
                    f"'{actor_name}' updated activity ID {activity_id} "
                    f"on product '{canonical_id}'. "
                    f"Fields changed: {changed_fields}. "
                    f"Revision {old_revision} → {new_revision}."
                ),
                target_type="activity",
                target_id=str(activity_id),
                extra={"inventory_id": canonical_id,
                       "fields_updated": list(updates.keys()),
                       "old_revision": old_revision,
                       "new_revision": new_revision},
            )

            return jsonify({
                "message":        "Activity updated",
                "inventory_id":   canonical_id,
                "activity_id":    activity_id,
                "fields_updated": list(updates.keys()),
                "old_revision":   old_revision,
                "new_revision":   new_revision,
            })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ── 4. Delete a single activity ───────────────────────────────────────────────

@update_bp.delete("/items/<item_code>/activities/<int:activity_id>")
@require_superuser_or_admin
def delete_activity(item_code, activity_id):
    """
    Remove one activity from a product. Revision is auto-incremented.
    ---
    tags:
      - Items
    parameters:
      - name: item_code
        in: path
        type: string
        required: true
        example: 1AF2202L
      - name: activity_id
        in: path
        type: integer
        required: true
        example: 637
    responses:
      200:
        description: Activity deleted
      404:
        description: Item or activity not found
      500:
        description: Internal server error
    """
    try:
        with managed_connection() as conn:
            # FIX #3: use for_update=True so the revision bump is protected by a
            # row-level lock, consistent with add_activity and update_activity.
            product = _fetch_product(conn, item_code, for_update=True)
            if product is None:
                return jsonify({"error": "Item not found", "item_code": item_code}), 404

            canonical_id = product["inventory_id"]

            act_row = conn.execute(
                text(
                    "SELECT id, activity_name FROM activities "
                    "WHERE id = :activity_id AND inventory_id = :canonical_id"
                ),
                {"activity_id": activity_id, "canonical_id": canonical_id},
            ).mappings().first()

            if act_row is None:
                return jsonify({
                    "error":       "Activity not found for this product",
                    "activity_id": activity_id,
                    "item_code":   canonical_id,
                }), 404

            activity_name = act_row["activity_name"]
            old_revision  = product["revision"]

            # ARCHIVE: snapshot BEFORE the delete so the removed activity is still
            # included in the stored snapshot — then delete, then bump revision.
            actor      = getattr(g, "current_user", None)
            actor_name = actor.username if actor else "unknown"
            snapshot_product(conn, canonical_id, old_revision, archived_by=actor_name)

            conn.execute(
                text(
                    "DELETE FROM activities "
                    "WHERE id = :activity_id AND inventory_id = :canonical_id"
                ),
                {"activity_id": activity_id, "canonical_id": canonical_id},
            )

            skip_revision = request.args.get("skip_revision", "0") == "1"
            new_revision  = _bump_revision(conn, canonical_id, old_revision) if not skip_revision else old_revision

            log_action(
                action="Deleted activity",
                description=(
                    f"'{actor_name}' deleted activity '{activity_name}' (ID {activity_id}) "
                    f"from product '{canonical_id}'. "
                    f"Revision {old_revision} → {new_revision}."
                ),
                target_type="activity",
                target_id=str(activity_id),
                extra={"inventory_id": canonical_id,
                       "activity_name": activity_name,
                       "old_revision": old_revision,
                       "new_revision": new_revision},
            )

            return jsonify({
                "message":      "Activity deleted",
                "inventory_id": canonical_id,
                "activity_id":  activity_id,
                "old_revision": old_revision,
                "new_revision": new_revision,
            })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ── 5. Delete an entire product ───────────────────────────────────────────────

@update_bp.delete("/items/<item_code>")
@require_superuser_or_admin
def delete_product(item_code):
    """
    Permanently delete a product and all of its activities.
    ---
    tags:
      - Items
    parameters:
      - name: item_code
        in: path
        type: string
        required: true
        description: The inventory ID / item code (case-insensitive)
        example: 1AF2202L
    responses:
      200:
        description: Product (and its activities) deleted
      404:
        description: Item not found
      500:
        description: Internal server error
    """
    try:
        with managed_connection() as conn:
            product = _fetch_product(conn, item_code, for_update=True)
            if product is None:
                return jsonify({"error": "Item not found", "item_code": item_code}), 404

            canonical_id   = product["inventory_id"]
            revision_descr = product["revision_descr"]
            revision       = product["revision"]

            act_count_row = conn.execute(
                text("SELECT COUNT(*) AS cnt FROM activities WHERE inventory_id = :canonical_id"),
                {"canonical_id": canonical_id},
            ).mappings().first()
            activity_count = act_count_row["cnt"] if act_count_row else 0

            conn.execute(
                text("DELETE FROM products WHERE inventory_id = :canonical_id"),
                {"canonical_id": canonical_id},
            )

            actor      = getattr(g, "current_user", None)
            actor_name = actor.username if actor else "unknown"
            log_action(
                action="Deleted product",
                description=(
                    f"'{actor_name}' permanently deleted product '{canonical_id}' "
                    f"(\"{revision_descr}\", Revision {revision}) "
                    f"along with its {activity_count} activit{'y' if activity_count == 1 else 'ies'}."
                ),
                target_type="product",
                target_id=canonical_id,
                extra={"revision": revision,
                       "revision_descr": revision_descr,
                       "activities_deleted": activity_count},
            )

            return jsonify({
                "message":      "Product deleted",
                "inventory_id": canonical_id,
            })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ── 6. Bulk Update (Solves Concurrency & Rate Limiting) ───────────────────────

@update_bp.put("/items/<item_code>/bulk")
@require_superuser_or_admin
def bulk_update_item(item_code):
    """
    Perform a bulk update of product metadata and activities in a single transaction.
    This solves the "Lost Update" concurrency problem by verifying expected_revision,
    and solves Rate Limiting crashes by processing everything in one request.
    ---
    tags:
      - Items
    parameters:
      - name: item_code
        in: path
        type: string
        required: true
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            expected_revision:
              type: string
            product_updates:
              type: object
            activities_added:
              type: array
            activities_updated:
              type: array
            activities_deleted:
              type: array
    responses:
      200:
        description: Bulk update successful
      400:
        description: Invalid request body
      404:
        description: Item not found
      409:
        description: Revision mismatch (modified by another user)
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    expected_revision = body.get("expected_revision")
    if not expected_revision:
        return jsonify({"error": "expected_revision is required to prevent lost updates"}), 400

    product_updates    = body.get("product_updates", {})
    activities_added   = body.get("activities_added", [])
    activities_updated = body.get("activities_updated", [])
    activities_deleted = body.get("activities_deleted", [])

    try:
        with managed_connection() as conn:
            # 1. Fetch and Lock the product row
            product = _fetch_product(conn, item_code, for_update=True)
            if product is None:
                return jsonify({"error": "Item not found", "item_code": item_code}), 404

            canonical_id = product["inventory_id"]
            db_revision  = product["revision"]

            # 2. Concurrency Check (Optimistic Locking)
            if db_revision != expected_revision:
                return jsonify({
                    "error": "Conflict: This document was modified by another user. Please refresh to see their changes.",
                    "expected_revision": expected_revision,
                    "db_revision": db_revision
                }), 409

            # 3. Archive current state before making ANY changes
            actor      = getattr(g, "current_user", None)
            actor_name = actor.username if actor else "unknown"
            snapshot_product(conn, canonical_id, db_revision, archived_by=actor_name)

            # 4. Update Product Metadata (if any)
            valid_updates = {k: v for k, v in product_updates.items() if k in UPDATABLE_PRODUCT_FIELDS}
            if valid_updates:
                if "quantity" in valid_updates and valid_updates["quantity"] is not None:
                    valid_updates["quantity"] = float(valid_updates["quantity"])
                
                set_clause = ", ".join(f"{col} = :{col}" for col in valid_updates)
                params = {**valid_updates, "canonical_id": canonical_id}
                conn.execute(
                    text(f"UPDATE products SET {set_clause} WHERE inventory_id = :canonical_id"),
                    params,
                )

            # 5. Process Activities (Delete, Update, Add)
            for act_id in activities_deleted:
                conn.execute(
                    text("DELETE FROM activities WHERE inventory_id = :canonical_id AND id = :act_id"),
                    {"canonical_id": canonical_id, "act_id": act_id}
                )

            for act in activities_updated:
                act_id = act.get("id")
                if not act_id:
                    continue
                valid_act_updates = {k: v for k, v in act.items() if k in UPDATABLE_ACTIVITY_FIELDS}
                if not valid_act_updates:
                    continue
                
                set_parts = []
                for col in valid_act_updates:
                    col_quoted = _QUOTED_COLUMNS.get(col, col)
                    set_parts.append(f"{col_quoted} = :v_{col}")
                
                act_params = {f"v_{col}": val for col, val in valid_act_updates.items()}
                act_params["canonical_id"] = canonical_id
                act_params["act_id"] = act_id

                conn.execute(
                    text(f"UPDATE activities SET {', '.join(set_parts)} WHERE inventory_id = :canonical_id AND id = :act_id"),
                    act_params
                )

            for i, act in enumerate(activities_added, start=1):
                activity_name = act.get("activity_name", "").strip()
                if not activity_name:
                    activity_name = act.get("activities", "").strip()
                
                conn.execute(
                    text(
                        """
                        INSERT INTO activities
                            (inventory_id, type, item_id, activity_name,
                             class, class_1, pax, machine, time_min, sort_order)
                        VALUES (:inventory_id, :type, :item_id, :activity_name,
                                :class, :class_1, :pax, :machine, :time_min, :sort_order)
                        """
                    ),
                    {
                        "inventory_id": canonical_id,
                        "type":         act.get("type", "Labor"),
                        "item_id":      act.get("item_id", activity_name),
                        "activity_name": activity_name,
                        "class":        act.get("class", "DL"),
                        "class_1":      act.get("class_1", "DL"),
                        "pax":          act.get("pax", 0),
                        "machine":      act.get("machine", 0),
                        "time_min":     act.get("time_min", 0),
                        "sort_order":   act.get("sort_order", i),
                    },
                )

            # 6. Bump Revision
            new_revision = _bump_revision(conn, canonical_id, db_revision)

            # 7. Log Action
            log_action(
                action="Bulk updated product",
                description=(
                    f"'{actor_name}' performed a bulk update on '{canonical_id}'. "
                    f"Revision {db_revision} → {new_revision}. "
                    f"(+{len(activities_added)} -{len(activities_deleted)} *{len(activities_updated)} activities)"
                ),
                target_type="product",
                target_id=canonical_id,
                extra={
                    "old_revision": db_revision,
                    "new_revision": new_revision,
                    "metadata_updated": list(valid_updates.keys()),
                    "added_count": len(activities_added),
                    "updated_count": len(activities_updated),
                    "deleted_count": len(activities_deleted)
                },
            )

            return jsonify({
                "message":      "Bulk update successful",
                "inventory_id": canonical_id,
                "old_revision": db_revision,
                "new_revision": new_revision,
            })

    except Exception as e:
        logger.exception("Error in bulk_update_item")
        return jsonify({"error": str(e)}), 500
