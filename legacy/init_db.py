import sys
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def init_db(password):
    host = "localhost"
    port = "5432"
    dbname = "routing_db"
    user = "postgres"

    print("Connecting to local PostgreSQL instance...")
    try:
        # Connect to the default 'postgres' database first to create the new one
        conn = psycopg2.connect(
            host=host,
            port=port,
            dbname="postgres",
            user=user,
            password=password
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cur = conn.cursor()

        cur.execute("SELECT 1 FROM pg_catalog.pg_database WHERE datname = %s", (dbname,))
        exists = cur.fetchone()

        if not exists:
            print(f"Database '{dbname}' does not exist. Creating it now...")
            cur.execute(f"CREATE DATABASE {dbname};")
            print(f"Successfully created database '{dbname}'.")
        else:
            print(f"Database '{dbname}' already exists. Skipping creation.")

        cur.close()
        conn.close()

    except Exception as e:
        print(f"Error connecting to PostgreSQL or creating database: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python init_db.py <db_password>")
        sys.exit(1)
    
    init_db(sys.argv[1])
