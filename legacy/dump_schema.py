import psycopg2
from config import Config

def dump_schema():
    conn = psycopg2.connect(
        host=Config.DB_HOST,
        port=Config.DB_PORT,
        dbname=Config.DB_NAME,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD
    )
    cur = conn.cursor()
    cur.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public';
    """)
    tables = cur.fetchall()
    for table in tables:
        print(f"Table: {table[0]}")
        cur.execute(f"""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = '{table[0]}';
        """)
        columns = cur.fetchall()
        for col in columns:
            print(f"  {col[0]}: {col[1]}")
    conn.close()

if __name__ == "__main__":
    dump_schema()
