#!/usr/bin/env bash
set -euo pipefail

REMOTE_NAME="dropbox"
DROPBOX_BASE=""
LOCAL_BASE="/work/$USER"
LOG_FILE="$LOCAL_BASE/rclone_sync.log"

# Default values
FOLDER_NAME=""
DIRECTION="pull"
DRYRUN=""
SYNC_TYPE="copy"

# Parse options: -f <folder> -d <direction> -dry <dryrun> -type <sync|copy>
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--folder)
      FOLDER_NAME="$2"
      shift 2
      ;;
    -d|--direction)
      DIRECTION="$2"
      shift 2
      ;;
    -dry|--dry)
      DRYRUN="dry"
      shift
      ;;
    -t|--type)
      SYNC_TYPE="$2"
      shift 2
      ;;
    *)
      if [[ -z "$FOLDER_NAME" ]]; then
        FOLDER_NAME="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$FOLDER_NAME" ]]; then
  echo "❌ Usage: $0 <folder_name> [pull|push] [dry]"
  exit 1
fi

LOCAL_PATH="${LOCAL_BASE}/${FOLDER_NAME}"
REMOTE_PATH="${REMOTE_NAME}:${DROPBOX_BASE}/${FOLDER_NAME}"
# Only make the directory if LOCAL_PATH is not an existing file

if [[ ! -f "$LOCAL_PATH" ]]; then
  mkdir -p "$LOCAL_PATH"
else
  # if this is file, them only keep the directory portion of folder name for the remote path
  FOLDER_NAME="${FOLDER_NAME%/*}"
fi

REMOTE_PATH="${REMOTE_NAME}:${DROPBOX_BASE}/${FOLDER_NAME}"

RCLONE_FLAGS=(-P --create-empty-src-dirs --log-file "$LOG_FILE" --log-level INFO)
if [[ "$DRYRUN" == "dry" ]]; then
  RCLONE_FLAGS+=(--dry-run -vv)
fi

# Helper: count files (fast-ish, avoids listing everything)
count_remote_files() {
  # Returns:
  #   - an integer count if rclone returns valid JSON
  #   - "ERR" if rclone size fails or doesn't return JSON
  local path="$1"
  local out
  if ! out="$(rclone size "$path" --json 2>/dev/null)"; then
    echo "ERR"
    return 0
  fi

  # Guard: empty output isn't JSON
  if [[ -z "${out//[[:space:]]/}" ]]; then
    echo "ERR"
    return 0
  fi

  python3 - <<'PY' "$out" 2>/dev/null || { echo "ERR"; exit 0; }
import json, sys
s = sys.argv[1]
j = json.loads(s)
print(j.get("count", "ERR"))
PY
}

# Helper: count local files (fast-ish, via find)
count_local_files() {
  # Returns an integer count of files in the local path
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "0"
    return 0
  fi
  # count regular files only (excludes dirs, symlinks, etc.)
  find "$path" -type f 2>/dev/null | wc -l
}

echo "--------------------------------------------------------"
echo "📂 Dropbox folder: ${REMOTE_PATH}"
echo "📁 Local folder:   ${LOCAL_PATH}"
echo "🔁 Direction:      ${DIRECTION}"
echo "🕒 Started:        $(date)"
echo "🧾 Log file:       ${LOG_FILE}"
echo "--------------------------------------------------------"

if [[ "$DIRECTION" == "pull" ]]; then
  echo "⬇️  Syncing Dropbox → Hopper..."

  remote_n=$(count_remote_files "$REMOTE_PATH")
  echo "🔎 Remote file count (estimate): $remote_n"

  if [[ "$remote_n" == "ERR" ]]; then
    echo "❌ Can't estimate remote size (rclone size failed or returned non-JSON)."
    echo "   Listing remote for diagnostics:"
    rclone lsd "$REMOTE_PATH" -vv || true
    echo "   Aborting to prevent accidental deletes."
    exit 1
  fi

  if [[ "$remote_n" -eq 0 ]]; then
    echo "❌ Refusing to proceed: remote path looks empty."
    exit 1
  fi

  # For pull, default to COPY (safer). Allow sync if explicitly requested.
  if [[ "$SYNC_TYPE" == "sync" ]]; then
    echo "⚠️  Using SYNC for pull may delete local files not present in Dropbox."
    read -p "Proceed with PULL-SYNC? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "❌ Canceled."; exit 1; }
    echo "Running: rclone sync \"$REMOTE_PATH\" \"$LOCAL_PATH\" ${RCLONE_FLAGS[*]}"
    rclone sync "$REMOTE_PATH" "$LOCAL_PATH" "${RCLONE_FLAGS[@]}"
  else
    echo "Running: rclone copy \"$REMOTE_PATH\" \"$LOCAL_PATH\" ${RCLONE_FLAGS[*]}"
    rclone copy "$REMOTE_PATH" "$LOCAL_PATH" "${RCLONE_FLAGS[@]}"
  fi

elif [[ "$DIRECTION" == "push" ]]; then
  echo "⬆️  Syncing Hopper → Dropbox..."

  local_n=$(count_local_files "$LOCAL_PATH")
  echo "🔎 Local file count: $local_n"

  if [[ "$local_n" -eq 0 ]] && [[ "$SYNC_TYPE" == "sync" ]]; then
    echo "❌ Refusing to sync: local path has zero files."
    echo "   Using 'sync' from an empty local folder would delete the Dropbox contents."
    echo "   Use 'copy' to copy files to Dropbox without deleting anything."
    exit 1
  fi

  echo "⚠️  This may delete files in Dropbox that are not present locally."
  echo "rclone ${SYNC_TYPE} ${LOCAL_PATH} ${REMOTE_PATH} ${RCLONE_FLAGS[@]}"
  read -p "Proceed with PUSH? (y/N): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rclone "${SYNC_TYPE}" "${LOCAL_PATH}" "${REMOTE_PATH}" "${RCLONE_FLAGS[@]}"
  else
    echo "❌ Sync canceled."
    exit 1
  fi

else
  echo "❌ Direction must be 'pull' or 'push'."
  exit 1
fi

echo "✅ Done! Finished at $(date)"
echo "--------------------------------------------------------"
