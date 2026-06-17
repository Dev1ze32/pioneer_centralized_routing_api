# ACU Routing API (v1)

A simple Flask + PostgreSQL API for looking up routing/activity data
by item code. No authentication - for local testing with Postman.

## 1. Project files

```
routing_api/
├── schema.sql      -> creates the "products" and "activities" tables
├── db.py           -> shared DB connection helper
├── load_data.py    -> loads acu_routing_parsed.json into the database
├── app.py          -> the Flask API server
├── requirements.txt
├── .env.example    -> copy to .env and fill in your DB credentials
└── acu_routing_parsed.json  -> the data exported by parser.py
```

## 2. Schema design

Two tables, mirroring the JSON 1-to-many structure:

**products** (one row per item code)
| column                | type         |
|-----------------------|--------------|
| inventory_id (PK)     | varchar(50)  |
| revision_descr        | text         |
| revision              | varchar(10)  |
| notes                 | text         |
| production_line       | text         |
| production_line_code  | varchar(20)  |

**activities** (one row per labor activity, FK -> products)
| column          | type        |
|-----------------|-------------|
| id (PK)         | serial      |
| inventory_id    | varchar(50) |
| type            | varchar(20) |
| item_id         | text        |
| qty_required    | double precision |
| activity_name   | text  (this is the JSON "activities" field) |
| class           | varchar(10) |
| class_1         | varchar(10) |
| sort_order      | integer (preserves original order) |

`activities.inventory_id` has `ON DELETE CASCADE`, so re-loading a
product also cleans up its old activity rows.

## 3. Setup

### a) Install dependencies
```bash
pip install -r requirements.txt
```

### b) Configure the database connection
```bash
cp .env.example .env
# edit .env with your real PostgreSQL host/port/db/user/password
```

Make sure the database itself exists, e.g.:
```bash
createdb routing_db
```

### c) Load the data
This creates the schema (dropping/recreating the two tables) and
loads `acu_routing_parsed.json`:
```bash
python load_data.py acu_routing_parsed.json
```

Re-run this any time you re-export a fresh JSON from `parser.py` -
it's safe to run multiple times (upserts products, replaces
activities for each product).

### d) Run the API
```bash
python app.py
```
Server runs at `http://127.0.0.1:5000`.

## 4. Endpoints

> Note: every endpoint here is a `GET` request, so there is no JSON
> **request** body to send - in Postman just set the method to `GET`
> and leave the "Body" tab empty (use the URL / path / query params
> as shown below). The raw JSON shown for each endpoint below is the
> **response** body you'll get back.

### GET /api/health
Quick check that the server is up.

Request: `GET http://127.0.0.1:5000/api/health` (no body)

Response body:
```json
{
  "status": "ok"
}
```

### GET /api/items/<item_code>
**This is the main one.** Case-insensitive lookup by item code -
returns the product info plus all of its activities.

Request: `GET http://127.0.0.1:5000/api/items/1AF2202L` (no body)

Response body:
```json
{
  "inventory_id": "1AF2202L",
  "revision_descr": "PG ANTI FOULING PAINT RED 4L",
  "revision": "03",
  "notes": "CRN RD23-CR055",
  "production_line": "L01 - L1 COATINGS",
  "production_line_code": "L01",
  "activities": [
    {
      "type": "Labor",
      "item_id": "L01 LABELING/CODING",
      "qty_required": 0.124499976967504,
      "activities": "L01 LABELING/CODING",
      "class": "DL",
      "class_1": "DL"
    },
    {
      "type": "Labor",
      "item_id": "L01 FILLING",
      "qty_required": 0.149900091588956,
      "activities": "L01 FILLING",
      "class": "DL",
      "class_1": "DL"
    }
  ]
}
```

