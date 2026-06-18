"""
Production lines resource.
"""

import psycopg2.errors
from flask import Blueprint, jsonify, request
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError

from db import get_connection, release_connection
from routes.utils.decorators import require_superuser_or_admin

production_lines_bp = Blueprint(
    "production_lines", __name__, url_prefix="/api"
)


@production_lines_bp.get("/production-lines")
@require_superuser_or_admin
def get_production_lines():
    """
    List all production lines and their activities
    ---
    tags:
      - Production Lines
    parameters:
      - name: limit
        in: query
        type: integer
        required: false
        default: 50
        description: Max number of production lines to return (capped at 200)
      - name: offset
        in: query
        type: integer
        required: false
        default: 0
        description: Number of production lines to skip, for paging
    responses:
      200:
        description: List of production lines with associated activities
    """
    # [M10 FIX] Paginate the lines themselves (there are only ~18 today, but
    # this keeps the response/memory footprint bounded as lines and their
    # activities grow) rather than fetching every line + every activity on
    # every request.
    limit = min(request.args.get("limit", 50, type=int), 200)
    offset = max(request.args.get("offset", 0, type=int), 0)

    conn = get_connection()
    try:
        result = conn.execute(
            text(
                """
                SELECT production_line_code, production_line_name
                FROM production_lines
                ORDER BY production_line_code
                LIMIT :limit OFFSET :offset
                """
            ),
            {"limit": limit, "offset": offset},
        )
        lines = result.mappings().all()

        line_codes = [line["production_line_code"] for line in lines]

        # [C3 FIX] Include `id` so the frontend can delete/update individual activities
        # [M10 FIX] Only pull activities for the lines on this page, instead
        # of the full line_activities table every time.
        result = conn.execute(
            text(
                """
                SELECT id, production_line_code, activity_name, sort_order
                FROM line_activities
                WHERE production_line_code = ANY(:line_codes)
                ORDER BY production_line_code, sort_order
                """
            ),
            {"line_codes": line_codes},
        )
        activities = result.mappings().all()

        line_map = {}
        for line in lines:
            code = line["production_line_code"]
            line_map[code] = {
                "production_line_code": code,
                "production_line_name": line["production_line_name"],
                "activities": [],
            }

        for act in activities:
            code = act["production_line_code"]
            if code in line_map:
                # [C3 FIX] Pass `id` through to the response
                line_map[code]["activities"].append(
                    {
                        "id": act["id"],
                        "activity_name": act["activity_name"],
                        "sort_order": act["sort_order"],
                    }
                )

        return jsonify(list(line_map.values()))
    finally:
        release_connection(conn)


@production_lines_bp.get("/production-lines/<line_code>")
@require_superuser_or_admin
def get_production_line(line_code):
    """
    Get a single production line and its activities
    ---
    tags:
      - Production Lines
    parameters:
      - name: line_code
        in: path
        type: string
        required: true
        description: Production line code (case-insensitive)
        example: L01
    responses:
      200:
        description: Production line details with activities
      404:
        description: Production line not found
    """
    conn = get_connection()
    try:
        result = conn.execute(
            text(
                """
                SELECT production_line_code, production_line_name
                FROM production_lines
                WHERE UPPER(production_line_code) = UPPER(:line_code)
                """
            ),
            {"line_code": line_code},
        )
        line = result.mappings().first()

        if line is None:
            return (
                jsonify(
                    {
                        "error": "Production line not found",
                        "line_code": line_code,
                    }
                ),
                404,
            )

        # [M6 FIX] Include `id` here too, consistent with the list endpoint
        result = conn.execute(
            text(
                """
                SELECT id, activity_name, sort_order
                FROM line_activities
                WHERE UPPER(production_line_code) = UPPER(:line_code)
                ORDER BY sort_order
                """
            ),
            {"line_code": line_code},
        )
        activities = result.mappings().all()

        line_result = dict(line)
        line_result["activities"] = [dict(a) for a in activities]

        return jsonify(line_result)
    finally:
        release_connection(conn)


