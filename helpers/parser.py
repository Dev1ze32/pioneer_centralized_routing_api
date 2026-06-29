"""
ACU Routing Parser (With Classifier)
------------------------------------
Reads the ACU Routing CSV file, applies the required filters, drops the
unneeded columns, and groups everything by Inventory ID. 

Classifier Added:
Evaluates the list of activities per Inventory ID to determine its type:
    - Base Material (BM)
    - Finished Good (FG)
    - Other / Intermediate
"""

import json
import math
import pandas as pd
import os

SOURCE_COLUMNS = [
    "Inventory ID",
    "Revision Descr.",
    "Revision",
    "Notes",
    "Type",
    "Item ID",
    "ACTIVITIES",
    "Production Line",
    "Production Line.1",
    "CLASS",
    "CLASS.1",
    "Pax",
    "Machine",
    "Qty Required",
]

# Fields that describe the PRODUCT (one value per Inventory ID)
PRODUCT_FIELDS = {
    "Inventory ID": "inventory_id",
    "Revision Descr.": "revision_descr",
    "Revision": "revision",
    "Notes": "notes",
    "Production Line": "production_line",
    "Production Line.1": "production_line_code",
}

# Fields that describe an ACTIVITY (one row per labor step)
ACTIVITY_FIELDS = {
    "Type": "type",
    "Item ID": "item_id",
    "ACTIVITIES": "activities",
    "CLASS": "class",
    "CLASS.1": "class_1",
    "Pax": "pax",
    "Machine": "machine",
    "Qty Required": "time_min",
}

# --- Classifier Configuration ---
MIX_STEPS = ['MIXING', 'MILLING', 'TINTING', 'LETDOWN', 'REACTING']
FG_STEPS = ['PACKING', 'PALLETIZ', 'LABELING', 'CODING']

def _clean(value):
    """Convert pandas/NumPy values into plain JSON-friendly Python values."""
    if value is None:
        return None
    if isinstance(value, float) and math.isnan(value):
        return None
    try:
        if pd.isna(value):
            return None
    except (TypeError, ValueError):
        pass
    if hasattr(value, "item"):
        return value.item()
    return value

def classify_product(activities_list):
    """
    Evaluates a list of activity dictionaries for a product and returns its classification.
    """
    # Create a giant string of all activity names for this product to search against
    all_activities = " ".join([str(act.get("activities", "")).upper() for act in activities_list])
    
    has_mix_step = any(step in all_activities for step in MIX_STEPS)
    has_fg_step = any(step in all_activities for step in FG_STEPS)
    is_subcon = 'SUBCON' in all_activities or 'SC -' in all_activities
    
    if has_fg_step or is_subcon:
        return 'Finished Good (FG)'
    elif has_mix_step and not has_fg_step:
        return 'Base Material (BM)'
    else:
        return 'Other / Intermediate'

def parse_acu_routing(filepath: str) -> dict:
    """Parse the ACU routing Excel file into a dict keyed by Inventory ID and classify them."""
    # Ensure openpyxl is installed to read .xlsx files
    df = pd.read_excel(filepath)

    # 1. Filter: Type == Labor
    filtered = df[df["Type"] == "Labor"]

    # 2. Keep only the columns we care about
    available = [c for c in SOURCE_COLUMNS if c in filtered.columns]
    missing = [c for c in SOURCE_COLUMNS if c not in filtered.columns]
    if missing:
        print(f"Warning: the following columns were not found and will be skipped: {missing}")
    filtered = filtered[available]

    # 3. Group by Inventory ID
    result: dict = {}
    for _, row in filtered.iterrows():
        inv_id = row["Inventory ID"]

        if inv_id not in result:
            product = {
                new_key: _clean(row[old_key])
                for old_key, new_key in PRODUCT_FIELDS.items()
                if old_key in available
            }
            product["activities"] = []
            result[inv_id] = product

        activity = {
            new_key: _clean(row[old_key])
            for old_key, new_key in ACTIVITY_FIELDS.items()
            if old_key in available
        }
        
        import re
        raw_activity = str(activity.get("activities", "") or "").strip()
        # Remove line code prefixes like 'L01 ', 'L04A ', 'SIPS ' from the activity name
        activity["activities"] = re.sub(r'^(?:L\d+[A-Z]?|SIPS)\s+', '', raw_activity).strip()

        # Override these fields to be empty (null) for now as requested
        activity["pax"] = None
        activity["machine"] = None
        activity["time_min"] = None

        result[inv_id]["activities"].append(activity)

    # 4. Apply Classification Logic after grouping
    for inv_id, product_data in result.items():
        # Inject the classification at the root level of the product
        product_data["product_type"] = classify_product(product_data["activities"])

    return result


if __name__ == "__main__":
    SOURCE_FILE = "FY26 ACU Routing.xlsx"
    
    # 1. Define the specific output folder path
    OUTPUT_DIR = "./output"
    OUTPUT_FILE = f"{OUTPUT_DIR}/acu_routing_parsed.json"

    # 2. Safety check: Create the 'output' folder if it got deleted
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("Parsing and Classifying Data...")
    data = parse_acu_routing(SOURCE_FILE)

    print(f"Parsed {len(data)} unique inventory IDs")
    total_activities = sum(len(v["activities"]) for v in data.values())
    print(f"Total activity rows: {total_activities}")

    # Breakdown by classification
    fg_count = sum(1 for v in data.values() if v["product_type"] == 'Finished Good (FG)')
    bm_count = sum(1 for v in data.values() if v["product_type"] == 'Base Material (BM)')
    other_count = sum(1 for v in data.values() if v["product_type"] == 'Other / Intermediate')
    
    print(f"\nClassification Breakdown:")
    print(f" - Finished Goods (FG): {fg_count}")
    print(f" - Base Materials (BM): {bm_count}")
    print(f" - Other / Intermediate: {other_count}")

    with open(OUTPUT_FILE, "w") as f:
        json.dump(data, f, indent=2)

    print(f"\nSaved exclusively to {OUTPUT_FILE}")