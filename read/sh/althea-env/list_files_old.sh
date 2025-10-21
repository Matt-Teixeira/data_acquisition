#!/usr/bin/env bash
set -euo pipefail

# Args: <user> <ip> <sme> [identity-file] [port]
REMOTE_USER="${1:?remote username required}"
REMOTE_IP="${2:?remote IP/host required}"
SME="${3:?SME (folder name) required}"
IDENTITY_FILE="${4:-$HOME/.ssh/althea_env}"
PORT="${5:-22}"

DIR="/usr/local/bin/althea/dp/$SME"

# Null-delimited file list (safe for spaces/newlines)
ssh -q \
  -i "${IDENTITY_FILE}" \
  -p "${PORT}" \
  -o BatchMode=yes \
  "${REMOTE_USER}@${REMOTE_IP}" \
  "find \"${DIR}\" -maxdepth 1 -type f -printf '%f\0'"