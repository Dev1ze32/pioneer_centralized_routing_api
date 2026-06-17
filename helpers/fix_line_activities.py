"""
fix_line_activities.py
----------------------
Aligns line_activities with the production_lines table by normalizing
'Line01' -> 'L01', adds missing SIPS line, and re-inserts activities.
"""

import json
import psycopg2
from typing import Optional  # <-- ADD THIS

# --- DB config (same as load_data.py) ---
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "routing_db"
DB_USER = "postgres"
DB_PASS = "Anciso-320910"

# --- The JSON you pasted (trimmed to the 'good' entries with activities) ---
RAW_JSON = r"""
[
  {"production_line_code":"Line01","production_line_name":"Line 01 COATINGS","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"MILLING","sort_order":2},{"activity_name":"LETDOWN","sort_order":3},{"activity_name":"TINTING","sort_order":4},{"activity_name":"CODING","sort_order":5},{"activity_name":"LABELING","sort_order":6},{"activity_name":"BOX PREPARATION","sort_order":7},{"activity_name":"MANUAL TRANSFER BM TO FILLING TANK","sort_order":8},{"activity_name":"FILLING","sort_order":9},{"activity_name":"CAPPING","sort_order":10},{"activity_name":"PACKING/PALLETIZING","sort_order":11}]},
  {"production_line_code":"Line02","production_line_name":"Line 02 CYANO BOTTLE FILLING","activities":[{"activity_name":"STICKERING","sort_order":1},{"activity_name":"CODING","sort_order":2},{"activity_name":"FILLING","sort_order":3},{"activity_name":"NOZZLE & CAPPING","sort_order":4},{"activity_name":"CAP TIGHTENING","sort_order":5},{"activity_name":"PLUNGERING","sort_order":6},{"activity_name":"TWIST TIE","sort_order":7},{"activity_name":"PACKING/PALLETIZING","sort_order":8}]},
  {"production_line_code":"Line03","production_line_name":"Line 03 CYANO TUBE FILLING","activities":[{"activity_name":"FILLING","sort_order":1},{"activity_name":"PACKING/PALLETIZING","sort_order":2},{"activity_name":"TRANSFER TO SUBCON","sort_order":3}]},
  {"production_line_code":"Line04A","production_line_name":"Line 04A ELASTO MIXING","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"CODING","sort_order":2},{"activity_name":"BOX PREPARATION","sort_order":3},{"activity_name":"TRANSFER BM TO ARO PUMP","sort_order":4},{"activity_name":"SCOOPING","sort_order":5},{"activity_name":"FILLING","sort_order":6},{"activity_name":"PLUNGERING","sort_order":7},{"activity_name":"SEALING","sort_order":8},{"activity_name":"CAPPING","sort_order":9},{"activity_name":"PACKING/PALLETIZING","sort_order":10}]},
  {"production_line_code":"Line04B","production_line_name":"Line 04B SEMI AUTO FILLING","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"CODING","sort_order":2},{"activity_name":"BOX PREPARATION","sort_order":3},{"activity_name":"TRANSFER BM TO ARO PUMP","sort_order":4},{"activity_name":"SCOOPING","sort_order":5},{"activity_name":"FILLING","sort_order":6},{"activity_name":"PLUNGERING","sort_order":7},{"activity_name":"SEALING","sort_order":8},{"activity_name":"CAPPING","sort_order":9},{"activity_name":"PACKING/PALLETIZING","sort_order":10}]},
  {"production_line_code":"Line04C","production_line_name":"Line 04C AUTO FILLING","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"CODING","sort_order":2},{"activity_name":"BOX PREPARATION","sort_order":3},{"activity_name":"TRANSFER BM TO ARO PUMP","sort_order":4},{"activity_name":"SCOOPING","sort_order":5},{"activity_name":"FILLING","sort_order":6},{"activity_name":"PLUNGERING","sort_order":7},{"activity_name":"SEALING","sort_order":8},{"activity_name":"CAPPING","sort_order":9},{"activity_name":"PACKING/PALLETIZING","sort_order":10}]},
  {"production_line_code":"Line05","production_line_name":"Line 05 EPOXY CLAY","activities":[{"activity_name":"CUTTING","sort_order":1},{"activity_name":"STICKERING","sort_order":2},{"activity_name":"PACKING/PALLETIZING","sort_order":3}]},
  {"production_line_code":"Line06","production_line_name":"Line 06 EPOXY LINE","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"CODING","sort_order":2},{"activity_name":"LABELING","sort_order":3},{"activity_name":"BOX PREPARATION","sort_order":4},{"activity_name":"TRANSFER OF BM TO ARO PUMP","sort_order":5},{"activity_name":"FILLING","sort_order":6},{"activity_name":"CAPPING","sort_order":7},{"activity_name":"PACKING/PALLETIZING","sort_order":8}]},
  {"production_line_code":"Line07","production_line_name":"Line 07 EPOXY TUBE FILLING","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"PRE HEAT OF BM","sort_order":2},{"activity_name":"FILLING","sort_order":3},{"activity_name":"PACKING/PALLETIZING","sort_order":4},{"activity_name":"TRANSFER TO SUBCON","sort_order":5}]},
  {"production_line_code":"Line08","production_line_name":"Line 08","activities":[]},
  {"production_line_code":"Line09","production_line_name":"Line 09 EPS - BLOCKS","activities":[{"activity_name":"BEADS PRE EXPANSION","sort_order":1},{"activity_name":"MOLDING","sort_order":2},{"activity_name":"CUTTING","sort_order":3}]},
  {"production_line_code":"Line09A","production_line_name":"Line 09A EPS - CUTTING","activities":[{"activity_name":"BEADS PRE EXPANSION","sort_order":1},{"activity_name":"MOLDING","sort_order":2},{"activity_name":"CUTTING","sort_order":3}]},
  {"production_line_code":"Line10","production_line_name":"Line 10 CONTACT BOND","activities":[{"activity_name":"CODING","sort_order":1},{"activity_name":"LABELING","sort_order":2},{"activity_name":"BOX PREPARATION","sort_order":3},{"activity_name":"FILLING","sort_order":4},{"activity_name":"CAPPING","sort_order":5},{"activity_name":"PACKING/PALLETIZING","sort_order":6}]},
  {"production_line_code":"Line11","production_line_name":"Line 11 SILICONE FILLING LINE","activities":[{"activity_name":"CODING","sort_order":1},{"activity_name":"FILLING","sort_order":2},{"activity_name":"SCOOPING","sort_order":3},{"activity_name":"PLUNGERING","sort_order":4},{"activity_name":"SEALING","sort_order":5},{"activity_name":"STICKERING","sort_order":6},{"activity_name":"PACKING/PALLETIZING","sort_order":7},{"activity_name":"TRANSFER TO SUBCON","sort_order":8},{"activity_name":"UNBOXING","sort_order":9},{"activity_name":"BATCH CODING","sort_order":10},{"activity_name":"PLACING OF CODED PAIL STICKER LABEL","sort_order":11},{"activity_name":"REBOXING","sort_order":12},{"activity_name":"PUTTING TEMPORARY BOX LABEL (PRINTED STICKER LABEL)","sort_order":13},{"activity_name":"PLACING OF QR CODE ON THE BOXES","sort_order":14}]},
  {"production_line_code":"Line12","production_line_name":"Line 12 SPECIAL PRODUCTS - EPOXY BASED","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"MELTING","sort_order":2},{"activity_name":"CODING","sort_order":3},{"activity_name":"LABELING","sort_order":4},{"activity_name":"BOX PREPARATION","sort_order":5},{"activity_name":"MANUAL TRANSFER BM TO FILLING TANK","sort_order":6},{"activity_name":"FILLING","sort_order":7},{"activity_name":"CAPPING","sort_order":8},{"activity_name":"SEALING","sort_order":9},{"activity_name":"PLUNGERING","sort_order":10},{"activity_name":"PACKING/PALLETIZING","sort_order":11}]},
  {"production_line_code":"Line13","production_line_name":"Line 13 SPECIAL PRODUCTS - WATER BASED","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"MELTING","sort_order":2},{"activity_name":"CODING","sort_order":3},{"activity_name":"LABELING","sort_order":4},{"activity_name":"BOX PREPARATION","sort_order":5},{"activity_name":"MANUAL TRANSFER BM TO FILLING TANK","sort_order":6},{"activity_name":"FILLING","sort_order":7},{"activity_name":"CAPPING","sort_order":8},{"activity_name":"SEALING","sort_order":9},{"activity_name":"PLUNGERING","sort_order":10},{"activity_name":"PACKING/PALLETIZING","sort_order":11}]},
  {"production_line_code":"Line14","production_line_name":"Line 14 SKIM COAT","activities":[{"activity_name":"MIXING","sort_order":1},{"activity_name":"SIEVING","sort_order":2},{"activity_name":"CODING","sort_order":3},{"activity_name":"LABELING","sort_order":4},{"activity_name":"BOX PREPARATION","sort_order":5},{"activity_name":"FILLING","sort_order":6},{"activity_name":"CAPPING","sort_order":7},{"activity_name":"SEALING","sort_order":8},{"activity_name":"PACKING/PALLETIZING","sort_order":9}]},
  {"production_line_code":"SIPS","production_line_name":"STRUCTURAL INSULATED PANEL","activities":[{"activity_name":"BEADS PRE EXPANSION","sort_order":1},{"activity_name":"MOLDING (BLOCK)","sort_order":2},{"activity_name":"CUTTING (LAMINATE)","sort_order":3},{"activity_name":"GLUING","sort_order":4},{"activity_name":"PANEL ASSEMBLY","sort_order":5}]}
]
"""

