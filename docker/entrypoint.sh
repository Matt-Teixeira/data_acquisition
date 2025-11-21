#!/usr/bin/env bash
set -euo pipefail

BUNDLE_DIR="/opt/ssh_bundles/data_acquisition"
SSH_DIR="${HOME}/.ssh"

# 1️⃣ Before: copy bundle into this user's ~/.ssh
if [ -d "$BUNDLE_DIR" ]; then
  echo "[entrypoint] Found SSH bundle at $BUNDLE_DIR"

  mkdir -p "$SSH_DIR"
  cp "$BUNDLE_DIR"/* "$SSH_DIR"/

  chmod 700 "$SSH_DIR" || true
  chmod 600 "$SSH_DIR"/mmb_google_deb 2>/dev/null || true

  echo "[entrypoint] Copied SSH bundle into $SSH_DIR"
fi

# 2️⃣ Run the actual command
#    (this is your Node app, bash script, etc.)
echo "[entrypoint] Running: $*"
"$@"
status=$?

# 3️⃣ After: sync known_hosts back to bundle to persist new host keys
if [ -d "$BUNDLE_DIR" ] && [ -f "$SSH_DIR/known_hosts" ]; then
  echo "[entrypoint] Syncing known_hosts back to bundle"
  cp "$SSH_DIR/known_hosts" "$BUNDLE_DIR/known_hosts"
fi

exit $status
