from flask import Blueprint, jsonify, request, g
from sqlalchemy import text, bindparam
from sqlalchemy.exc import IntegrityError

from db import get_connection, release_connection, managed_connection
from routes.utils.decorators import require_superuser_or_admin
from routes.utils.log_utils import log_action

production_lines_bp = Blueprint("production_lines", __name__, url_prefix="/api")

_FK_VIOLATION = "23503"


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
    limit  = min(request.args.get("limit",  50, type=int), 200)
    offset = max(request.args.get("offset",  0, type=int), 0)

    with managed_connection() as conn:
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

        if not lines:
            return jsonify([])

        line_codes = [line["production_line_code"] for line in lines]

        result = conn.execute(
            text(
                """
                SELECT id, production_line_code, activity_name, sort_order
                FROM line_activities
                WHERE production_line_code IN :line_codes
                ORDER BY production_line_code, sort_order
                """
            ).bindparams(bindparam("line_codes", expanding=True)),
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
            line_map[code]["activities"].append({
                "id":            act["id"],
                "activity_name": act["activity_name"],
                "sort_order":    act["sort_order"],
            })

    return jsonify(list(line_map.values()))


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
    with managed_connection() as conn:
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
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

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

    new_name   = body.get("production_line_name")
    activities = body.get("activities", [])

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
            text(
                "SELECT production_line_code, production_line_name FROM production_lines "
                "WHERE UPPER(production_line_code) = UPPER(:line_code)"
            ),
            {"line_code": line_code},
        )
        existing = result.mappings().first()
        if existing is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = existing["production_line_code"]
        old_name       = existing["production_line_name"]

        if new_name:
            conn.execute(
                text(
                    "UPDATE production_lines SET production_line_name = :new_name "
                    "WHERE production_line_code = :canonical_code"
                ),
                {"new_name": new_name, "canonical_code": canonical_code},
            )

        conn.execute(
            text("DELETE FROM line_activities WHERE production_line_code = :canonical_code"),
            {"canonical_code": canonical_code},
        )
        for act in activities:
            conn.execute(
                text(
                    """
                    INSERT INTO line_activities
                        (production_line_code, activity_name, sort_order, stage)
                    VALUES (:canonical_code, :activity_name, :sort_order, :stage)
                    """
                ),
                {
                    "canonical_code": canonical_code,
                    "activity_name":  act["activity_name"].strip(),
                    "sort_order":     act["sort_order"],
                    "stage":          act.get("stage"),
                },
            )

        conn.commit()

        actor = getattr(g, "current_user", None)
        actor_name = actor.username if actor else "unknown"
        log_action(
            action="Replaced production line activities",
            description=(
                f"'{actor_name}' replaced all activities on line '{canonical_code}' "
                f"({new_name or old_name}). "
                f"New activity count: {len(activities)}."
            ),
            target_type="production_line",
            target_id=canonical_code,
            extra={
                "name_changed":    new_name is not None and new_name != old_name,
                "new_name":        new_name or old_name,
                "activities_set":  len(activities),
            },
        )

        return jsonify({
            "message":    "Production line updated",
            "line_code":  canonical_code,
            "activities": len(activities),
        })
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


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
            text(
                "SELECT production_line_code FROM production_lines "
                "WHERE UPPER(production_line_code) = UPPER(:line_code)"
            ),
            {"line_code": line_code},
        )
        if result.mappings().first() is not None:
            return jsonify({
                "error":     "Production line code already exists",
                "line_code": line_code,
            }), 409

        conn.execute(
            text(
                "INSERT INTO production_lines (production_line_code, production_line_name) "
                "VALUES (:line_code, :line_name)"
            ),
            {"line_code": line_code, "line_name": line_name},
        )

        conn.commit()

        actor = getattr(g, "current_user", None)
        actor_name = actor.username if actor else "unknown"
        log_action(
            action="Created production line",
            description=(
                f"'{actor_name}' created production line '{line_code}' ({line_name})."
            ),
            target_type="production_line",
            target_id=line_code,
            extra={"production_line_name": line_name},
        )

        return jsonify({
            "message":               "Production line created",
            "production_line_code":  line_code,
            "production_line_name":  line_name,
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
            text(
                "SELECT production_line_code, production_line_name FROM production_lines "
                "WHERE UPPER(production_line_code) = UPPER(:line_code)"
            ),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]
        old_name       = row["production_line_name"]

        conn.execute(
            text(
                "UPDATE production_lines SET production_line_name = :new_name "
                "WHERE production_line_code = :canonical_code"
            ),
            {"new_name": new_name, "canonical_code": canonical_code},
        )
        # Cascade new name to all products that reference this line
        conn.execute(
            text(
                "UPDATE products SET fg_production_line = :new_name "
                "WHERE fg_production_line_code = :canonical_code"
            ),
            {"new_name": new_name, "canonical_code": canonical_code},
        )
        conn.execute(
            text(
                "UPDATE products SET bm_production_line = :new_name "
                "WHERE bm_production_line_code = :canonical_code"
            ),
            {"new_name": new_name, "canonical_code": canonical_code},
        )

        conn.commit()

        actor = getattr(g, "current_user", None)
        actor_name = actor.username if actor else "unknown"
        log_action(
            action="Renamed production line",
            description=(
                f"'{actor_name}' renamed production line '{canonical_code}' "
                f"from '{old_name}' to '{new_name}'."
            ),
            target_type="production_line",
            target_id=canonical_code,
            extra={"old_name": old_name, "new_name": new_name},
        )

        return jsonify({
            "message":               "Production line renamed",
            "production_line_code":  canonical_code,
            "production_line_name":  new_name,
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
    Delete a production line and all of its activities
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
            text(
                "SELECT production_line_code, production_line_name FROM production_lines "
                "WHERE UPPER(production_line_code) = UPPER(:line_code)"
            ),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]
        line_name      = row["production_line_name"]

        result = conn.execute(
            text(
                """
                SELECT inventory_id FROM products
                WHERE bm_production_line_code = :canonical_code
                   OR fg_production_line_code  = :canonical_code
                   OR bm_production_line ILIKE :code_prefix
                   OR fg_production_line ILIKE :code_prefix
                LIMIT 1
                """
            ),
            {"canonical_code": canonical_code, "code_prefix": f"{canonical_code} - %"},
        )
        if result.mappings().first() is not None:
            return jsonify({
                "error":     "Production line is still in use by one or more products and cannot be deleted",
                "line_code": canonical_code,
            }), 409

        conn.execute(
            text("DELETE FROM production_lines WHERE production_line_code = :canonical_code"),
            {"canonical_code": canonical_code},
        )

        conn.commit()

        actor = getattr(g, "current_user", None)
        actor_name = actor.username if actor else "unknown"
        log_action(
            action="Deleted production line",
            description=(
                f"'{actor_name}' deleted production line '{canonical_code}' ({line_name})."
            ),
            target_type="production_line",
            target_id=canonical_code,
            extra={"production_line_name": line_name},
        )

        return jsonify({
            "message":               "Production line deleted",
            "production_line_code":  canonical_code,
        })

    except IntegrityError as e:
        conn.rollback()
        pgcode = getattr(getattr(e, "orig", None), "pgcode", None)
        if pgcode == _FK_VIOLATION:
            return jsonify({
                "error":     "Production line is still referenced by another record and cannot be deleted",
                "line_code": line_code,
            }), 409
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)


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
        result = conn.execute(
            text(
                "SELECT production_line_code FROM production_lines "
                "WHERE UPPER(production_line_code) = UPPER(:line_code) FOR UPDATE"
            ),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]
        sort_order     = body.get("sort_order")
        activity_name  = body["activity_name"].strip()

        if sort_order is None:
            result = conn.execute(
                text(
                    """
                    INSERT INTO line_activities (production_line_code, activity_name, sort_order, stage)
                    VALUES (
                        :canonical_code, :activity_name,
                        (SELECT COALESCE(MAX(sort_order), 0) + 1
                         FROM line_activities WHERE production_line_code = :canonical_code),
                        :stage
                    )
                    RETURNING id, sort_order
                    """
                ),
                {
                    "canonical_code": canonical_code,
                    "activity_name":  activity_name,
                    "stage":          body.get("stage"),
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
                    "activity_name":  activity_name,
                    "sort_order":     sort_order,
                    "stage":          body.get("stage"),
                },
            )

        result_row       = result.mappings().first()
        new_id           = result_row["id"]
        final_sort_order = result_row["sort_order"]

        conn.commit()

        actor = getattr(g, "current_user", None)
        actor_name = actor.username if actor else "unknown"
        log_action(
            action="Added line activity",
            description=(
                f"'{actor_name}' added activity '{activity_name}' (ID {new_id}) "
                f"to production line '{canonical_code}' at sort_order {final_sort_order}."
            ),
            target_type="production_line",
            target_id=canonical_code,
            extra={
                "activity_id":   new_id,
                "activity_name": activity_name,
                "sort_order":    final_sort_order,
            },
        )

        return jsonify({
            "message":               "Activity added",
            "production_line_code":  canonical_code,
            "activity_id":           new_id,
            "sort_order":            final_sort_order,
        }), 201
    except IntegrityError:
        conn.rollback()
        return jsonify({
            "error":     "This activity already exists on this production line",
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
            text(
                "SELECT production_line_code FROM production_lines "
                "WHERE UPPER(production_line_code) = UPPER(:line_code)"
            ),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        result = conn.execute(
            text(
                "SELECT id FROM line_activities "
                "WHERE id = :activity_id AND production_line_code = :canonical_code"
            ),
            {"activity_id": activity_id, "canonical_code": canonical_code},
        )
        if result.mappings().first() is None:
            return jsonify({
                "error":       "Activity not found for this production line",
                "activity_id": activity_id,
                "line_code":   canonical_code,
            }), 404

        set_clause = ", ".join(f"{col} = :{col}" for col in updates)
        params = {**updates, "activity_id": activity_id, "canonical_code": canonical_code}
        conn.execute(
            text(
                f"UPDATE line_activities SET {set_clause} "
                f"WHERE id = :activity_id AND production_line_code = :canonical_code"
            ),
            params,
        )

        conn.commit()

        actor = getattr(g, "current_user", None)
        actor_name = actor.username if actor else "unknown"
        changed_fields = ", ".join(sorted(updates.keys()))
        log_action(
            action="Updated line activity",
            description=(
                f"'{actor_name}' updated activity ID {activity_id} "
                f"on production line '{canonical_code}'. "
                f"Fields changed: {changed_fields}."
            ),
            target_type="production_line",
            target_id=canonical_code,
            extra={"activity_id": activity_id, "fields_updated": list(updates.keys())},
        )

        return jsonify({
            "message":               "Activity updated",
            "production_line_code":  canonical_code,
            "activity_id":           activity_id,
            "fields_updated":        list(updates.keys()),
        })
    except IntegrityError:
        conn.rollback()
        return jsonify({
            "error":     "This activity name already exists on this production line",
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
            text(
                "SELECT production_line_code FROM production_lines "
                "WHERE UPPER(production_line_code) = UPPER(:line_code)"
            ),
            {"line_code": line_code},
        )
        row = result.mappings().first()
        if row is None:
            return jsonify({"error": "Production line not found", "line_code": line_code}), 404

        canonical_code = row["production_line_code"]

        act_row = conn.execute(
            text(
                "SELECT id, activity_name FROM line_activities "
                "WHERE id = :activity_id AND production_line_code = :canonical_code"
            ),
            {"activity_id": activity_id, "canonical_code": canonical_code},
        ).mappings().first()

        if act_row is None:
            return jsonify({
                "error":       "Activity not found for this production line",
                "activity_id": activity_id,
                "line_code":   canonical_code,
            }), 404

        activity_name = act_row["activity_name"]

        conn.execute(
            text(
                "DELETE FROM line_activities "
                "WHERE id = :activity_id AND production_line_code = :canonical_code"
            ),
            {"activity_id": activity_id, "canonical_code": canonical_code},
        )

        conn.commit()

        actor = getattr(g, "current_user", None)
        actor_name = actor.username if actor else "unknown"
        log_action(
            action="Deleted line activity",
            description=(
                f"'{actor_name}' deleted activity '{activity_name}' (ID {activity_id}) "
                f"from production line '{canonical_code}'."
            ),
            target_type="production_line",
            target_id=canonical_code,
            extra={"activity_id": activity_id, "activity_name": activity_name},
        )

        return jsonify({
            "message":               "Activity deleted",
            "production_line_code":  canonical_code,
            "activity_id":           activity_id,
        })
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_connection(conn)