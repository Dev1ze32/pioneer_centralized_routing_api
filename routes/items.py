"""
Items resource.

FIX #2 — create_item() now uses managed_connection() throughout. The old
get_connection() + manual try/except/finally had early returns inside the
try block that could leave connections in the pool with open (uncommitted,
not-rolled-back) transactions.

FIX #1 — all read-only endpoints also use managed_connection() so any
mid-query error is always followed by an explicit rollback before the
connection is returned to the pool.

FIX #23 — create_item() now calls log_action() after a successful insert
so product creation is recorded in the audit log, consistent with all other
mutating endpoints.
"""

from flask import Blueprint, jsonify, request
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from db import managed_connection
from routes.utils.decorators import require_auth, require_superuser_or_admin
from routes.utils.log_utils import log_action

items_bp = Blueprint("items", __name__, url_prefix="/api")


@items_bp.get("/items/<path:item_code>")
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
    with managed_connection() as conn:
        result = conn.execute(
            text(
                """
                SELECT inventory_id, revision_descr, revision, notes, product_type,
                       quantity,
                       bm_production_line, bm_production_line_code,
                       fg_production_line, fg_production_line_code,
                       total_run_time, total_labor_min, total_mc_min,
                       total_dl_units, total_dl, total_voh, total_foh,
                       created_at, updated_at
                FROM products
                WHERE UPPER(inventory_id) = UPPER(:item_code)
                """
            ),
            {"item_code": item_code},
        )
        product = result.mappings().first()

        if product is None:
            return jsonify({"error": "Item code not found", "item_code": item_code}), 404

        result = conn.execute(
            text(
                """
                SELECT id, type, item_id, activity_name AS activities,
                       class, class_1, pax, machine, time_min,
                       run_time, labor_min, mc_min, dl_units, dl, voh, foh
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
          required: [inventory_id]
          properties:
            inventory_id:
              type: string
            revision_descr:
              type: string
            quantity:
              type: number
            product_type:
              type: string
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
              items:
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
                  run_time:
                    type: number
                  labor_min:
                    type: number
                  mc_min:
                    type: number
                  dl_units:
                    type: number
                  dl:
                    type: number
                  voh:
                    type: number
                  foh:
                    type: number
    responses:
      201:
        description: Product created successfully
      400:
        description: Validation error
      409:
        description: Item code already exists
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    inventory_id = (body.get("inventory_id") or "").strip().upper()
    if not inventory_id:
        return jsonify({"error": "inventory_id is required"}), 400

    revision_descr = body.get("revision_descr", "")
    product_type   = body.get("product_type", "")
    quantity       = body.get("quantity")

    if quantity in (None, ""):
        quantity = 0.0
    else:
        try:
            quantity = float(quantity)
        except (TypeError, ValueError):
            return jsonify({"error": "quantity must be a number"}), 400
    if quantity != int(quantity):
        return jsonify({"error": "quantity must be a whole number"}), 400

    # Validate activities before touching the DB
    raw_activities = body.get("activities", [])
    for idx, act in enumerate(raw_activities):
        if not (act.get("activity_name") or "").strip():
            return jsonify({
                "error": f"Activity at index {idx} is missing a non-empty activity_name"
            }), 400

    # FIX #2: managed_connection() guarantees rollback + pool return on any
    # early return or exception — no more leaked open transactions.
    try:
        with managed_connection() as conn:
            # Validate production line codes against the production_lines table
            for code_field in ("fg_production_line_code", "bm_production_line_code"):
                code = body.get(code_field)
                if code:
                    row = conn.execute(
                        text("SELECT 1 FROM production_lines WHERE production_line_code = :c"),
                        {"c": code},
                    ).first()
                    if not row:
                        return jsonify({"error": f"{code_field} '{code}' does not exist"}), 400

            # Check for duplicate inventory_id
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
                    """
                ),
                {
                    "inventory_id":            inventory_id,
                    "revision_descr":          revision_descr,
                    "revision":                "00",
                    "quantity":                quantity,
                    "product_type":            product_type,
                    "fg_production_line":      body.get("fg_production_line"),
                    "fg_production_line_code": body.get("fg_production_line_code"),
                    "bm_production_line":      body.get("bm_production_line"),
                    "bm_production_line_code": body.get("bm_production_line_code"),
                    "notes":                   body.get("notes"),
                    "total_run_time":  body.get("total_run_time",  0.0),
                    "total_labor_min": body.get("total_labor_min", 0.0),
                    "total_mc_min":    body.get("total_mc_min",    0.0),
                    "total_dl_units":  body.get("total_dl_units",  0.0),
                    "total_dl":        body.get("total_dl",        0.0),
                    "total_voh":       body.get("total_voh",       0.0),
                    "total_foh":       body.get("total_foh",       0.0),
                },
            )

            for i, act in enumerate(raw_activities, start=1):
                activity_name = act["activity_name"].strip()
                conn.execute(
                    text(
                        """
                        INSERT INTO activities
                            (inventory_id, type, item_id, activity_name,
                             class, class_1, pax, machine, time_min, sort_order,
                             run_time, labor_min, mc_min, dl_units, dl, voh, foh)
                        VALUES (:inventory_id, :type, :item_id, :activity_name,
                                :class, :class_1, :pax, :machine, :time_min, :sort_order,
                                :run_time, :labor_min, :mc_min, :dl_units, :dl, :voh, :foh)
                        """
                    ),
                    {
                        "inventory_id": inventory_id,
                        "type":         act.get("type", "Labor"),
                        "item_id":      act.get("item_id", activity_name),
                        "activity_name": activity_name,
                        "class":        act.get("class", "DL"),
                        "class_1":      act.get("class_1", "DL"),
                        "pax":          act.get("pax", 0),
                        "machine":      act.get("machine", 0),
                        "time_min":     act.get("time_min", 0),
                        "sort_order":   act.get("sort_order", i),
                        "run_time":     act.get("run_time", 0.0),
                        "labor_min":    act.get("labor_min", 0.0),
                        "mc_min":       act.get("mc_min", 0.0),
                        "dl_units":     act.get("dl_units", 0.0),
                        "dl":           act.get("dl", 0.0),
                        "voh":          act.get("voh", 0.0),
                        "foh":          act.get("foh", 0.0),
                    },
                )

        # FIX #23: log the creation after the transaction commits successfully.
        # Placed outside the with-block so it only runs on clean exit,
        # and outside the try/except so errors here don't suppress the 201.
        log_action(
            action="Created product",
            description=(
                f"Product '{inventory_id}' (type: {product_type}) was created "
                f"with {len(raw_activities)} "
                f"activit{'y' if len(raw_activities) == 1 else 'ies'}."
            ),
            target_type="product",
            target_id=inventory_id,
            extra={
                "product_type":            product_type,
                "revision_descr":          revision_descr,
                "fg_production_line_code": body.get("fg_production_line_code"),
                "bm_production_line_code": body.get("bm_production_line_code"),
                "activity_count":          len(raw_activities),
            },
        )

        return jsonify({
            "message":      "Product created",
            "inventory_id": inventory_id,
            "revision":     "00",
        }), 201

    except IntegrityError:
        # managed_connection() already rolled back
        return jsonify({"error": "Item code already exists", "inventory_id": inventory_id}), 409
    except Exception as e:
        return jsonify({"error": str(e)}), 500


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
      - name: offset
        in: query
        type: integer
        required: false
        default: 0
        description: Number of items to skip, for pagination
    responses:
      200:
        description: List of matching items (summary, no activities)
    """
    q      = request.args.get("q", "").strip()
    limit  = min(request.args.get("limit", 50, type=int), 1000)
    offset = max(request.args.get("offset", 0, type=int), 0)

    with managed_connection() as conn:
        params: dict = {"limit": limit, "offset": offset}
        if q:
            params["q"] = f"%{q}%"
            where = "WHERE inventory_id ILIKE :q OR revision_descr ILIKE :q"
        else:
            where = ""

        # Total count so callers know when results are truncated
        count_result = conn.execute(
            text(f"SELECT COUNT(*) AS total FROM products {where}"),
            params,
        )
        total = count_result.mappings().first()["total"]

        result = conn.execute(
            text(
                f"""
                SELECT inventory_id, revision_descr, revision, product_type,
                       quantity,
                       bm_production_line, bm_production_line_code,
                       fg_production_line, fg_production_line_code
                FROM products
                {where}
                ORDER BY inventory_id
                LIMIT :limit OFFSET :offset
                """
            ),
            params,
        )
        rows = result.mappings().all()

    return jsonify({
        "total":   total,
        "limit":   limit,
        "offset":  offset,
        "results": [dict(r) for r in rows],
    })