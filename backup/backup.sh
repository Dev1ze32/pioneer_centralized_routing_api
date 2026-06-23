#!/bin/sh
# =============================================================================
# ACU Routing API — PostgreSQL Backup Script
# Runs inside the backup container on a cron schedule.
#
# Weekly  backups: every Sunday at 02:00  — kept for 90 days
# Monthly backups: 1st of month at 03:00  — kept for 365 days
#
# Backup files are written to /backups (bind-mounted from the host).
# Filename format:
#   routing_db_weekly_2026-06-22.sql.gz
#   routing_db_monthly_2026-06-01.sql.gz
# =============================================================================

set -e

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-routing_db}"
DB_USER="${DB_USER:-postgres}"
export PGPASSWORD="${DB_PASSWORD}"

BACKUP_DIR="/backups"
DATE=$(date +%Y-%m-%d)
TYPE="${1:-weekly}"
FILENAME="${BACKUP_DIR}/${DB_NAME}_${TYPE}_${DATE}.sql.gz"

echo "[$(date)] Waiting for Postgres at ${DB_HOST}:${DB_PORT}..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -q; do
  sleep 2
done
echo "[$(date)] Postgres is ready."

echo "[$(date)] Starting ${TYPE} backup -> ${FILENAME}"
pg_dump \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --format=plain \
  --no-password \
  | gzip > "$FILENAME"

SIZE=$(du -sh "$FILENAME" | cut -f1)
echo "[$(date)] Backup complete. Size: ${SIZE}"

if [ "$TYPE" = "weekly" ]; then
  KEEP_DAYS=90
else
  KEEP_DAYS=365
fi

echo "[$(date)] Removing ${TYPE} backups older than ${KEEP_DAYS} days..."
find "$BACKUP_DIR" -name "${DB_NAME}_${TYPE}_*.sql.gz" -mtime +${KEEP_DAYS} -delete
echo "[$(date)] Cleanup done."

echo "[$(date)] Current backups in ${BACKUP_DIR}:"
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "  (no backups yet)"