@production_lines_bp.put("/production-lines/<line_code>")
@require_superuser_or_admin
def update_production_line(line_code):
    """
    Replace a production line and its activities atomically
    ---
    tags:
      - Production Lines
    parameters:
      - name: line_code
        in: path
        type: string
        required: true
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            production_line_name:
              type: string
            activities:
              type: array
    responses:
      200:
        description: Line updated
      404:
        description: Line not found
      400:
        description: Invalid JSON or missing activity fields
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    new_name = body.get("production_line_name")
    activities = body.get("activities", [])

    # [C4 FIX] Validate all activities up-front before touching the DB
    for idx, act in enumerate(activities):
        if not (act.get("activity_name") or "").strip():
            return jsonify({
                "error": f"Activity at index {idx} is missing a non-empty activity_name"
            }), 400
        if not isinstance(act.get("sort_order"), int):
            return jsonify({
                "error": f"Activity at index {idx} must have an integer sort_order"
            }), 400

    conn = get_connection()
    try:
        result = conn.execute(
            text("SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(:line_code)"),
            {"line_code": line_code},
        )
        if result.mappings().first() is None:
            return (
                jsonify(
                    {"error": "Production line not found", "line_code": line_code}
                ),
                404,
            )

        if new_name:
            conn.execute(
                text("UPDATE production_lines SET production_line_name = :new_name WHERE production_line_code = :line_code"),
                {"new_name": new_name, "line_code": line_code},
            )

        conn.execute(
            text("DELETE FROM line_activities WHERE production_line_code = :line_code"),
            {"line_code": line_code},
        )
        for act in activities:
            conn.execute(
                text(
                    """
                    INSERT INTO line_activities
                        (production_line_code, activity_name, sort_order, stage)
                    VALUES (:line_code, :activity_name, :sort_order, :stage)
                    """
                ),
                {
                    "line_code": line_code,
                    "activity_name": act["activity_name"].strip(),
                    "sort_order": act["sort_order"],
                    "stage": act.get("stage"),
                },
            )

        conn.commit()
        return jsonify(
            {
                "message": "Production line updated",
                "line_code": line_code,
                "activities": len(activities),
            }
        )
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


# ── Create / rename / delete a production line ────────────────────────────────

@production_lines_bp.post("/production-lines")
@require_superuser_or_admin
def create_production_line():
    """
    Create a new production line
    ---
    tags:
      - Production Lines
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required: [production_line_code, production_line_name]
          properties:
            production_line_code:
              type: string
              example: L20
            production_line_name:
              type: string
              example: Line 20 - Filling
    responses:
      201:
        description: Production line created
      400:
        description: Missing required fields or invalid JSON
      409:
        description: Production line code already exists
      500:
        description: Internal server error
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    line_code = (body.get("production_line_code") or "").strip()
    line_name = (body.get("production_line_name") or "").strip()

    if not line_code or not line_name:
        return jsonify({
            "error": "Both production_line_code and production_line_name are required"
        }), 400

    conn = get_connection()
    try:
        result = conn.execute(
            text("SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(:line_code)"),
            {"line_code": line_code},
        )
        if result.mappings().first() is not None:
            return jsonify({
                "error": "Production line code already exists",
                "line_code": line_code,
            }), 409

        conn.execute(
            text("INSERT INTO production_lines (production_line_code, production_line_name) VALUES (:line_code, :line_name)"),
            {"line_code": line_code, "line_name": line_name},
        )

        conn.commit()
        return jsonify({
            "message": "Production line created",
            "production_line_code": line_code,
            "production_line_name": line_name,
        }), 201
    except IntegrityError:
        conn.rollback()
        return jsonify({"error": "Production line code already exists", "line_code": line_code}), 409
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


