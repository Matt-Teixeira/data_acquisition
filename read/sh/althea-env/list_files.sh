#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./list_althea_dp_files.sh <user> <host_or_ip> <sme> [port]
#
# Example:
#   ./list_althea_dp_files.sh mattteixeira 20.55.232.226 SME20288
#   SSH_OPTS='-o IdentitiesOnly=yes' ./list_althea_dp_files.sh mattteixeira 20.55.232.226 SME20288 22
#
# Notes:
# - This version does NOT pass an IdentityFile (-i). It uses your default SSH setup
#   (ssh-agent, ~/.ssh/config, or password prompt).
# - Removed BatchMode=yes so a password prompt is allowed if needed.
# - Output is null-delimited (safe for spaces/newlines in filenames).

REMOTE_USER="${1:?remote username required}"
REMOTE_HOST="${2:?remote IP/host required}"
SME="${3:?SME (folder name) required}"
PORT="${4:-22}"

REMOTE_DIR="/usr/local/bin/althea/dp/${SME}"

# Optional: inject extra SSH opts (e.g., SSH_OPTS='-o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new')
: "${SSH_OPTS:=}"

ssh -q \
  -p "${PORT}" \
  ${SSH_OPTS} \
  "${REMOTE_USER}@${REMOTE_HOST}" \
  "find \"${REMOTE_DIR}\" -maxdepth 1 -type f -printf '%f\0'"
