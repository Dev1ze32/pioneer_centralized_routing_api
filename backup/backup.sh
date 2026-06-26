#!/bin/sh
# ACU Routing API — Automated Backup Script
# Usage: ./backup.sh <weekly|monthly>

TYPE=$1
if [ -z "$TYPE" ]; then
  echo "Error: Backup type (weekly or monthly) not specified."
  exit 1
fi

# Ensure environment variables are available to pg_dump
export PGPASSWORD="$DB_PASSWORD"

# Create target directory
BACKUP_DIR="/backups/${TYPE}"
mkdir -p "$BACKUP_DIR"

# Generate filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting ${TYPE} backup to ${FILENAME}..."

# Dump and compress
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" | gzip > "$FILENAME"

if [ $? -eq 0 ]; then
  echo "[$(date)] Backup successful."
else
  echo "[$(date)] Backup failed!"
  exit 1
fi

# Apply retention policy
if [ "$TYPE" = "weekly" ]; then
  echo "[$(date)] Cleaning up weekly backups older than 90 days..."
  find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +90 -exec rm -f {} \;
elif [ "$TYPE" = "monthly" ]; then
  echo "[$(date)] Cleaning up monthly backups older than 360 days..."
  find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +360 -exec rm -f {} \;
fi

echo "[$(date)] Backup process finished."