@production_lines_bp.patch("/production-lines/<line_code>")
@require_superuser_or_admin
def rename_production_line(line_code):
    """
    Rename a production line
    ---
    tags:
      - Production Lines
    parameters:
      - name: line_code
        in: path
        type: string
        required: true
        example: L01
      - name: body
        in: body
        required: true
        schema:
          type: object
          required: [production_line_name]
          properties:
            production_line_name:
              type: string
              example: Line 01 - Filling & Labeling
    responses:
      200:
        description: Production line renamed
      400:
        description: Missing production_line_name or invalid JSON
      404:
        description: Production line not found
      500:
        description: Internal server error
    """
    body = request.get_json(force=True, silent=True)
    if not body or not body.get("production_line_name"):
        return jsonify({"error": "production_line_name is required"}), 400

    new_name = body["production_line_name"].strip()

    conn = get_connection()
    try:
        result = conn.execute(
            text("SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(:line_code)"),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        conn.execute(
            text("UPDATE production_lines SET production_line_name = :new_name WHERE production_line_code = :canonical_code"),
            {"new_name": new_name, "canonical_code": canonical_code},
        )

        conn.commit()
        return jsonify({
            "message": "Production line renamed",
            "production_line_code": canonical_code,
            "production_line_name": new_name,
        })
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


@production_lines_bp.delete("/production-lines/<line_code>")
@require_superuser_or_admin
def delete_production_line(line_code):
    """
    Delete a production line and its activities
    ---
    tags:
      - Production Lines
    parameters:
      - name: line_code
        in: path
        type: string
        required: true
        example: L01
    responses:
      200:
        description: Production line deleted
      404:
        description: Production line not found
      409:
        description: Production line is still referenced by one or more products
      500:
        description: Internal server error
    """
    conn = get_connection()
    try:
        result = conn.execute(
            text("SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(:line_code)"),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        # [H11 FIX] The free-text bm_production_line/fg_production_line
        # columns aren't FK-constrained, so a product can reference this line
        # by name (e.g. "L01 - L1 COATINGS") while its *_code column is NULL
        # or stale. Checking only the code columns lets that product's text
        # go stale with no referential integrity once the line is gone, so
        # this also matches on the free-text columns starting with the code.
        result = conn.execute(
            text(
                """
                SELECT inventory_id FROM products
                WHERE bm_production_line_code = :canonical_code
                   OR fg_production_line_code = :canonical_code
                   OR bm_production_line ILIKE :code_prefix
                   OR fg_production_line ILIKE :code_prefix
                LIMIT 1
                """
            ),
            {"canonical_code": canonical_code, "code_prefix": f"{canonical_code} - %"},
        )
        if result.mappings().first() is not None:
            return jsonify({
                "error": "Production line is still in use by one or more products and cannot be deleted",
                "line_code": canonical_code,
            }), 409

        conn.execute(
            text("DELETE FROM production_lines WHERE production_line_code = :canonical_code"),
            {"canonical_code": canonical_code},
        )

        conn.commit()
        return jsonify({
            "message": "Production line deleted",
            "production_line_code": canonical_code,
        })
    # [H3 FIX] Catch any FK violation from tables we didn't check manually
    except IntegrityError as e:
        conn.rollback()
        if isinstance(e.orig, psycopg2.errors.ForeignKeyViolation):
            return jsonify({
                "error": "Production line is still referenced by another record and cannot be deleted",
                "line_code": line_code,
            }), 409
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


# ── Add / update / delete a single activity on a line ──────────────────────────

@production_lines_bp.post("/production-lines/<line_code>/activities")
@require_superuser_or_admin
def add_line_activity(line_code):
    """
    Add a single activity to a production line
    ---
    tags:
      - Production Lines
    parameters:
      - name: line_code
        in: path
        type: string
        required: true
        example: L01
      - name: body
        in: body
        required: true
        schema:
          type: object
          required: [activity_name]
          properties:
            activity_name:
              type: string
              example: L01 FILLING
            sort_order:
              type: integer
              description: Defaults to the next available position on the line
            stage:
              type: string
    responses:
      201:
        description: Activity added
      400:
        description: Missing activity_name or invalid JSON
      404:
        description: Production line not found
      409:
        description: Activity already exists on this line
      500:
        description: Internal server error
    """
    body = request.get_json(force=True, silent=True)
    if not body or not (body.get("activity_name") or "").strip():
        return jsonify({"error": "activity_name is required and must be non-empty"}), 400

    conn = get_connection()
    try:
        # [H4 FIX] FOR UPDATE locks this production line's row for the rest of the
        # transaction. If two requests race to add an activity to the same line,
        # the second blocks here until the first commits — so it computes
        # MAX(sort_order) against the now-updated table instead of a stale
        # snapshot, which is what actually prevents duplicate sort_orders.
        # A bare MAX+1 subquery inside the INSERT, on its own, is NOT atomic
        # across concurrent transactions under READ COMMITTED.
        result = conn.execute(
            text("SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(:line_code) FOR UPDATE"),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        sort_order = body.get("sort_order")
        if sort_order is None:
            result = conn.execute(
                text(
                    """
                    INSERT INTO line_activities (production_line_code, activity_name, sort_order, stage)
                    VALUES (
                        :canonical_code, :activity_name,
                        (SELECT COALESCE(MAX(sort_order), 0) + 1 FROM line_activities WHERE production_line_code = :canonical_code),
                        :stage
                    )
                    RETURNING id, sort_order
                    """
                ),
                {
                    "canonical_code": canonical_code,
                    "activity_name": body["activity_name"].strip(),
                    "stage": body.get("stage"),
                },
            )
        else:
            result = conn.execute(
                text(
                    """
                    INSERT INTO line_activities (production_line_code, activity_name, sort_order, stage)
                    VALUES (:canonical_code, :activity_name, :sort_order, :stage)
                    RETURNING id, sort_order
                    """
                ),
                {
                    "canonical_code": canonical_code,
                    "activity_name": body["activity_name"].strip(),
                    "sort_order": sort_order,
                    "stage": body.get("stage"),
                },
            )

        result_row = result.mappings().first()
        new_id = result_row["id"]
        final_sort_order = result_row["sort_order"]

        conn.commit()
        return jsonify({
            "message": "Activity added",
            "production_line_code": canonical_code,
            "activity_id": new_id,
            "sort_order": final_sort_order,
        }), 201
    except IntegrityError:
        conn.rollback()
        return jsonify({
            "error": "This activity already exists on this production line",
            "line_code": line_code,
        }), 409
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


@production_lines_bp.patch("/production-lines/<line_code>/activities/<int:activity_id>")
@require_superuser_or_admin
def update_line_activity(line_code, activity_id):
    """
    Update a single activity on a production line
    ---
    tags:
      - Production Lines
    parameters:
      - name: line_code
        in: path
        type: string
        required: true
        example: L01
      - name: activity_id
        in: path
        type: integer
        required: true
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            activity_name:
              type: string
            sort_order:
              type: integer
            stage:
              type: string
    responses:
      200:
        description: Activity updated
      400:
        description: No valid fields provided or invalid JSON
      404:
        description: Production line or activity not found
      409:
        description: Activity name already exists on this line
      500:
        description: Internal server error
    """
    # SECURITY: Only hardcoded field names reach set_clause — never add user-supplied keys here.
    UPDATABLE_LINE_ACTIVITY_FIELDS = {"activity_name", "sort_order", "stage"}

    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    updates = {k: v for k, v in body.items() if k in UPDATABLE_LINE_ACTIVITY_FIELDS}
    if not updates:
        return jsonify({
            "error": "No valid fields provided",
            "updatable_fields": sorted(UPDATABLE_LINE_ACTIVITY_FIELDS),
        }), 400

    conn = get_connection()
    try:
        result = conn.execute(
            text("SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(:line_code)"),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        result = conn.execute(
            text("SELECT id FROM line_activities WHERE id = :activity_id AND production_line_code = :canonical_code"),
            {"activity_id": activity_id, "canonical_code": canonical_code},
        )
        if result.mappings().first() is None:
            return jsonify({
                "error": "Activity not found for this production line",
                "activity_id": activity_id,
                "line_code": canonical_code,
            }), 404

        set_clause = ", ".join(f"{col} = :{col}" for col in updates)
        params = {**updates, "activity_id": activity_id, "canonical_code": canonical_code}
        conn.execute(
            text(f"UPDATE line_activities SET {set_clause} WHERE id = :activity_id AND production_line_code = :canonical_code"),
            params,
        )

        conn.commit()
        return jsonify({
            "message": "Activity updated",
            "production_line_code": canonical_code,
            "activity_id": activity_id,
            "fields_updated": list(updates.keys()),
        })
    except IntegrityError:
        conn.rollback()
        return jsonify({
            "error": "This activity name already exists on this production line",
            "line_code": line_code,
        }), 409
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


@production_lines_bp.delete("/production-lines/<line_code>/activities/<int:activity_id>")
@require_superuser_or_admin
def delete_line_activity(line_code, activity_id):
    """
    Delete a single activity from a production line
    ---
    tags:
      - Production Lines
    parameters:
      - name: line_code
        in: path
        type: string
        required: true
        example: L01
      - name: activity_id
        in: path
        type: integer
        required: true
    responses:
      200:
        description: Activity deleted
      404:
        description: Production line or activity not found
      500:
        description: Internal server error
    """
    conn = get_connection()
    try:
        result = conn.execute(
            text("SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(:line_code)"),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        result = conn.execute(
            text("SELECT id FROM line_activities WHERE id = :activity_id AND production_line_code = :canonical_code"),
            {"activity_id": activity_id, "canonical_code": canonical_code},
        )
        if result.mappings().first() is None:
            return jsonify({
                "error": "Activity not found for this production line",
                "activity_id": activity_id,
                "line_code": canonical_code,
            }), 404

        conn.execute(
            text("DELETE FROM line_activities WHERE id = :activity_id AND production_line_code = :canonical_code"),
            {"activity_id": activity_id, "canonical_code": canonical_code},
        )

        conn.commit()
        return jsonify({
            "message": "Activity deleted",
            "production_line_code": canonical_code,
            "activity_id": activity_id,
        })
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)