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
            SELECT type, item_id, activity_name AS activities,
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