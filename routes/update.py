"""
Update resource.

Endpoints
---------
PATCH /api/items/<item_code>
    Update product metadata only (notes, production line, etc.).
    Revision is auto-incremented.

POST  /api/items/<item_code>/activities
    Add a single new activity to a product.
    Revision is auto-incremented.

PATCH /api/items/<item_code>/activities/<activity_id>
    Update a single existing activity by its DB id.
    Revision is auto-incremented.

DELETE /api/items/<item_code>/activities/<activity_id>
    Remove a single activity from a product.
    Revision is auto-incremented.

DELETE /api/items/<item_code>
    Permanently delete an entire product, along with all of its
    activities (cascades at the DB level).
"""

from typing import Optional

from flask import Blueprint, jsonify, request
from sqlalchemy import text
from sqlalchemy.engine import Connection

from db import get_connection, release_connection

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
    # SECURITY: 'revision' must NEVER be added here — it is managed exclusively
    # by _bump_revision() and is injected separately into the SET clause.
    # Adding it here would allow callers to overwrite the auto-increment value.
}

REQUIRED_ACTIVITY_FIELDS = ("activity_name", "pax", "machine", "time_min")

# [H7 FIX] Moved to module level — was re-created on every request inside update_activity()
# SECURITY: Only hardcoded field names reach the f-string SET clause.
# Never add user-supplied keys to this set.
UPDATABLE_ACTIVITY_FIELDS = {
    "activity_name", "type", "item_id",
    "class", "class_1", "pax", "machine", "time_min", "sort_order",
}

# ── Helpers ───────────────────────────────────────────────────────────────────


def _increment_revision(current: Optional[str]) -> str:
    """
    Increment a zero-padded revision string.
    "00" -> "01", "03" -> "04", "09" -> "10", "99" -> "100"
    None or unrecognised values start at "01".
    """
    try:
        num = int(current or "0") + 1
    except (ValueError, TypeError):
        num = 1
    return f"0{num}" if num < 10 else str(num)


def _fetch_product(conn: Connection, item_code: str, for_update: bool = False):
    """Return the product row (RowMapping) or None. Uses the canonical (exact) ID.

    for_update=True takes a row lock (SELECT ... FOR UPDATE) so that a concurrent
    request touching the same product serializes behind this one instead of
    racing on a value computed from the row (e.g. the next activity sort_order).
    Only pass for_update=True where that's actually needed — it holds a lock
    for the rest of the transaction.
    """
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
    """Write the incremented revision to the DB and return the new value.

    NOTE: Always call this AFTER all validation is complete so that a failed
    operation never silently advances the revision counter.
    """
    new_revision = _increment_revision(old_revision)
    conn.execute(
        text("UPDATE products SET revision = :new_revision WHERE inventory_id = :canonical_id"),
        {"new_revision": new_revision, "canonical_id": canonical_id},
    )
    return new_revision


# ── 1. Update product metadata ────────────────────────────────────────────────

@update_bp.patch("/items/<item_code>")
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

    # Only keep fields that are actually allowed to be updated.
    # 'revision' is intentionally excluded from UPDATABLE_PRODUCT_FIELDS so
    # callers cannot overwrite the auto-incremented value.
    updates = {k: v for k, v in body.items() if k in UPDATABLE_PRODUCT_FIELDS}
    VALID_PRODUCT_TYPES = {"Finished Good (FG)", "Base Material (BM)", "Other / Intermediate"}
    if "product_type" in updates and updates["product_type"] not in VALID_PRODUCT_TYPES:
        return jsonify({"error": f"Invalid product_type. Must be one of: {sorted(VALID_PRODUCT_TYPES)}"}), 400
    # [H8 FIX] quantity is semantically a whole number (matches the
    # products_quantity_whole_number CHECK constraint). Validate here too,
    # since this endpoint is the other place quantity can be written.
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

    conn = get_connection()
    try:
        product = _fetch_product(conn, item_code)
        if product is None:
            return jsonify({"error": "Item not found", "item_code": item_code}), 404

        canonical_id = product["inventory_id"]
        old_revision = product["revision"]
        new_revision = _increment_revision(old_revision)

        # [C6 FIX] Revision is set in its OWN explicit UPDATE, completely separate
        # from the user-field SET clause, so there is no risk of it being shadowed
        # or duplicated if UPDATABLE_PRODUCT_FIELDS is ever changed carelessly.
        set_clause = ", ".join(f"{col} = :{col}" for col in updates)
        params = {**updates, "canonical_id": canonical_id}
        conn.execute(
            text(f"UPDATE products SET {set_clause} WHERE inventory_id = :canonical_id"),
            params,
        )
        conn.execute(
            text("UPDATE products SET revision = :new_revision WHERE inventory_id = :canonical_id"),
            {"new_revision": new_revision, "canonical_id": canonical_id},
        )

        conn.commit()
        return jsonify({
            "message":        "Product metadata updated",
            "inventory_id":   canonical_id,
            "old_revision":   old_revision,
            "new_revision":   new_revision,
            "fields_updated": list(updates.keys()),
        })

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


# ── 2. Add a single activity ──────────────────────────────────────────────────

