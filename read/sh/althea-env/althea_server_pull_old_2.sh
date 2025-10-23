#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./pull_althea_dp.sh <user> <host> <sme> <remote_filename> <local_dest> [identity-file] [port]
#
# Examples:
#   ./pull_althea_dp.sh mattteixeira 20.55.232.226 SME20288 SME20288-GEMM3-day011025.dat ./inbox
#   ./pull_althea_dp.sh mattteixeira 20.55.232.226 SME20288 SME20288-GEMM3-day011025.dat ./inbox/file.dat ~/.ssh/althea_env 22

REMOTE_USER="${1:?remote username required}"
REMOTE_HOST="${2:?remote host/IP required}"
SME="${3:?SME folder required}"
REMOTE_FILE="${4:?remote filename required}"      # e.g. SME20288-GEMM3-day011025.dat
LOCAL_DEST="${5:?local destination path required}"
IDENTITY_FILE="${6:-$HOME/.ssh/althea_env}"
PORT="${7:-22}"

REMOTE_DIR="/usr/local/bin/althea/dp/${SME}"
SRC="${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/${REMOTE_FILE}"

[ ! -d "$5" ] && mkdir $5

# Copy the file
scp -q -p \
  -i "$IDENTITY_FILE" \
  -P "$PORT" \
  -o BatchMode=yes \
  -- "$SRC" "$LOCAL_DEST"
