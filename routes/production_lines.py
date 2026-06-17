"""
Production lines resource.
"""

import psycopg2
from flask import Blueprint, jsonify, request

from db import get_connection, get_dict_cursor

production_lines_bp = Blueprint(
    "production_lines", __name__, url_prefix="/api"
)


@production_lines_bp.get("/production-lines")
def get_production_lines():
    """
    List all production lines and their activities
    ---
    tags:
      - Production Lines
    responses:
      200:
        description: List of production lines with associated activities
    """
    conn = get_connection()
    try:
        cur = get_dict_cursor(conn)

        cur.execute(
            """
            SELECT production_line_code, production_line_name
            FROM production_lines
            ORDER BY production_line_code
            """
        )
        lines = cur.fetchall()

        cur.execute(
            """
            SELECT id, production_line_code, activity_name, sort_order
            FROM line_activities
            ORDER BY production_line_code, sort_order
            """
        )
        activities = cur.fetchall()

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
                line_map[code]["activities"].append(
                    {
                        "id": act["id"],
                        "activity_name": act["activity_name"],
                        "sort_order": act["sort_order"],
                    }
                )

        return jsonify(list(line_map.values()))
    finally:
        conn.close()


@production_lines_bp.get("/production-lines/<line_code>")
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
        cur = get_dict_cursor(conn)

        cur.execute(
            """
            SELECT production_line_code, production_line_name
            FROM production_lines
            WHERE UPPER(production_line_code) = UPPER(%s)
            """,
            (line_code,),
        )
        line = cur.fetchone()

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

        cur.execute(
            """
            SELECT activity_name, sort_order
            FROM line_activities
            WHERE UPPER(production_line_code) = UPPER(%s)
            ORDER BY sort_order
            """,
            (line_code,),
        )
        activities = cur.fetchall()

        result = dict(line)
        result["activities"] = [dict(a) for a in activities]

        return jsonify(result)
    finally:
        conn.close()