# --- BM / FG tags from your reference text ---
BM_ACTIVITIES = {
    "MIXING", "MILLING", "LETDOWN", "TINTING", "REACTING",
    "BEADS PRE EXPANSION", "MOLDING", "MOLDING (BLOCK)",
    "SIEVING", "MELTING", "CUTTING", "PRE HEAT OF BM",
    "MANUAL TRANSFER BM TO FILLING TANK", "TRANSFER BM TO ARO PUMP",
    "TRANSFER OF BM TO ARO PUMP",
}
FG_ACTIVITIES = {
    "CODING", "LABELING", "BOX PREPARATION", "FILLING", "CAPPING",
    "PACKING/PALLETIZING", "PACKING/PALLETIZ", "STICKERING",
    "NOZZLE & CAPPING", "CAP TIGHTENING", "PLUNGERING", "TWIST TIE",
    "TRANSFER TO SUBCON", "SCOOPING", "SEALING", "UNBOXING",
    "BATCH CODING", "PLACING OF CODED PAIL STICKER LABEL",
    "REBOXING", "PUTTING TEMPORARY BOX LABEL (PRINTED STICKER LABEL)",
    "PLACING OF QR CODE ON THE BOXES", "CUTTING (LAMINATE)",
    "GLUING", "PANEL ASSEMBLY", "MOLDING (BLOCK)",
}


