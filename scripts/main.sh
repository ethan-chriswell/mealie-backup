#!/bin/bash
set -euo pipefail

# --------------------------
# Configuration
# --------------------------
MEALIE_URL="${MEALIE_URL:-https://your-mealie-instance.com}"  # Set your Mealie URL
MEALIE_API_KEY="${MEALIE_API_KEY:-your_api_key_here}" # Set your Mealie API key
BACKUP_DIR="${BACKUP_DIR:-./backups/mealie}"       # Local directory to save backups

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"
chmod 755 "$BACKUP_DIR"

# --------------------------
# 1. Trigger backup
# --------------------------
echo "Triggering Mealie backup..."
curl -sSL -X POST "$MEALIE_URL/api/admin/backups" \
     -H "Authorization: Bearer $MEALIE_API_KEY" \
     -H "Content-Type: application/json"

# Optional: small delay to allow backup creation
sleep 5

# --------------------------
# 2. List backups
# --------------------------
echo "Fetching list of backups..."
BACKUPS_JSON=$(curl -sSL "$MEALIE_URL/api/admin/backups" \
    -H "Authorization: Bearer $MEALIE_API_KEY")

# --------------------------
# 3. Get the latest backup filename
# --------------------------
LATEST_FILE=$(echo "$BACKUPS_JSON" | jq -r '.imports | sort_by(.date) | last(.[]) | .name')

if [[ -z "$LATEST_FILE" || "$LATEST_FILE" == "null" ]]; then
    echo "No backups found!"
    exit 1
fi

echo "Latest backup file: $LATEST_FILE"

# --------------------------
# 4. Get fileToken for latest backup
# --------------------------
FILE_TOKEN=$(curl -sSL "$MEALIE_URL/api/admin/backups/$LATEST_FILE" \
    -H "Authorization: Bearer $MEALIE_API_KEY" | jq -r '.fileToken')

if [[ -z "$FILE_TOKEN" || "$FILE_TOKEN" == "null" ]]; then
    echo "Failed to get fileToken for $LATEST_FILE"
    exit 1
fi

echo "fileToken obtained: $FILE_TOKEN"

# --------------------------
# 5. Download backup using fileToken
# --------------------------
BACKUP_PATH="$BACKUP_DIR/$LATEST_FILE"
echo "Downloading backup to $BACKUP_PATH ..."
curl -sSL "$MEALIE_URL/api/utils/download?token=$FILE_TOKEN" \
     -H "Authorization: Bearer $MEALIE_API_KEY" \
     -o "$BACKUP_PATH"

echo "Backup downloaded successfully!"

# --------------------------
# 6. Transfer backup file to remote server via SMB
# --------------------------
REMOTE_DIR="Homelab/mealie"

smbclient "//${BACKUP_SERVER_HOST}/Backups" \
  -U "$BACKUP_SERVER_USER%$BACKUP_SERVER_PASSWORD" \
  -c "cd $REMOTE_DIR; put $BACKUP_PATH $(basename $BACKUP_PATH)" \
  && echo "Transferred $BACKUP_PATH to backup server."