@production_lines_bp.put("/production-lines/<line_code>")
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
        description: Invalid JSON
    """
    body = request.get_json(force=True, silent=True)
    if not body:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    new_name = body.get("production_line_name")
    activities = body.get("activities", [])

    conn = get_connection()
    try:
        cur = get_dict_cursor(conn)

        cur.execute(
            "SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(%s)",
            (line_code,),
        )
        if cur.fetchone() is None:
            return (
                jsonify(
                    {"error": "Production line not found", "line_code": line_code}
                ),
                404,
            )

        if new_name:
            cur.execute(
                "UPDATE production_lines SET production_line_name = %s WHERE production_line_code = %s",
                (new_name, line_code),
            )

        cur.execute(
            "DELETE FROM line_activities WHERE production_line_code = %s",
            (line_code,),
        )
        for act in activities:
            cur.execute(
                """
                INSERT INTO line_activities
                    (production_line_code, activity_name, sort_order, stage)
                VALUES (%s, %s, %s, %s)
                """,
                (
                    line_code,
                    act.get("activity_name"),
                    act.get("sort_order"),
                    act.get("stage"),
                ),
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
        conn.close()


# ── Create / rename / delete a production line ────────────────────────────────

@production_lines_bp.post("/production-lines")
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
        cur = get_dict_cursor(conn)

        cur.execute(
            "SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(%s)",
            (line_code,),
        )
        if cur.fetchone() is not None:
            return jsonify({
                "error": "Production line code already exists",
                "line_code": line_code,
            }), 409

        cur.execute(
            "INSERT INTO production_lines (production_line_code, production_line_name) VALUES (%s, %s)",
            (line_code, line_name),
        )

        conn.commit()
        return jsonify({
            "message": "Production line created",
            "production_line_code": line_code,
            "production_line_name": line_name,
        }), 201
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


@production_lines_bp.patch("/production-lines/<line_code>")
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
        cur = get_dict_cursor(conn)

        cur.execute(
            "SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(%s)",
            (line_code,),
        )
        row = cur.fetchone()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        cur.execute(
            "UPDATE production_lines SET production_line_name = %s WHERE production_line_code = %s",
            (new_name, canonical_code),
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
        conn.close()


@production_lines_bp.delete("/production-lines/<line_code>")
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
        cur = get_dict_cursor(conn)

        cur.execute(
            "SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(%s)",
            (line_code,),
        )
        row = cur.fetchone()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        # products.bm/fg_production_line_code have no ON DELETE CASCADE, so
        # check up front and give a clear error instead of a raw FK violation.
        cur.execute(
            """
            SELECT inventory_id FROM products
            WHERE bm_production_line_code = %s OR fg_production_line_code = %s
            LIMIT 1
            """,
            (canonical_code, canonical_code),
        )
        if cur.fetchone() is not None:
            return jsonify({
                "error": "Production line is still in use by one or more products and cannot be deleted",
                "line_code": canonical_code,
            }), 409

        # line_activities has ON DELETE CASCADE, so its rows are removed automatically.
        cur.execute(
            "DELETE FROM production_lines WHERE production_line_code = %s",
            (canonical_code,),
        )

        conn.commit()
        return jsonify({
            "message": "Production line deleted",
            "production_line_code": canonical_code,
        })
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


# ── Add / update / delete a single activity on a line ──────────────────────────

@production_lines_bp.post("/production-lines/<line_code>/activities")
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
    if not body or not body.get("activity_name"):
        return jsonify({"error": "activity_name is required"}), 400

    conn = get_connection()
    try:
        cur = get_dict_cursor(conn)

        cur.execute(
            "SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(%s)",
            (line_code,),
        )
        row = cur.fetchone()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        sort_order = body.get("sort_order")
        if sort_order is None:
            cur.execute(
                "SELECT COALESCE(MAX(sort_order), 0) AS max_order FROM line_activities WHERE production_line_code = %s",
                (canonical_code,),
            )
            sort_order = cur.fetchone()["max_order"] + 1

        cur.execute(
            """
            INSERT INTO line_activities (production_line_code, activity_name, sort_order, stage)
            VALUES (%s, %s, %s, %s)
            RETURNING id
            """,
            (canonical_code, body["activity_name"], sort_order, body.get("stage")),
        )
        new_id = cur.fetchone()["id"]

        conn.commit()
        return jsonify({
            "message": "Activity added",
            "production_line_code": canonical_code,
            "activity_id": new_id,
            "sort_order": sort_order,
        }), 201
    except psycopg2.IntegrityError:
        conn.rollback()
        return jsonify({
            "error": "This activity already exists on this production line",
            "line_code": line_code,
        }), 409
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


@production_lines_bp.patch("/production-lines/<line_code>/activities/<int:activity_id>")
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
        cur = get_dict_cursor(conn)

        cur.execute(
            "SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(%s)",
            (line_code,),
        )
        row = cur.fetchone()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        cur.execute(
            "SELECT id FROM line_activities WHERE id = %s AND production_line_code = %s",
            (activity_id, canonical_code),
        )
        if cur.fetchone() is None:
            return jsonify({
                "error": "Activity not found for this production line",
                "activity_id": activity_id,
                "line_code": canonical_code,
            }), 404

        set_clause = ", ".join(f"{col} = %s" for col in updates)
        cur.execute(
            f"UPDATE line_activities SET {set_clause} WHERE id = %s AND production_line_code = %s",
            (*updates.values(), activity_id, canonical_code),
        )

        conn.commit()
        return jsonify({
            "message": "Activity updated",
            "production_line_code": canonical_code,
            "activity_id": activity_id,
            "fields_updated": list(updates.keys()),
        })
    except psycopg2.IntegrityError:
        conn.rollback()
        return jsonify({
            "error": "This activity name already exists on this production line",
            "line_code": line_code,
        }), 409
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        conn.close()


@production_lines_bp.delete("/production-lines/<line_code>/activities/<int:activity_id>")
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
        cur = get_dict_cursor(conn)

        cur.execute(
            "SELECT production_line_code FROM production_lines WHERE UPPER(production_line_code) = UPPER(%s)",
            (line_code,),
        )
        row = cur.fetchone()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        cur.execute(
            "SELECT id FROM line_activities WHERE id = %s AND production_line_code = %s",
            (activity_id, canonical_code),
        )
        if cur.fetchone() is None:
            return jsonify({
                "error": "Activity not found for this production line",
                "activity_id": activity_id,
                "line_code": canonical_code,
            }), 404

        cur.execute(
            "DELETE FROM line_activities WHERE id = %s AND production_line_code = %s",
            (activity_id, canonical_code),
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
        conn.close()