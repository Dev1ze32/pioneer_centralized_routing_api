# ACU Routing API (v0.0.1)

A Flask + PostgreSQL REST API for managing product routing data — item codes, their activity sequences, and the production lines those activities belong to. Documented via Swagger UI (Flasgger).

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Schema Design](#2-schema-design)
3. [Setup](#3-setup)
4. [Running the Server](#4-running-the-server)
5. [Interactive Docs (Swagger UI)](#5-interactive-docs-swagger-ui)
6. [API Reference](#6-api-reference)
   - [Health](#health)
   - [Items](#items)
   - [Production Lines](#production-lines)
7. [Error Responses](#7-error-responses)

---

## 1. Project Structure

```
routing_api/
├── app.py                      # Flask app factory + entry point
├── config.py                   # Env-based configuration (DB credentials)
├── db.py                       # SQLAlchemy connection pool helper
├── schema.sql                  # Creates products, activities, production_lines, line_activities tables
├── load_data.py                # Loads acu_routing_parsed.json into the database
├── requirements.txt            # Python dependencies
├── .env.example                # Copy to .env and fill in DB credentials
├── acu_routing_parsed.json     # Source data exported by parser.py
└── routes/
    ├── __init__.py             # Blueprint registration
    ├── health.py               # GET /api/health
    ├── items.py                # CRUD for /api/items
    ├── production_lines.py     # CRUD for /api/production-lines
    └── update.py               # PATCH/DELETE for items and their activities
```

---

## 2. Schema Design

Four tables with a clear hierarchy:

**products** — one row per item code
| Column | Type |
|---|---|
| inventory_id (PK) | varchar(50) |
| revision_descr | text |
| revision | varchar(10) |
| notes | text |
| product_type | text |
| quantity | double precision |
| bm_production_line | text |
| bm_production_line_code | varchar(20) |
| fg_production_line | text |
| fg_production_line_code | varchar(20) |

**activities** — one row per labor activity, FK → products
| Column | Type |
|---|---|
| id (PK) | serial |
| inventory_id | varchar(50) |
| type | varchar(20) |
| item_id | text |
| activity_name | text |
| class / class_1 | varchar(10) |
| pax | integer |
| machine | integer |
| time_min | double precision |
| sort_order | integer |

**production_lines** — one row per line
| Column | Type |
|---|---|
| production_line_code (PK) | varchar(20) |
| production_line_name | text |

**line_activities** — one row per activity template on a line, FK → production_lines
| Column | Type |
|---|---|
| id (PK) | serial |
| production_line_code | varchar(20) |
| activity_name | text |
| sort_order | integer |
| stage | text |

`activities.inventory_id` has `ON DELETE CASCADE` — deleting a product also removes all its activities. `line_activities.production_line_code` has `ON DELETE CASCADE` as well.

---

## 3. Setup

### a) Install dependencies

```bash
pip install -r requirements.txt
```

### b) Configure the database connection

```bash
cp .env.example .env
# Edit .env with your PostgreSQL credentials
```

`.env.example` values:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=routing_db
DB_USER=postgres
DB_PASSWORD=postgres
```

Make sure the database exists:
```bash
createdb routing_db
```

### c) Load the data

Creates the schema (drops and recreates all tables) and loads `acu_routing_parsed.json`. Safe to re-run — it upserts products and replaces activities for each product.

```bash
python load_data.py acu_routing_parsed.json
```

---

## 4. Running the Server

```bash
python app.py
```

Server starts at `http://127.0.0.1:5000` with hot-reload enabled (`debug=True`).

---

## 5. Interactive Docs (Swagger UI)

Once the server is running, open:

```
http://127.0.0.1:5000/docs/
```

Use the Swagger UI to explore every endpoint, fill in parameters, and fire live requests directly from the browser. The raw OpenAPI spec is at `/apispec_1.json`.

---

## 6. API Reference

All endpoints are under the `/api` prefix. Request/response bodies are JSON. Path parameters are **case-insensitive** unless noted.

---

### Health

#### `GET /api/health`

Quick liveness check.

**Request:** no body, no parameters.

**Response `200`:**
```json
{ "status": "ok" }
```

---

### Items

#### `GET /api/items`

Browse or search item codes. Returns a summary list (no activities).

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `q` | string | No | — | Partial, case-insensitive match on `inventory_id` or `revision_descr` |
| `limit` | integer | No | 50 | Max results returned (capped at 1000) |

**Example:** `GET /api/items?q=anti fouling&limit=10`

**Response `200`:**
```json
[
  {
    "inventory_id": "1AF2202L",
    "revision_descr": "PG ANTI FOULING PAINT RED 4L",
    "revision": "03",
    "product_type": "Finished Good (FG)",
    "quantity": 4,
    "bm_production_line": null,
    "bm_production_line_code": null,
    "fg_production_line": "L01 - L1 COATINGS",
    "fg_production_line_code": "L01"
  }
]
```

---

#### `POST /api/items`

Create a new product with optional activities.

**Request Body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `inventory_id` | string | **Yes** | Unique item code |
| `revision_descr` | string | **Yes** | Product description |
| `product_type` | string | **Yes** | `"Finished Good (FG)"` or `"Base Material (BM)"` |
| `quantity` | number | No | Defaults to `1` |
| `fg_production_line` | string | No | Full name of the FG production line |
| `fg_production_line_code` | string | No | Code of the FG production line (e.g. `L01`) |
| `bm_production_line` | string | No | Full name of the BM production line |
| `bm_production_line_code` | string | No | Code of the BM production line |
| `notes` | string | No | Free-text notes |
| `activities` | array | No | List of activity objects (see below) |

Each object in `activities`:

| Field | Type | Required | Default |
|---|---|---|---|
| `activity_name` | string | **Yes** | — |
| `type` | string | No | `"Labor"` |
| `item_id` | string | No | Same as `activity_name` |
| `class` | string | No | `"DL"` |
| `class_1` | string | No | `"DL"` |
| `pax` | integer | No | `0` |
| `machine` | integer | No | `0` |
| `time_min` | number | No | `0` |
| `sort_order` | integer | No | Auto-assigned |

**Example Request Body:**
```json
{
  "inventory_id": "TESTITEM01",
  "revision_descr": "Test Product",
  "product_type": "Finished Good (FG)",
  "quantity": 10,
  "fg_production_line": "L01 - L1 COATINGS",
  "fg_production_line_code": "L01",
  "activities": [
    { "activity_name": "L01 FILLING", "pax": 2, "machine": 0, "time_min": 0.15 }
  ]
}
```

**Response `201`:**
```json
{
  "message": "Product created",
  "inventory_id": "TESTITEM01",
  "revision": "00"
}
```

**Error responses:** `400` missing fields, `409` item code already exists.

---

#### `GET /api/items/{item_code}`

Look up full routing details for a single item, including all activities.

**Path Parameter:** `item_code` — the inventory ID (case-insensitive).

**Example:** `GET /api/items/1AF2202L`

**Response `200`:**
```json
{
  "inventory_id": "1AF2202L",
  "revision_descr": "PG ANTI FOULING PAINT RED 4L",
  "revision": "03",
  "notes": "CRN RD23-CR055",
  "product_type": "Finished Good (FG)",
  "quantity": 4,
  "bm_production_line": null,
  "bm_production_line_code": null,
  "fg_production_line": "L01 - L1 COATINGS",
  "fg_production_line_code": "L01",
  "activities": [
    {
      "id": 1,
      "type": "Labor",
      "item_id": "L01 LABELING/CODING",
      "activities": "L01 LABELING/CODING",
      "class": "DL",
      "class_1": "DL",
      "pax": 1,
      "machine": 0,
      "time_min": 0.1245
    }
  ]
}
```

**Response `404`:**
```json
{ "error": "Item code not found", "item_code": "doesnotexist" }
```

---

#### `PATCH /api/items/{item_code}`

Update product metadata. **Revision is auto-incremented on every save.**

**Path Parameter:** `item_code`

**Request Body** — send only the fields you want to change:

| Field | Type |
|---|---|
| `revision_descr` | string |
| `notes` | string |
| `quantity` | number |
| `product_type` | string |
| `fg_production_line` | string |
| `fg_production_line_code` | string |
| `bm_production_line` | string |
| `bm_production_line_code` | string |

**Example:**
```json
{ "notes": "Updated note", "quantity": 20 }
```

**Response `200`:**
```json
{
  "message": "Product metadata updated",
  "inventory_id": "1AF2202L",
  "old_revision": "03",
  "new_revision": "04",
  "fields_updated": ["notes", "quantity"]
}
```

---

#### `DELETE /api/items/{item_code}`

Permanently delete a product and **all** of its activities (cascades at DB level).

**Path Parameter:** `item_code`

**Response `200`:**
```json
{ "message": "Product deleted", "inventory_id": "1AF2202L" }
```

---

#### `POST /api/items/{item_code}/activities`

Add one new activity to an existing product. **Revision is auto-incremented.**

**Path Parameter:** `item_code`

**Query Parameter (optional):** `skip_revision=1` — add the activity without bumping the revision (useful for bulk loading).

**Request Body:**

| Field | Type | Required | Default |
|---|---|---|---|
| `activity_name` | string | **Yes** | — |
| `pax` | integer | **Yes** | — |
| `machine` | integer | **Yes** | — |
| `time_min` | number | **Yes** | — |
| `type` | string | No | `"Labor"` |
| `item_id` | string | No | Same as `activity_name` |
| `class` | string | No | `"DL"` |
| `class_1` | string | No | `"DL"` |

**Example:**
```json
{
  "activity_name": "L01 PACKING/PALLETIZ",
  "pax": 2,
  "machine": 0,
  "time_min": 0.5
}
```

**Response `201`:**
```json
{
  "message": "Activity added",
  "inventory_id": "1AF2202L",
  "activity_id": 42,
  "sort_order": 3,
  "old_revision": "04",
  "new_revision": "05"
}
```

---

#### `PATCH /api/items/{item_code}/activities/{activity_id}`

Update one specific activity by its database ID. **Revision is auto-incremented.**

**Path Parameters:** `item_code`, `activity_id` (integer)

**Query Parameter (optional):** `skip_revision=1`

**Request Body** — send only the fields you want to change:

| Field | Type |
|---|---|
| `activity_name` | string |
| `type` | string |
| `item_id` | string |
| `class` | string |
| `class_1` | string |
| `pax` | integer |
| `machine` | integer |
| `time_min` | number |
| `sort_order` | integer |

**Response `200`:**
```json
{
  "message": "Activity updated",
  "inventory_id": "1AF2202L",
  "activity_id": 42,
  "fields_updated": ["pax", "time_min"],
  "old_revision": "05",
  "new_revision": "06"
}
```

---

#### `DELETE /api/items/{item_code}/activities/{activity_id}`

Remove one activity from a product. **Revision is auto-incremented.**

**Path Parameters:** `item_code`, `activity_id` (integer)

**Query Parameter (optional):** `skip_revision=1`

**Response `200`:**
```json
{
  "message": "Activity deleted",
  "inventory_id": "1AF2202L",
  "activity_id": 42,
  "old_revision": "06",
  "new_revision": "07"
}
```

---

### Production Lines

#### `GET /api/production-lines`

List all production lines and their activity templates.

**Response `200`:**
```json
[
  {
    "production_line_code": "L01",
    "production_line_name": "L01 - L1 COATINGS",
    "activities": [
      { "id": 1, "activity_name": "L01 MIXING", "sort_order": 1 },
      { "id": 2, "activity_name": "L01 FILLING", "sort_order": 2 }
    ]
  }
]
```

---

#### `POST /api/production-lines`

Create a new production line.

**Request Body:**

| Field | Type | Required |
|---|---|---|
| `production_line_code` | string | **Yes** |
| `production_line_name` | string | **Yes** |

**Example:**
```json
{ "production_line_code": "L20", "production_line_name": "L20 - New Filling Line" }
```

**Response `201`:**
```json
{
  "message": "Production line created",
  "production_line_code": "L20",
  "production_line_name": "L20 - New Filling Line"
}
```

**Error responses:** `400` missing fields, `409` code already exists.

---

#### `GET /api/production-lines/{line_code}`

Get a single production line and its activities.

**Path Parameter:** `line_code` (case-insensitive)

**Response `200`:**
```json
{
  "production_line_code": "L01",
  "production_line_name": "L01 - L1 COATINGS",
  "activities": [
    { "id": 1, "activity_name": "L01 MIXING", "sort_order": 1 }
  ]
}
```

**Response `404`:**
```json
{ "error": "Production line not found", "line_code": "L99" }
```

---

#### `PATCH /api/production-lines/{line_code}`

Rename a production line (name only — does not affect activities).

**Path Parameter:** `line_code`

**Request Body:**
```json
{ "production_line_name": "L01 - L1 COATINGS (UPDATED)" }
```

**Response `200`:**
```json
{
  "message": "Production line renamed",
  "production_line_code": "L01",
  "production_line_name": "L01 - L1 COATINGS (UPDATED)"
}
```

---

#### `PUT /api/production-lines/{line_code}`

Atomically replace a production line's name and its full activity list. All existing activities are deleted and replaced with the ones you send.

**Path Parameter:** `line_code`

**Request Body:**

| Field | Type | Required |
|---|---|---|
| `production_line_name` | string | No |
| `activities` | array | No |

Each activity in the array:

| Field | Type | Required |
|---|---|---|
| `activity_name` | string | **Yes** |
| `sort_order` | integer | **Yes** |
| `stage` | string | No |

**Example:**
```json
{
  "production_line_name": "L01 - L1 COATINGS",
  "activities": [
    { "activity_name": "L01 MIXING", "sort_order": 1 },
    { "activity_name": "L01 FILLING", "sort_order": 2 },
    { "activity_name": "L01 LABELING/CODING", "sort_order": 3 }
  ]
}
```

**Response `200`:**
```json
{
  "message": "Production line updated",
  "line_code": "L01",
  "activities": 3
}
```

---

#### `DELETE /api/production-lines/{line_code}`

Delete a production line and all of its activity templates. Will return `409` if any product still references this line.

**Path Parameter:** `line_code`

**Response `200`:**
```json
{ "message": "Production line deleted", "production_line_code": "L01" }
```

**Response `409`:**
```json
{
  "error": "Production line is still in use by one or more products and cannot be deleted",
  "line_code": "L01"
}
```

---

#### `POST /api/production-lines/{line_code}/activities`

Add a single activity to a production line.

**Path Parameter:** `line_code`

**Request Body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `activity_name` | string | **Yes** | Must be non-empty |
| `sort_order` | integer | No | Defaults to the next available position |
| `stage` | string | No | Optional stage label |

**Example:**
```json
{ "activity_name": "L01 TINTING", "sort_order": 3 }
```

**Response `201`:**
```json
{
  "message": "Activity added",
  "production_line_code": "L01",
  "activity_id": 15,
  "sort_order": 3
}
```

---

#### `PATCH /api/production-lines/{line_code}/activities/{activity_id}`

Update a single activity on a production line.

**Path Parameters:** `line_code`, `activity_id` (integer)

**Request Body** — send only the fields you want to change:

| Field | Type |
|---|---|
| `activity_name` | string |
| `sort_order` | integer |
| `stage` | string |

**Response `200`:**
```json
{
  "message": "Activity updated",
  "production_line_code": "L01",
  "activity_id": 15,
  "fields_updated": ["sort_order"]
}
```

---

#### `DELETE /api/production-lines/{line_code}/activities/{activity_id}`

Delete a single activity from a production line.

**Path Parameters:** `line_code`, `activity_id` (integer)

**Response `200`:**
```json
{
  "message": "Activity deleted",
  "production_line_code": "L01",
  "activity_id": 15
}
```

---

## 7. Error Responses

All errors return JSON with at minimum an `"error"` key.

| HTTP Status | Meaning |
|---|---|
| `400` | Bad request — missing required fields, invalid JSON, or empty value where one is required |
| `404` | Resource not found — item code or production line does not exist |
| `409` | Conflict — duplicate code/name, or attempting to delete a record still referenced by others |
| `500` | Internal server error — check server logs |

**Example `400`:**
```json
{ "error": "inventory_id, revision_descr, and product_type are required" }
```

**Example `409`:**
```json
{ "error": "Item code already exists", "inventory_id": "1AF2202L" }
```