"""
Production lines resource.
"""

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
            SELECT production_line_code, activity_name, sort_order
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