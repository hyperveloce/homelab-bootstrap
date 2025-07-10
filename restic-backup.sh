#!/bin/bash

# === CONFIGURATION ===
ENV_FILE="../.env"
LOG_FILE="/srv/data/log/restic-backup.log"
BACKUP_MOUNT="/mnt/asus/kserver_backup"
REPO_PATH="$BACKUP_MOUNT/restic-backups"
RESTIC_BIN="$(which restic)"
BACKUP_PATHS=("/srv/data")

DB_BACKUP_DIR="/srv/data/db_backup"
NEXTCLOUD_DB_DUMP="$DB_BACKUP_DIR/nextcloud.sql"
IMMICH_DB_DUMP="$DB_BACKUP_DIR/immich_postgres.sql.gz"

# # Fix permissions for backup
# chown -R kanasu:kanasu /srv/data
# chmod -R u+rwX /srv/data

# === LOAD ENVIRONMENT VARIABLES ===
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "❌ ERROR: .env file not found at $ENV_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

# Ensure db_backup directory exists
mkdir -p "$DB_BACKUP_DIR"

# Unset RESTIC_PASSWORD_FILE if set, to avoid conflicts
unset RESTIC_PASSWORD_FILE

# === CHECK RESTIC PASSWORD ===
if [ -z "$RESTIC_PASSWORD" ]; then
    echo "❌ RESTIC_PASSWORD not loaded. Check .env file." | tee -a "$LOG_FILE"
    exit 1
fi

# === CHECK BACKUP DRIVE ===
echo "🔍 Checking if $BACKUP_MOUNT is mounted..." | tee -a "$LOG_FILE"
if ! mountpoint -q "$BACKUP_MOUNT"; then
    echo "❌ ERROR: Backup drive $BACKUP_MOUNT is not mounted. Exiting." | tee -a "$LOG_FILE"
    exit 1
fi

# === DUMP NEXTCLOUD DATABASE ===
echo "📦 Dumping Nextcloud DB..." | tee -a "$LOG_FILE"
docker run --rm --network app_network \
  -e MYSQL_PWD="$MYSQL_PASSWORD" \
  mysql:8.0 \
  mysqldump -h nc_db -u nextcloud nextcloud > "$NEXTCLOUD_DB_DUMP"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Nextcloud DB dump failed!" | tee -a "$LOG_FILE"
    exit 1
fi

# === DUMP IMMICH DATABASE ===
echo "📦 Dumping Immich Postgres DB..." | tee -a "$LOG_FILE"
docker exec -t immich_postgres \
  pg_dumpall --clean --if-exists --username=postgres | gzip > "$IMMICH_DB_DUMP"

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Immich DB dump failed!" | tee -a "$LOG_FILE"
    exit 1
fi

# === RUN RESTIC BACKUP ===
echo "🚀 Starting backup: $(date)" | tee -a "$LOG_FILE"
$RESTIC_BIN backup "${BACKUP_PATHS[@]}" \
  --repo "$REPO_PATH" \
  --password-command "echo $RESTIC_PASSWORD" \
  >> "$LOG_FILE" 2>&1

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "❌ ERROR: Restic backup failed!" | tee -a "$LOG_FILE"
    exit 1
fi

# === UNLOCK STALE REPO LOCKS BEFORE PRUNE ===
echo "🔓 Ensuring repo is not locked..." | tee -a "$LOG_FILE"
$RESTIC_BIN unlock \
  --repo "$REPO_PATH" \
  --password-command "echo $RESTIC_PASSWORD" >> "$LOG_FILE" 2>&1

# === RETENTION POLICY (Run only on Sundays) ===
DAY_OF_WEEK=$(date +%u)
if [ "$DAY_OF_WEEK" -eq 7 ]; then
    echo "🧹 Applying retention policy..." | tee -a "$LOG_FILE"
    $RESTIC_BIN forget \
      --repo "$REPO_PATH" \
      --password-command "echo $RESTIC_PASSWORD" \
      --keep-daily 7 \
      --keep-weekly 2 \
      --keep-monthly 2 \
      --prune >> "$LOG_FILE" 2>&1

    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        echo "❌ ERROR: Retention/prune failed!" | tee -a "$LOG_FILE"
        exit 1
    fi
fi

# === DONE ===
echo "✅ Backup completed successfully: $(date)" | tee -a "$LOG_FILE"
