#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/mattteixeira/app/hhm_data_acquisition"
ENV_FILE="$APP_DIR/.env"
DOCKER="/usr/bin/docker"
IMAGE="node:lts"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

exec "$DOCKER" run --rm \
  -w /usr/src/app \
  -v "$APP_DIR":/usr/src/app \
  --env-file "$ENV_FILE" \
  --add-host=host.docker.internal:host-gateway \
  -e HOST_UID="$HOST_UID" -e HOST_GID="$HOST_GID" \
  "$IMAGE" \
  bash -lc '
    set -e
    # install tools as root
    apt-get update
    apt-get install -y --no-install-recommends lftp
    # run your job
    npm ci --omit=dev
    npm run ge_ct
    # make sure host files aren’t left root-owned
    chown -R "$HOST_UID":"$HOST_GID" /usr/src/app || true
  '
