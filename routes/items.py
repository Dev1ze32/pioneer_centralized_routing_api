"""
Items resource.
"""

from flask import Blueprint, jsonify, request
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from db import get_connection, release_connection, managed_connection
from routes.decorators import require_auth, require_superuser_or_admin

items_bp = Blueprint("items", __name__, url_prefix="/api")


@items_bp.get("/items/<item_code>")
@require_auth
def get_item(item_code):
    """
    Look up an item code's routing details
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
        description: Routing details for the item, including activities
      404:
        description: Item code not found
    """
    # [H6 FIX] Use the managed_connection() context manager instead of a bare
    # get_connection()/finally pair, so the connection is always returned to
    # the pool (and any error correctly rolled back) regardless of where an
    # exception is raised.
    with managed_connection() as conn:
        result = conn.execute(
            text(
                """
                SELECT inventory_id, revision_descr, revision, notes, product_type,
                       quantity,
                       bm_production_line, bm_production_line_code,
                       fg_production_line, fg_production_line_code
                FROM products
                WHERE UPPER(inventory_id) = UPPER(:item_code)
                """
            ),
            {"item_code": item_code},
        )
        product = result.mappings().first()

        if product is None:
            return (
                jsonify(
                    {
                        "error": "Item code not found",
                        "item_code": item_code,
                    }
                ),
                404,
            )

        result = conn.execute(
            text(
                """
                SELECT id, type, item_id, activity_name AS activities,
                    class, class_1, pax, machine, time_min
                FROM activities
                WHERE inventory_id = :inventory_id
                ORDER BY sort_order
                """
            ),
            {"inventory_id": product["inventory_id"]},
        )
        activities = result.mappings().all()

        item_result = dict(product)
        item_result["activities"] = [dict(a) for a in activities]

        return jsonify(item_result)