@update_bp.post("/items/<item_code>/activities")
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

    # [H6 FIX] Validate that activity_name is actually non-empty, not just present
    activity_name = (body.get("activity_name") or "").strip()
    if not activity_name:
        return jsonify({"error": "activity_name cannot be empty"}), 400

    conn = get_connection()
    try:
        # [H4 FIX] for_update=True locks this product's row so a concurrent
        # add_activity call on the same product blocks until this one commits,
        # rather than both racing to compute the same MAX(sort_order) + 1.
        product = _fetch_product(conn, item_code, for_update=True)
        if product is None:
            return jsonify({"error": "Item not found", "item_code": item_code}), 404

        canonical_id = product["inventory_id"]

        # Place the new activity after all existing ones (the row lock above is
        # what actually makes this race-free — see _fetch_product docstring)
        result = conn.execute(
            text(
                """
                INSERT INTO activities
                    (inventory_id, type, item_id,
                     activity_name, class, class_1, pax, machine, time_min, sort_order)
                VALUES (:inventory_id, :type, :item_id, :activity_name, :class, :class_1,
                        :pax, :machine, :time_min,
                        (SELECT COALESCE(MAX(sort_order), 0) + 1 FROM activities WHERE inventory_id = :inventory_id))
                RETURNING id, sort_order
                """
            ),
            {
                "inventory_id": canonical_id,
                "type": body.get("type", "Labor"),
                "item_id": body.get("item_id", activity_name),   # [H6 FIX] uses validated non-empty name
                "activity_name": activity_name,
                "class": body.get("class", "DL"),
                "class_1": body.get("class_1", "DL"),
                "pax": body["pax"],
                "machine": body["machine"],
                "time_min": body["time_min"],
            },
        )
        result_row = result.mappings().first()
        new_id = result_row["id"]
        next_order = result_row["sort_order"]

        old_revision = product["revision"]
        # [H9 FIX] This bump must stay inside the SAME transaction as the
        # operation above (no commit() between them). If _bump_revision()
        # raises, the surrounding except block rolls back the whole
        # transaction, so the activity insert/update/delete above is undone
        # too -- the bump is not optional or safe to move out on its own.
        skip_revision = request.args.get("skip_revision", "0") == "1"
        if not skip_revision:
            new_revision = _bump_revision(conn, canonical_id, old_revision)
        else:
            new_revision = old_revision

        conn.commit()
        return jsonify({
            "message":      "Activity added",
            "inventory_id": canonical_id,
            "activity_id":  new_id,
            "sort_order":   next_order,
            "old_revision": old_revision,
            "new_revision": new_revision,
        }), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


# ── 3. Update a single activity ───────────────────────────────────────────────

@update_bp.patch("/items/<item_code>/activities/<int:activity_id>")
def update_activity(item_code, activity_id):
    """
    Update one specific activity by its ID. Only send the fields you want to change.
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

    conn = get_connection()
    try:
        # [H7 FIX] for_update=True locks the product row for the rest of the
        # transaction, same as add_activity(). Without it, two concurrent
        # requests touching this product (e.g. one update racing another, or
        # an update racing an add) can both read a stale `revision` value and
        # each think they're applying the "next" revision, or otherwise step
        # on each other's partial writes.
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

        set_clause = ", ".join(f"{col} = :{col}" for col in updates)
        params = {**updates, "activity_id": activity_id, "canonical_id": canonical_id}
        conn.execute(
            text(f"UPDATE activities SET {set_clause} WHERE id = :activity_id AND inventory_id = :canonical_id"),
            params,
        )

        old_revision = product["revision"]
        # [H9 FIX] This bump must stay inside the SAME transaction as the
        # operation above (no commit() between them). If _bump_revision()
        # raises, the surrounding except block rolls back the whole
        # transaction, so the activity insert/update/delete above is undone
        # too -- the bump is not optional or safe to move out on its own.
        skip_revision = request.args.get("skip_revision", "0") == "1"
        if not skip_revision:
            new_revision = _bump_revision(conn, canonical_id, old_revision)
        else:
            new_revision = old_revision

        conn.commit()
        return jsonify({
            "message":        "Activity updated",
            "inventory_id":   canonical_id,
            "activity_id":    activity_id,
            "fields_updated": list(updates.keys()),
            "old_revision":   old_revision,
            "new_revision":   new_revision,
        })

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


# ── 4. Delete a single activity ───────────────────────────────────────────────

@update_bp.delete("/items/<item_code>/activities/<int:activity_id>")
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
    conn = get_connection()
    try:
        product = _fetch_product(conn, item_code)
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

        conn.execute(
            text("DELETE FROM activities WHERE id = :activity_id AND inventory_id = :canonical_id"),
            {"activity_id": activity_id, "canonical_id": canonical_id},
        )

        old_revision = product["revision"]
        # [H9 FIX] This bump must stay inside the SAME transaction as the
        # operation above (no commit() between them). If _bump_revision()
        # raises, the surrounding except block rolls back the whole
        # transaction, so the activity insert/update/delete above is undone
        # too -- the bump is not optional or safe to move out on its own.
        skip_revision = request.args.get("skip_revision", "0") == "1"
        if not skip_revision:
            new_revision = _bump_revision(conn, canonical_id, old_revision)
        else:
            new_revision = old_revision

        conn.commit()
        return jsonify({
            "message":      "Activity deleted",
            "inventory_id": canonical_id,
            "activity_id":  activity_id,
            "old_revision": old_revision,
            "new_revision": new_revision,
        })

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


# ── 5. Delete an entire product ───────────────────────────────────────────────

@update_bp.delete("/items/<item_code>")
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
    conn = get_connection()
    try:
        product = _fetch_product(conn, item_code)
        if product is None:
            return jsonify({"error": "Item not found", "item_code": item_code}), 404

        canonical_id = product["inventory_id"]

        conn.execute(
            text("DELETE FROM products WHERE inventory_id = :canonical_id"),
            {"canonical_id": canonical_id},
        )

        conn.commit()
        return jsonify({
            "message":      "Product deleted",
            "inventory_id": canonical_id,
        })

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)