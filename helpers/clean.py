import psycopg2

DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "routing_db"
DB_USER = "postgres"
DB_PASS = "Anciso-320910"

conn = psycopg2.connect(
    host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
    user=DB_USER, password=DB_PASS
)
cur = conn.cursor()

# Delete old "Line01", "Line02", etc. that have no activities linked
cur.execute("""
    DELETE FROM production_lines
    WHERE production_line_code LIKE 'Line%';
""")

deleted = cur.rowcount
conn.commit()
cur.close()
conn.close()

print(f"Deleted {deleted} orphaned 'LineXX' records.")