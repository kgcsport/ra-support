#!/usr/bin/env bash
#
# sync_dropbox.sh
# Sync a Dropbox folder with Hopper using rclone.
# Usage:
#   ./sync_dropbox.sh <folder_name> [direction]
#
# folder_name : Dropbox folder under /Projects/
# direction   : "pull" (default) = Dropbox → Hopper
#               "push"            = Hopper → Dropbox
#
# Example:
#   ./sync_dropbox.sh MyStudy
#   ./sync_dropbox.sh MyStudy push

set -euo pipefail

REMOTE_NAME="dropbox"
DROPBOX_BASE="/Projects"
LOCAL_BASE="/work/$USER"
LOG_FILE="$LOCAL_BASE/rclone_sync.log"

FOLDER_NAME=${1:-}
DIRECTION=${2:-pull}

if [[ -z "$FOLDER_NAME" ]]; then
  echo "❌ Usage: $0 <folder_name> [pull|push]"
  exit 1
fi

REMOTE_PATH="${REMOTE_NAME}:${DROPBOX_BASE}/${FOLDER_NAME}"
LOCAL_PATH="${LOCAL_BASE}/${FOLDER_NAME}"

mkdir -p "$LOCAL_PATH"

echo "--------------------------------------------------------"
echo "📂 Dropbox folder: ${REMOTE_PATH}"
echo "📁 Local folder:   ${LOCAL_PATH}"
echo "🔁 Direction:      ${DIRECTION}"
echo "🕒 Started:        $(date)"
echo "--------------------------------------------------------" | tee -a "$LOG_FILE"

if [[ "$DIRECTION" == "pull" ]]; then
  echo "⬇️  Syncing Dropbox → Hopper..."
  rclone sync "${REMOTE_PATH}" "${LOCAL_PATH}" -P --create-empty-src-dirs | tee -a "$LOG_FILE"
elif [[ "$DIRECTION" == "push" ]]; then
  echo "⬆️  Syncing Hopper → Dropbox..."
  rclone sync "${LOCAL_PATH}" "${REMOTE_PATH}" -P --create-empty-src-dirs | tee -a "$LOG_FILE"
else
  echo "❌ Direction must be 'pull' or 'push'."
  exit 1
fi

echo "✅ Done! Finished at $(date)" | tee -a "$LOG_FILE"
echo "--------------------------------------------------------"