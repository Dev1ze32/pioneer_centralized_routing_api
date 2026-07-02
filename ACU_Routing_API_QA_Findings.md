# ACU Routing API — Crash & Data-Integrity QA Findings

Reviewed: `app.py`, `db.py`, `routes/*`, `routes/utils/*`, `init-db/01-init.sql`, `server.py`, `docker-compose.yml`

Each finding lists: where it lives, what actually goes wrong, why it matters, and a concrete fix.

---

## CRITICAL

### 1. Bulk-save endpoint has no input validation — one bad field kills the whole save
**File:** `routes/update.py` → `bulk_update_item()` (`PUT /api/items/<item_code>/bulk`)

This is your main "Save" path — the audit log shows it firing constantly. It loops over `activities_added` / `activities_updated` / `activities_deleted` and trusts the JSON shape completely:

```python
activity_name = act.get("activity_name", "").strip()
```
If the client ever sends `"activity_name": null` (not missing, just null), `.get()` returns `None` — the default only applies when the key is *absent*. `.strip()` on `None` raises `AttributeError`.

```python
valid_updates["quantity"] = float(valid_updates["quantity"])
```
No `try/except`, and no "must be a whole number" check — unlike the single-item `PATCH /api/items/<item_code>` endpoint, which validates this properly. A stray string or malformed number here throws `ValueError`.

**Why it matters:** any exception here is caught only by the function's outer `except Exception` → returns a generic 500 **and** the whole `managed_connection()` block rolls back — every change in that save (metadata + every added/updated/deleted activity) is discarded, not just the bad one. To the user, "the site crashed" on a save that had 20 valid changes and 1 bad one.

**Fix:** validate the payload shape up front (list of dicts, required keys present and non-null, quantity coercible) and return a clean 400 before touching the DB, same as `create_item()` already does.

---

### 2. No conflict detection on the "quick" edit endpoints — silent lost updates
**File:** `routes/update.py` → `add_activity()`, `update_activity()`, `delete_activity()`, `update_product_metadata()`

Only `bulk_update_item()` checks `expected_revision` against the current DB revision before writing (the correct pattern — see the 409 conflict response it returns). The four single-item endpoints skip that check entirely. They still take a `FOR UPDATE` row lock, so writes are *serialized* — but nothing tells either user their change collided. Two admins editing the same product at once can overwrite each other with no error, no log entry that explains it, nothing.

**Why it matters:** this is exactly the class of bug the bulk endpoint's `expected_revision` mechanism was built to prevent — it's just not applied consistently, so the protection has gaps.

**Fix:** either route all edits through the bulk endpoint, or add the same `expected_revision` check to the single-item endpoints.

---

### 3. Case-sensitive primary keys + check-then-insert race → duplicate "same" items
**Files:** `routes/items.py` → `create_item()`; `routes/production_lines.py` → `create_production_line()`

Both check for an existing row with `UPPER(x) = UPPER(:input)`, but the actual primary key (`products.inventory_id`, `production_lines.production_line_code`) is case-sensitive. Two concurrent requests for `abc123` and `ABC123` can both pass the "doesn't exist" check and both insert successfully as two distinct rows — even though every other endpoint in the app treats item codes as case-insensitive.

**Why it matters:** this produces genuinely dirty data — two "duplicate" products with different casing, inconsistent activities, inconsistent history — that's hard to detect later and will confuse users searching by code.

**Fix:** either normalize the stored value to uppercase on insert, or add a unique index on `UPPER(inventory_id)` / `UPPER(production_line_code)` so the database itself rejects the race, not just the app-level check.

---

## HIGH

### 4. `activities_deleted` isn't type-checked before hitting the DB
**File:** `routes/update.py` → `bulk_update_item()`

```python
for act_id in activities_deleted:
    conn.execute(text("DELETE FROM activities WHERE inventory_id = :canonical_id AND id = :act_id"), ...)
```
No check that `act_id` is actually an integer. A malformed value raises a DB type error, caught by the generic handler — same full-rollback behavior as Finding #1.

### 5. Waitress body size limit vs. the bulk endpoint's payload size
**File:** `server.py`

```python
serve(app_with_static, ..., max_request_body_size=1048576, ...)
```
1MB global cap. The bulk-save endpoint is the one endpoint most likely to produce a large JSON body (many activities in one PUT). If it's ever exceeded, Waitress resets the connection rather than returning a clean JSON error — the frontend sees a raw connection failure, which looks like a crash rather than a validation error.

**Fix:** either raise the cap for this route specifically, or (better) keep payloads small by having the frontend diff and send only changed activities — which it already partially does via `activities_added/updated/deleted`, so check real-world payload sizes against the limit.

### 6. Orphaned DB trigger function — landmine for future changes
**File:** `init-db/01-init.sql`

`sync_production_line_text()` is defined but never attached with `CREATE TRIGGER` to any table (only `trigger_users_updated_at` exists). The app currently compensates by manually updating `products.bm_production_line` / `fg_production_line` text inside `rename_production_line()` — so nothing is broken today. But the function's existence implies it *should* be doing this automatically. If a future change removes the manual sync (assuming the trigger handles it), production-line display text will silently desync from the canonical name.

**Fix:** either delete the unused function, or actually wire it up as a trigger and remove the manual sync code — don't leave both half-implementations in place.

---

## MEDIUM

### 7. `GET /api/auth/users` has no pagination
**File:** `routes/auth.py` → `get_users()`

Returns every user unbounded. Fine today with a handful of accounts; will degrade as the table grows. Every other list endpoint in the app already paginates — this one was missed.

### 8. Every request commits, even pure reads
**File:** `db.py` → `managed_connection()`

`conn.commit()` runs unconditionally after every request, including GETs. Harmless (no-op on a read-only transaction) but adds a small amount of unnecessary round-trip overhead on every single request.

---

## LOW / Cosmetic

### 9. Docstring drift
**File:** `app.py` — top-of-file comment says the production entrypoint is `python waitress_server.py`; the actual file is `server.py`. Documentation only, no functional impact.

### 10. Fragile static-method call pattern
**File:** `config.py`

```python
DB_POOL_SIZE = _safe_int.__func__("DB_POOL_SIZE", "20")
```
Works correctly, but calling `.__func__` on a staticmethod from inside the class body (before the class object fully exists) is an unusual idiom. A future refactor (e.g. moving `_safe_int` out, or a Python version change to how staticmethods behave) could break this in a way that's not obviously connected to the change that caused it.

---

## Suggested priority order
1. Fix #1 and #4 together (input validation on the bulk endpoint) — highest blast radius, easiest to reproduce accidentally from the frontend.
2. Fix #3 (case-sensitive PK race) — add a DB-level unique index; cheap, permanent fix.
3. Fix #2 (conflict detection gap) — decide whether to unify on the bulk endpoint or backport `expected_revision` to the others.
4. Fix #6 (orphaned trigger) — low effort, prevents a future silent-desync bug.
5. Everything else is nice-to-have hardening, not urgent.