@items_bp.post("/items")
@require_superuser_or_admin
def create_item():
    """
    Create a new product with optional activities
    ---
    tags:
      - Items
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required: [inventory_id, revision_descr, product_type]
          properties:
            inventory_id:
              type: string
              example: 1AF2202L
            revision_descr:
              type: string
            quantity:
              type: number
            product_type:
              type: string
              enum: ["Finished Good (FG)", "Base Material (BM)"]
            fg_production_line:
              type: string
            fg_production_line_code:
              type: string
            bm_production_line:
              type: string
            bm_production_line_code:
              type: string
            notes:
              type: string
            activities:
              type: array
    responses:
      201:
        description: Product created
      400:
        description: Missing required fields or invalid JSON
      409:
        description: Item code already exists
      500:
        description: Internal server error
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    inventory_id = (body.get("inventory_id") or "").strip()
    revision_descr = (body.get("revision_descr") or "").strip()
    product_type = (body.get("product_type") or "").strip()

    if not inventory_id or not revision_descr or not product_type:
        return jsonify({"error": "inventory_id, revision_descr, and product_type are required"}), 400

    # [H8 FIX] quantity is stored as double precision but is semantically a
    # whole number (matches the products_quantity_whole_number CHECK constraint
    # added in the data-fix migration). Validate up front so a bad value comes
    # back as a clean 400 instead of a raw Postgres CheckViolation / 500.
    quantity = body.get("quantity", 1)
    try:
        quantity = float(quantity)
    except (TypeError, ValueError):
        return jsonify({"error": "quantity must be a number"}), 400
    if quantity != int(quantity):
        return jsonify({"error": "quantity must be a whole number"}), 400

    # --- [C7 FIX] Validate activities before touching the DB ---
    raw_activities = body.get("activities", [])
    for idx, act in enumerate(raw_activities):
        if not (act.get("activity_name") or "").strip():
            return jsonify({
                "error": f"Activity at index {idx} is missing a non-empty activity_name"
            }), 400

    # [H8 FIX] Validate fg/bm_production_line_code against production_lines
    # before inserting, so an unknown code comes back as a clean 400 instead
    # of a raw FK-violation IntegrityError surfaced as a 500.
    conn = get_connection()
    try:
        for code_field in ("fg_production_line_code", "bm_production_line_code"):
            code = body.get(code_field)
            if code:
                row = conn.execute(
                    text("SELECT 1 FROM production_lines WHERE production_line_code = :c"),
                    {"c": code},
                ).first()
                if not row:
                    return jsonify({"error": f"{code_field} '{code}' does not exist"}), 400

        # Check for duplicate
        result = conn.execute(
            text("SELECT inventory_id FROM products WHERE UPPER(inventory_id) = UPPER(:inventory_id)"),
            {"inventory_id": inventory_id},
        )
        if result.mappings().first() is not None:
            return jsonify({"error": "Item code already exists", "inventory_id": inventory_id}), 409

        conn.execute(
            text(
                """
                INSERT INTO products
                    (inventory_id, revision_descr, revision, quantity, product_type,
                     fg_production_line, fg_production_line_code,
                     bm_production_line, bm_production_line_code, notes)
                VALUES (:inventory_id, :revision_descr, :revision, :quantity, :product_type,
                        :fg_production_line, :fg_production_line_code,
                        :bm_production_line, :bm_production_line_code, :notes)
                """
            ),
            {
                "inventory_id": inventory_id,
                "revision_descr": revision_descr,
                "revision": "00",
                "quantity": quantity,
                "product_type": product_type,
                "fg_production_line": body.get("fg_production_line"),
                "fg_production_line_code": body.get("fg_production_line_code"),
                "bm_production_line": body.get("bm_production_line"),
                "bm_production_line_code": body.get("bm_production_line_code"),
                "notes": body.get("notes"),
            },
        )

        # Insert activities
        for i, act in enumerate(raw_activities, start=1):
            activity_name = act["activity_name"].strip()
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
                    "inventory_id": inventory_id,
                    "type": act.get("type", "Labor"),
                    "item_id": act.get("item_id", activity_name),
                    "activity_name": activity_name,
                    "class": act.get("class", "DL"),
                    "class_1": act.get("class_1", "DL"),
                    "pax": act.get("pax", 0),
                    "machine": act.get("machine", 0),
                    "time_min": act.get("time_min", 0),
                    "sort_order": act.get("sort_order", i),   # [H5 FIX] respect caller sort_order
                },
            )

        conn.commit()
        return jsonify({
            "message": "Product created",
            "inventory_id": inventory_id,
            "revision": "00",
        }), 201

    # --- [C2 FIX] Catch IntegrityError separately for a clean 409 ---
    except IntegrityError:
        conn.rollback()
        return jsonify({"error": "Item code already exists", "inventory_id": inventory_id}), 409
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


@items_bp.get("/items")
@require_auth
def search_items():
    """
    Browse / search item codes
    ---
    tags:
      - Items
    parameters:
      - name: q
        in: query
        type: string
        required: false
        description: Partial, case-insensitive match on inventory_id or revision_descr
      - name: limit
        in: query
        type: integer
        required: false
        default: 50
    responses:
      200:
        description: List of matching items (summary, no activities)
    """
    q = request.args.get("q", "").strip()
    # [M2 FIX] Cap limit to prevent runaway full-table scans
    limit = min(request.args.get("limit", 50, type=int), 1000)

    # [H6 FIX] managed_connection() guarantees the connection is released
    # back to the pool even if something raises mid-query.
    with managed_connection() as conn:
        if q:
            result = conn.execute(
                text(
                    """
                    SELECT inventory_id, revision_descr, revision, product_type,
                           quantity,
                           bm_production_line, bm_production_line_code,
                           fg_production_line, fg_production_line_code
                    FROM products
                    WHERE inventory_id ILIKE :q OR revision_descr ILIKE :q
                    ORDER BY inventory_id
                    LIMIT :limit
                    """
                ),
                {"q": f"%{q}%", "limit": limit},
            )
        else:
            result = conn.execute(
                text(
                    """
                    SELECT inventory_id, revision_descr, revision, product_type,
                           quantity,
                           bm_production_line, bm_production_line_code,
                           fg_production_line, fg_production_line_code
                    FROM products
                    ORDER BY inventory_id
                    LIMIT :limit
                    """
                ),
                {"limit": limit},
            )

        rows = result.mappings().all()
        return jsonify([dict(r) for r in rows])