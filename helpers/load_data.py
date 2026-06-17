import json
import psycopg2

# Database connection parameters
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "routing_db"
DB_USER = "postgres"
DB_PASS = "Anciso-320910"

# Input JSON file
JSON_FILE = "./output/acu_routing_parsed.json"

def load_data():
    # 1. Load the JSON data
    with open(JSON_FILE, "r") as f:
        data = json.load(f)

    # 2. Connect to the database
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        cur = conn.cursor()

        # 3. Clear existing data safely
        # We use TRUNCATE instead of DROP so we don't destroy your Foreign Key constraints
        print("Clearing old data (preserving schema constraints)...")
        cur.execute("TRUNCATE TABLE activities CASCADE;")
        cur.execute("TRUNCATE TABLE products CASCADE;")

        # 4. Prepare Insert Queries
        product_insert_query = """
            INSERT INTO products (
                inventory_id, revision_descr, revision, notes, product_type,
                bm_production_line, bm_production_line_code,
                fg_production_line, fg_production_line_code
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (inventory_id) DO NOTHING;
        """

        activity_insert_query = """
            INSERT INTO activities (
                inventory_id, type, item_id, qty_required, activity_name, 
                class, class_1, pax, machine, time_min, sort_order
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
        """

        print(f"Loading {len(data)} products into the database...")

        product_count = 0
        activity_count = 0

        # 5. Loop through data and insert
        for inv_id, prod in data.items():
            # Grab the parsed values
            prod_line = prod.get("production_line")
            prod_line_code = prod.get("production_line_code")
            prod_type = prod.get("product_type")

            # Map the JSON to the new split table structure
            product_values = (
                prod.get("inventory_id"),
                prod.get("revision_descr"),
                prod.get("revision"),
                prod.get("notes"),
                prod_type,        # New Field
                prod_line,        # Assigned to BM
                prod_line_code,   # Assigned to BM Code
                prod_line,        # Assigned to FG
                prod_line_code    # Assigned to FG Code
            )
            cur.execute(product_insert_query, product_values)
            product_count += 1

            # Insert associated activities
            activities = prod.get("activities", [])
            for i, act in enumerate(activities):
                activity_values = (
                    inv_id,
                    act.get("type"),
                    act.get("item_id"),
                    act.get("qty_required"),
                    act.get("activities"),
                    act.get("class"),
                    act.get("class_1"),
                    act.get("pax"),
                    act.get("machine"),
                    act.get("time_min"),
                    i + 1  # Using loop index for sort_order
                )
                cur.execute(activity_insert_query, activity_values)
                activity_count += 1

        # 6. Commit and close
        conn.commit()
        print(f"Success! Inserted {product_count} products and {activity_count} activities.")

    except (Exception, psycopg2.Error) as error:
        print("Error while connecting to PostgreSQL:", error)
        if 'conn' in locals():
            conn.rollback()
    finally:
        if 'conn' in locals() and conn:
            cur.close()
            conn.close()
            print("PostgreSQL connection is closed.")

if __name__ == "__main__":
    load_data()