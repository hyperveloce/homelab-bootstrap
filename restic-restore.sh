#!/bin/bash

# sudo ./scripts/restic-restore.sh

# === CONFIGURATION ===
RESTIC_REPO="/mnt/asus/kserver_backup/restic-backups"
RESTORE_TARGET="/srv/restic-restore"
PASSWORD_FILE="../restic-pw.txt"
LOG_FILE="/srv/restic-restore/restic-backup.log"

# === CHECKS ===
if [ ! -f "$PASSWORD_FILE" ]; then
    echo "❌ Password file not found: $PASSWORD_FILE"
    exit 1
fi

if [ ! -d "$RESTIC_REPO" ]; then
    echo "❌ Restic repo not found: $RESTIC_REPO"
    exit 1
fi

# === FETCH LATEST SNAPSHOT ID ===
echo "🔍 Fetching latest snapshot ID..." | tee -a "$LOG_FILE"
LATEST_SNAPSHOT_ID=$(restic snapshots \
    --repo "$RESTIC_REPO" \
    --password-file "$PASSWORD_FILE" \
    --json | jq -r '.[-1].short_id')

if [ -z "$LATEST_SNAPSHOT_ID" ]; then
    echo "❌ Could not determine latest snapshot ID" | tee -a "$LOG_FILE"
    exit 1
fi

echo "📦 Latest snapshot ID: $LATEST_SNAPSHOT_ID" | tee -a "$LOG_FILE"

# === PREPARE RESTORE TARGET ===
echo "📁 Cleaning restore target: $RESTORE_TARGET" | tee -a "$LOG_FILE"
rm -rf "$RESTORE_TARGET"
mkdir -p "$RESTORE_TARGET"

# === RESTORE ===
echo "🚀 Restoring snapshot $LATEST_SNAPSHOT_ID..." | tee -a "$LOG_FILE"
restic restore "$LATEST_SNAPSHOT_ID" \
    --repo "$RESTIC_REPO" \
    --password-file "$PASSWORD_FILE" \
    --target "$RESTORE_TARGET" \
    | tee -a "$LOG_FILE"

if [ "${PIPESTATUS[0]}" -ne 0 ]; then
    echo "❌ Restore failed!" | tee -a "$LOG_FILE"
    exit 1
else
    echo "✅ Restore completed successfully at $(date)" | tee -a "$LOG_FILE"
    echo "📂 Restored files are in: $RESTORE_TARGET"
fi
