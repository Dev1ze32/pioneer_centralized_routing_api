#!/bin/sh
# =============================================================================
# ACU Routing API — PostgreSQL Restore Script
#
# Restores a database from a .sql.gz backup file.
#
# Usage (run from the project root):
#   docker compose exec backup restore.sh backups/routing_db_weekly_2026-06-22.sql.gz
#
# Or from outside the container:
#   docker compose run --rm backup restore.sh /backups/routing_db_weekly_2026-06-22.sql.gz
#
# WARNING: This drops and recreates the database. All current data will be
# replaced with the contents of the backup file. There is no undo.
# =============================================================================

set -e

BACKUP_FILE="${1}"

if [ -z "$BACKUP_FILE" ]; then
  echo "ERROR: No backup file specified."
  echo "Usage: restore.sh <path-to-backup.sql.gz>"
  echo ""
  echo "Available backups:"
  ls -lh /backups/*.sql.gz 2>/dev/null || echo "  (no backups found in /backups)"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: File not found: ${BACKUP_FILE}"
  exit 1
fi

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-routing_db}"
DB_USER="${DB_USER:-postgres}"
export PGPASSWORD="${DB_PASSWORD}"

echo "=========================================="
echo " ACU Routing API — Database Restore"
echo "=========================================="
echo " Backup file : ${BACKUP_FILE}"
echo " Target DB   : ${DB_NAME} on ${DB_HOST}:${DB_PORT}"
echo " User        : ${DB_USER}"
echo "=========================================="
echo ""
echo "WARNING: This will DROP and RECREATE the database."
echo "All current data will be permanently replaced."
echo ""
printf "Type YES to continue: "
read CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Restore cancelled."
  exit 0
fi

echo ""
echo "[$(date)] Waiting for Postgres..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -q; do
  sleep 2
done
echo "[$(date)] Postgres is ready."

echo "[$(date)] Dropping existing database '${DB_NAME}'..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres \
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}' AND pid <> pg_backend_pid();" \
  -c "DROP DATABASE IF EXISTS ${DB_NAME};" \
  -c "CREATE DATABASE ${DB_NAME};"

echo "[$(date)] Restoring from ${BACKUP_FILE}..."
gunzip -c "$BACKUP_FILE" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"

echo ""
echo "[$(date)] Restore complete. Database '${DB_NAME}' has been restored."