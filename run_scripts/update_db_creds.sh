#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-node:16.20.2}"
DOCKER="/usr/bin/docker"

APP_DIR="/home/mattteixeira/apps/data_acquisition"
ENV_FILE="$APP_DIR/.env"

# 1) Ensure the image exists locally (pull if missing)
if ! "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image $IMAGE not found locally. Pulling..."
  "$DOCKER" pull "$IMAGE"
fi

# 2) Run
exec "$DOCKER" run --rm \
  -w /usr/src/app \
  -v "$APP_DIR":/usr/src/app \
  --env-file "$ENV_FILE" \
  --add-host=host.docker.internal:host-gateway \
  "$IMAGE" \
  bash -lc 'npm ci --omit=dev && npm run update_db_creds'
