"""
Archive resource — read-only access to historical product snapshots.

Every time a product (or any of its activities) is modified, the complete
state BEFORE that change is written to the `product_revisions` table by the
snapshot helper in archive_utils.py.  These endpoints expose that history.

Endpoints
---------
    GET  /api/items/<item_code>/revisions
        List every archived revision for an item, newest first.
        Returns summary rows (no full snapshot body) for fast browsing.

    GET  /api/items/<item_code>/revisions/<revision>
        Return the full JSONB snapshot for one specific revision, including
        the complete activities list as it existed at that point in time.

Access
------
Restricted to **admin** and **superuser** roles only.  A valid JWT that
belongs to any other role will receive a 403 Forbidden response.

Revisions survive product deletion (no FK constraint), so these endpoints
still work even after a product has been removed from the live `products`
table.
"""

import logging

from flask import Blueprint, jsonify, request
from sqlalchemy import text

from db import managed_connection
from routes.utils.decorators import require_superuser_or_admin

logger = logging.getLogger(__name__)

archive_bp = Blueprint("archive", __name__, url_prefix="/api")


# ── GET /api/items/<item_code>/revisions ──────────────────────────────────────

@archive_bp.get("/items/<path:item_code>/revisions")
@require_superuser_or_admin
def list_revisions(item_code):
    """
    List all archived revisions for an item code.
    ---
    tags:
      - Archive
    security:
      - Bearer: []
    parameters:
      - name: item_code
        in: path
        type: string
        required: true
        description: The inventory ID / item code (case-insensitive)
        example: 1AF2202L
      - name: page
        in: query
        type: integer
        default: 1
        description: Page number (1-based)
      - name: per_page
        in: query
        type: integer
        default: 50
        description: Results per page (max 200)
    responses:
      200:
        description: >
          Paginated list of archived revision summaries, newest first.
          The `snapshot` body is NOT included here — use the detail endpoint
          to retrieve the full snapshot for a specific revision.
        schema:
          type: object
          properties:
            inventory_id:
              type: string
            total:
              type: integer
            page:
              type: integer
            per_page:
              type: integer
            total_pages:
              type: integer
            revisions:
              type: array
              items:
                type: object
                properties:
                  id:
                    type: integer
                  revision:
                    type: string
                  archived_by:
                    type: string
                  archived_at:
                    type: string
      404:
        description: No archived revisions found for this item code
      401:
        description: Missing or invalid token
      403:
        description: Permission denied — admin or superuser role required
    """
    try:
        page     = max(1, request.args.get("page", 1, type=int))
        per_page = min(request.args.get("per_page", 50, type=int), 200)
    except (ValueError, TypeError):
        return jsonify({"error": "page and per_page must be integers"}), 400

    offset = (page - 1) * per_page

    # Normalise the item code to upper-case so the lookup is case-insensitive,
    # matching the same convention used in products and activities.
    canonical_id = item_code.upper()

    with managed_connection() as conn:
        count_row = conn.execute(
            text(
                "SELECT COUNT(*) AS total FROM product_revisions "
                "WHERE UPPER(inventory_id) = :canonical_id"
            ),
            {"canonical_id": canonical_id},
        ).mappings().first()

        total = count_row["total"] if count_row else 0

        if total == 0:
            return jsonify({
                "error":        "No archived revisions found for this item code",
                "inventory_id": canonical_id,
            }), 404

        rows = conn.execute(
            text(
                """
                SELECT
                    id,
                    inventory_id,
                    revision,
                    archived_by,
                    approved_by,
                    TO_CHAR(archived_at AT TIME ZONE 'UTC',
                            'YYYY-MM-DD HH24:MI:SS UTC') AS archived_at
                FROM product_revisions
                WHERE UPPER(inventory_id) = :canonical_id
                ORDER BY archived_at DESC
                LIMIT  :limit
                OFFSET :offset
                """
            ),
            {"canonical_id": canonical_id, "limit": per_page, "offset": offset},
        ).mappings().all()

    return jsonify({
        "inventory_id": canonical_id,
        "total":        total,
        "page":         page,
        "per_page":     per_page,
        "total_pages":  max(1, -(-total // per_page)),
        # BUG-13 NOTE: each row includes its unique `id` field so callers can
        # pass ?snapshot_id=<id> to get_revision() to pin to one specific
        # snapshot when multiple exist for the same revision string.
        "revisions":    [dict(r) for r in rows],
    }), 200


# ── GET /api/items/<item_code>/revisions/<revision> ───────────────────────────

@archive_bp.get("/items/<path:item_code>/revisions/<revision>")
@require_superuser_or_admin
def get_revision(item_code, revision):
    """
    Retrieve the full snapshot of a specific archived revision.
    ---
    tags:
      - Archive
    security:
      - Bearer: []
    parameters:
      - name: item_code
        in: path
        type: string
        required: true
        description: The inventory ID / item code (case-insensitive)
        example: 1AF2202L
      - name: revision
        in: path
        type: string
        required: true
        description: >
          The two-digit zero-padded revision number to retrieve (e.g. "01",
          "02").  This is the revision the product WAS ON before it was
          changed — i.e. the state you are restoring a view of.
        example: "01"
    responses:
      200:
        description: >
          Full snapshot of the product at the requested revision, including
          all activities as they existed at that point in time.
        schema:
          type: object
          properties:
            id:
              type: integer
            inventory_id:
              type: string
            revision:
              type: string
            archived_by:
              type: string
            archived_at:
              type: string
            snapshot:
              type: object
              description: >
                Complete product record and its activities list at the time
                this revision was archived.
      404:
        description: Revision not found for this item code
      401:
        description: Missing or invalid token
      403:
        description: Permission denied — admin or superuser role required
    """
    canonical_id = item_code.upper()

    # BUG-13 FIX: When multiple snapshots share the same revision string
    # (e.g. intermediate snapshots from a bulk-update), ORDER BY archived_at DESC
    # LIMIT 1 silently returns only the most recent one, making older snapshots
    # unreachable. The optional ?snapshot_id=<id> parameter lets callers pin to
    # a specific archive row by its unique primary key.
    snapshot_id = request.args.get("snapshot_id", None, type=int)

    with managed_connection() as conn:
        if snapshot_id is not None:
            # Exact lookup by primary key — unambiguous.
            row = conn.execute(
                text(
                    """
                    SELECT
                        id,
                        inventory_id,
                        revision,
                        snapshot,
                        archived_by,
                        approved_by,
                        TO_CHAR(archived_at AT TIME ZONE 'UTC',
                                'YYYY-MM-DD HH24:MI:SS UTC') AS archived_at
                    FROM product_revisions
                    WHERE UPPER(inventory_id) = :canonical_id
                      AND revision            = :revision
                      AND id                  = :snapshot_id
                    """
                ),
                {"canonical_id": canonical_id, "revision": revision,
                 "snapshot_id": snapshot_id},
            ).mappings().first()
        else:
            # Default: most recent snapshot for this revision (original behaviour).
            row = conn.execute(
                text(
                    """
                    SELECT
                        id,
                        inventory_id,
                        revision,
                        snapshot,
                        archived_by,
                        approved_by,
                        TO_CHAR(archived_at AT TIME ZONE 'UTC',
                                'YYYY-MM-DD HH24:MI:SS UTC') AS archived_at
                    FROM product_revisions
                    WHERE UPPER(inventory_id) = :canonical_id
                      AND revision            = :revision
                    ORDER BY archived_at DESC
                    LIMIT 1
                    """
                ),
                {"canonical_id": canonical_id, "revision": revision},
            ).mappings().first()

        if row is None:
            return jsonify({
                "error":        "Revision not found for this item code",
                "inventory_id": canonical_id,
                "revision":     revision,
            }), 404

        result = dict(row)

    # snapshot is returned from psycopg2 as a dict already (JSONB auto-decode);
    # guard against the rare case where it arrives as a raw string.
    if isinstance(result.get("snapshot"), str):
        import json
        try:
            result["snapshot"] = json.loads(result["snapshot"])
        except Exception:
            pass  # leave as-is — the raw string is still useful

    return jsonify(result), 200