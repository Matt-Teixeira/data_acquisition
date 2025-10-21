#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./pull_althea_dp.sh <user> <host> <sme> <remote_filename> <local_dest> [port]
#
# Examples:
#   ./pull_althea_dp.sh mattteixeira 20.55.232.226 SME20288 SME20288-GEMM3-day011025.dat ./inbox
#   ./pull_althea_dp.sh mattteixeira 20.55.232.226 SME20288 SME20288-GEMM3-day011025.dat ./inbox/file.dat 22
#
# Notes:
# - This version does NOT pass an IdentityFile (-i). It uses your default SSH setup.
# - Removed BatchMode=yes so you can enter a password if needed.
# - You can inject extra SSH options via $SSH_OPTS (optional).

REMOTE_USER="${1:?remote username required}"
REMOTE_HOST="${2:?remote host/IP required}"
SME="${3:?SME folder required}"
REMOTE_FILE="${4:?remote filename required}"      # e.g. SME20288-GEMM3-day011025.dat
LOCAL_DEST="${5:?local destination path required}"
PORT="${6:-22}"

REMOTE_DIR="/usr/local/bin/althea/dp/${SME}"
SRC="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/${REMOTE_FILE}"

# Figure out whether the user intends a directory or a file for LOCAL_DEST
# - If LOCAL_DEST ends with '/' OR exists as a directory, treat as directory
# - Otherwise treat as a file path and ensure its parent exists
if [[ "$LOCAL_DEST" == */ || -d "$LOCAL_DEST" ]]; then
  mkdir -p -- "$LOCAL_DEST"
  DEST_PATH="$LOCAL_DEST"
else
  mkdir -p -- "$(dirname -- "$LOCAL_DEST")"
  DEST_PATH="$LOCAL_DEST"
fi

# Optional extra ssh/scp options via environment (e.g., SSH_OPTS='-o IdentitiesOnly=yes')
: "${SSH_OPTS:=}"

# Copy the file (preserve times/perm with -p)
scp -q -p \
  -P "$PORT" \
  $SSH_OPTS \
  -- "$SRC" "$DEST_PATH"