Another example with 3 activities - `GET /api/items/1APU5A5I04`:
```json
{
  "inventory_id": "1APU5A5I04",
  "revision_descr": "PIOTHANE PU TOPCOAT RAL 5011 16L",
  "revision": "02",
  "notes": "CRN RD23-CR055",
  "production_line": "L01 - L1 COATINGS",
  "production_line_code": "L01",
  "activities": [
    {
      "type": "Labor",
      "item_id": "L01 LABELING/CODING",
      "qty_required": 0.125,
      "activities": "L01 LABELING/CODING",
      "class": "DL",
      "class_1": "DL"
    },
    {
      "type": "Labor",
      "item_id": "L01 LETDOWN",
      "qty_required": 0.666671111140741,
      "activities": "L01 LETDOWN",
      "class": "DL",
      "class_1": "DL"
    },
    {
      "type": "Labor",
      "item_id": "L01 PACKING/PALLETIZ",
      "qty_required": 0.5,
      "activities": "L01 PACKING/PALLETIZ",
      "class": "DL",
      "class_1": "DL"
    }
  ]
}
```

If the item code doesn't exist - `GET /api/items/doesnotexist` returns
HTTP `404` with body:
```json
{
  "error": "Item code not found",
  "item_code": "doesnotexist"
}
```

### GET /api/items?q=<term>&limit=<n>
Browse / search item codes - partial, case-insensitive match on
`inventory_id` or `revision_descr`. Useful for finding a valid item
code to test with. `limit` defaults to 50.

Request: `GET http://127.0.0.1:5000/api/items?q=anti fouling` (no body)

Response body:
```json
[
  {
    "inventory_id": "1AF2202L",
    "revision_descr": "PG ANTI FOULING PAINT RED 4L",
    "revision": "03",
    "production_line": "L01 - L1 COATINGS",
    "production_line_code": "L01"
  },
  {
    "inventory_id": "1AF29233",
    "revision_descr": "PG ANTI FOULING PAINT RED 1L",
    "revision": "03",
    "production_line": "L01 - L1 COATINGS",
    "production_line_code": "L01"
  },
  {
    "inventory_id": "BM000082",
    "revision_descr": "BULKMIX- PG ANTI FOULING PAINT BLUE A",
    "revision": "01",
    "production_line": "L01 - L1 COATINGS",
    "production_line_code": "L01"
  }
]
```

## 5. Interactive docs (Swagger UI)

Once the server is running, open:

```
http://127.0.0.1:5000/docs/
```

This gives you a Swagger UI where you can see all endpoints, expand
each one, fill in parameters (e.g. `item_code = 1AF2202L`), and hit
"Try it out" to send the request and see the live response - no
Postman needed, though you can still use Postman if you prefer.

The raw OpenAPI spec is also available at `/apispec_1.json`.

## 6. Next steps
Once this is confirmed working, the next step is parsing the BM/FG
routing template and wiring up the lookup so that selecting BM or FG
and entering an item code auto-fills the template from this API.

### GET /api/production-lines
Returns every production line and the activities that can be performed on each line.

Request: `GET http://127.0.0.1:5000/api/production-lines` (no body)

Response body:
```json
[
  {
    "production_line_code": "L01",
    "production_line_name": "L01 - L1 COATINGS",
    "activities": [
      { "activity_name": "L01 MIXING", "sort_order": 1 },
      { "activity_name": "L01 MILLING", "sort_order": 2 },
      { "activity_name": "L01 TINTING", "sort_order": 3 },
      { "activity_name": "L01 LETDOWN", "sort_order": 4 },
      { "activity_name": "L01 FILLING", "sort_order": 5 },
      { "activity_name": "L01 PACKING/PALLETIZ", "sort_order": 6 },
      { "activity_name": "L01 LABELING/CODING", "sort_order": 7 }
    ]
  },
  {
    "production_line_code": "L02",
    "production_line_name": "L02 - L2 COATINGS",
    "activities": [
      { "activity_name": "L02 MIXING", "sort_order": 1 },
      { "activity_name": "L02 MILLING", "sort_order": 2 }
    ]
  }
]