def normalize_code(code: str) -> str:
    """Line01 -> L01, Line02 -> L02, Line04A -> L04A, SIPS -> SIPS"""
    if code.startswith("Line"):
        return "L" + code[4:]
    return code


def classify(activity_name: str) -> Optional[str]:  # <-- CHANGED HERE
    an = activity_name.upper()
    if an in {a.upper() for a in BM_ACTIVITIES}:
        return "BM"
    if an in {a.upper() for a in FG_ACTIVITIES}:
        return "FG"
    return None


def main():
    data = json.loads(RAW_JSON)

    conn = psycopg2.connect(
        host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
        user=DB_USER, password=DB_PASS
    )
    cur = conn.cursor()

    # 1. Upsert any missing production lines (e.g. SIPS)
    print("Upserting production_lines...")
    for line in data:
        code = normalize_code(line["production_line_code"])
        name = line["production_line_name"]
        cur.execute(
            """
            INSERT INTO production_lines (production_line_code, production_line_name)
            VALUES (%s, %s)
            ON CONFLICT (production_line_code) DO UPDATE
            SET production_line_name = EXCLUDED.production_line_name;
            """,
            (code, name),
        )

    # 2. Clear old line_activities so we start clean
    print("Truncating line_activities...")
    cur.execute("TRUNCATE TABLE line_activities;")

    # 3. Insert aligned activities
    print("Inserting aligned activities...")
    total = 0
    for line in data:
        code = normalize_code(line["production_line_code"])
        for act in line.get("activities", []):
            an = act["activity_name"]
            so = act["sort_order"]
            stage = classify(an)  # BM, FG, or None
            cur.execute(
                """
                INSERT INTO line_activities
                    (production_line_code, activity_name, sort_order, stage)
                VALUES (%s, %s, %s, %s);
                """,
                (code, an, so, stage),
            )
            total += 1

    conn.commit()
    cur.close()
    conn.close()
    print(f"Done. Inserted {total} activities across {len(data)} lines.")


if __name__ == "__main__":
    main()