"""
Archive snapshot utility.

Called inside every mutating endpoint in update.py BEFORE committing the
change, so the snapshot is part of the same DB transaction.  If the update
rolls back, the snapshot rolls back too — no orphaned archive rows.

Usage (inside an open connection block in update.py)
-----------------------------------------------------
    from routes.utils.archive_utils import snapshot_product

    # conn must be the same connection already used for the update,
    # and it must NOT have been committed yet.
    snapshot_product(conn, canonical_id, old_revision, archived_by=actor_name)

    conn.commit()   # commits both the update AND the snapshot atomically

Public API
----------
    snapshot_product(conn, inventory_id, revision, archived_by=None)
        Reads the current product row + all activities, then inserts one row
        into product_revisions.  Raises on DB error (caller's transaction
        will roll back automatically).
"""
from __future__ import annotations
import json
import logging

from sqlalchemy import text
from sqlalchemy.engine import Connection

logger = logging.getLogger(__name__)


def snapshot_product(
    conn: Connection,
    inventory_id: str,
    revision: str,
    archived_by: str | None = None,
) -> None:
    """
    Write a full snapshot of *inventory_id* at *revision* into product_revisions.

    Parameters
    ----------
    conn         : An open, uncommitted SQLAlchemy Core connection.
    inventory_id : Canonical (exact-case) inventory ID from the products row.
    revision     : The revision string currently on the product (before bump).
    archived_by  : Username of the actor triggering the change (stored for
                   audit purposes; may be None if called outside a request
                   context).

    Raises
    ------
    Any SQLAlchemy exception propagates to the caller so the enclosing
    transaction is rolled back — never silently swallowed here.
    """

    # ── 1. Read the product row ───────────────────────────────────────────────
    product_row = conn.execute(
        text(
            """
            SELECT
                inventory_id, revision_descr, revision, notes, product_type,
                quantity,
                bm_production_line, bm_production_line_code,
                fg_production_line, fg_production_line_code
            FROM products
            WHERE inventory_id = :inventory_id
            """
        ),
        {"inventory_id": inventory_id},
    ).mappings().first()

    if product_row is None:
        # Shouldn't happen — caller already verified existence — but guard anyway.
        logger.warning(
            "snapshot_product: product '%s' not found; skipping snapshot.",
            inventory_id,
        )
        return

    # ── 2. Read all current activities ────────────────────────────────────────
    activity_rows = conn.execute(
        text(
            """
            SELECT
                id, type, item_id, activity_name AS activities,
                class, class_1, pax, machine, time_min, sort_order
            FROM activities
            WHERE inventory_id = :inventory_id
            ORDER BY sort_order
            """
        ),
        {"inventory_id": inventory_id},
    ).mappings().all()

    # ── 3. Build the snapshot payload ─────────────────────────────────────────
    snapshot = {
        **dict(product_row),
        "activities": [dict(a) for a in activity_rows],
    }

    # ── 4. Insert into product_revisions ──────────────────────────────────────
    conn.execute(
        text(
            """
            INSERT INTO product_revisions
                (inventory_id, revision, snapshot, archived_by)
            VALUES
                (:inventory_id, :revision, :snapshot, :archived_by)
            """
        ),
        {
            "inventory_id": inventory_id,
            "revision":     revision,
            "snapshot":     json.dumps(snapshot),
            "archived_by":  archived_by,
        },
    )

    # ── 5. Cleanup old revisions (keep last 50) ───────────────────────────────
    conn.execute(
        text(
            """
            DELETE FROM product_revisions
            WHERE inventory_id = :inventory_id
              AND id NOT IN (
                  SELECT id FROM product_revisions
                  WHERE inventory_id = :inventory_id
                  ORDER BY archived_at DESC
                  LIMIT 50
              )
            """
        ),
        {"inventory_id": inventory_id},
    )

    logger.debug(
        "Archived snapshot for '%s' rev %s (by %s) and cleaned old revisions.",
        inventory_id, revision, archived_by or "unknown",
    )