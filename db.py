"""
Shared PostgreSQL connection helper.
Reads connection settings from config.py (no repeated os.getenv).
"""

import psycopg2
import psycopg2.extras

from config import Config


def get_connection():
    """Return a new psycopg2 connection using centralized config."""
    return psycopg2.connect(
        host=Config.DB_HOST,
        port=Config.DB_PORT,
        dbname=Config.DB_NAME,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
    )


def get_dict_cursor(conn):
    """Return a cursor that returns rows as dict-like objects."""
    return conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)