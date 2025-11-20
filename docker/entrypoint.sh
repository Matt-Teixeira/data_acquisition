#!/usr/bin/env bash
set -e

# Copy SSH bundle into this user's home as ~/.ssh
if [ -d /opt/ssh_bundles/data_acquisition ]; then
  mkdir -p "${HOME}/.ssh"
  cp /opt/ssh_bundles/data_acquisition/* "${HOME}/.ssh"/
  chmod 700 "${HOME}/.ssh"
  chmod 600 "${HOME}/.ssh"/mmb_google_deb || true
fi

# Hand off to whatever command was given (node, bash, etc.)
exec "$@"