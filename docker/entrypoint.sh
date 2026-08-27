#!/bin/bash
set -e

# Default to svc if RUN_USER not specified
RUN_USER="${RUN_USER:-svc}"

# Dynamically set HOME based on user
export HOME="/home/$RUN_USER"

# Repair log directories while still root, BEFORE gosu drops privileges.
# Docker creates a missing bind-mount source as root:root, which makes the app
# die EACCES inside createWriteStream -- before any logging exists to say why.
# Only a root-owned directory is repaired: one somebody deliberately chowned
# (e.g. /opt/run-logs/data_acquisition as svc:docker) is left alone.
#   /workspace/utils/logger/logs -- structured run logs (utils/logger/log.js)
# (./logs is gone: the winston side-logger was retired 2026-08-27 — logger.js
#  is console-only now and writes no files.)
for dir in /workspace/utils/logger/logs; do
    mkdir -p "$dir"
    if [ "$(stat -c %u "$dir")" = "0" ]; then
        echo "entrypoint: $dir is root-owned (Docker created it) — chowning to $RUN_USER:docker"
        chown "$RUN_USER":docker "$dir" || true
        chmod 2775 "$dir" || true
    fi
done

# Execute command as the specified user
exec gosu "$RUN_USER" "$@"
