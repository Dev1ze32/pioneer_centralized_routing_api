"""
Items resource.
"""

from flask import Blueprint, jsonify, request

from db import get_connection, get_dict_cursor

items_bp = Blueprint("items", __name__, url_prefix="/api")


@items_bp.get("/items/<item_code>")
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
    conn = get_connection()
    try:
        cur = get_dict_cursor(conn)

        cur.execute(
            """
            SELECT inventory_id, revision_descr, revision, notes, product_type,
                   quantity,
                   bm_production_line, bm_production_line_code,
                   fg_production_line, fg_production_line_code
            FROM products
            WHERE UPPER(inventory_id) = UPPER(%s)
            """,
            (item_code,),
        )
        product = cur.fetchone()

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

        cur.execute(
            """
            SELECT id, type, item_id, activity_name AS activities,
                class, class_1, pax, machine, time_min
            FROM activities
            WHERE inventory_id = %s
            ORDER BY sort_order
            """,
            (product["inventory_id"],),
        )
        activities = cur.fetchall()

        result = dict(product)
        result["activities"] = [dict(a) for a in activities]

        return jsonify(result)
    finally:
        conn.close()


@items_bp.post("/items")
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

    conn = get_connection()
    try:
        cur = get_dict_cursor(conn)

        # Check for duplicate
        cur.execute(
            "SELECT inventory_id FROM products WHERE UPPER(inventory_id) = UPPER(%s)",
            (inventory_id,),
        )
        if cur.fetchone():
            return jsonify({"error": "Item code already exists", "inventory_id": inventory_id}), 409

        cur.execute(
            """
            INSERT INTO products
                (inventory_id, revision_descr, revision, quantity, product_type,
                 fg_production_line, fg_production_line_code,
                 bm_production_line, bm_production_line_code, notes)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                inventory_id,
                revision_descr,
                "00",
                body.get("quantity", 1),
                product_type,
                body.get("fg_production_line"),
                body.get("fg_production_line_code"),
                body.get("bm_production_line"),
                body.get("bm_production_line_code"),
                body.get("notes"),
            ),
        )

        # Insert activities if provided
        for i, act in enumerate(body.get("activities", []), start=1):
            cur.execute(
                """
                INSERT INTO activities
                    (inventory_id, type, item_id, activity_name,
                     class, class_1, pax, machine, time_min, sort_order)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    inventory_id,
                    act.get("type", "Labor"),
                    act.get("item_id", act.get("activity_name", "")),
                    act.get("activity_name", ""),
                    act.get("class", "DL"),
                    act.get("class_1", "DL"),
                    act.get("pax", 0),
                    act.get("machine", 0),
                    act.get("time_min", 0),
                    i,
                ),
            )

        conn.commit()
        return jsonify({
            "message": "Product created",
            "inventory_id": inventory_id,
            "revision": "00",
        }), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()

@items_bp.get("/items")
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
    limit = request.args.get("limit", 50, type=int)

    conn = get_connection()
    try:
        cur = get_dict_cursor(conn)

        if q:
            cur.execute(
                """
                SELECT inventory_id, revision_descr, revision, product_type,
                       quantity,
                       bm_production_line, bm_production_line_code,
                       fg_production_line, fg_production_line_code
                FROM products
                WHERE inventory_id ILIKE %s OR revision_descr ILIKE %s
                ORDER BY inventory_id
                LIMIT %s
                """,
                (f"%{q}%", f"%{q}%", limit),
            )
        else:
            cur.execute(
                """
                SELECT inventory_id, revision_descr, revision, product_type,
                       quantity,
                       bm_production_line, bm_production_line_code,
                       fg_production_line, fg_production_line_code
                FROM products
                ORDER BY inventory_id
                LIMIT %s
                """,
                (limit,),
            )

        rows = cur.fetchall()
        return jsonify([dict(r) for r in rows])
    finally:
        conn.close()