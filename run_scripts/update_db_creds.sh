#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-node:16.20.2}"
DOCKER="/usr/bin/docker"

APP_DIR="/home/mattteixeira/apps/data_acquisition"
ENV_FILE="$APP_DIR/.env"

# Ensure image exists
if ! "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image $IMAGE not found locally. Pulling..."
  "$DOCKER" pull "$IMAGE"
fi

# Just in case a previous run created node_modules on the host
rm -rf "$APP_DIR/node_modules" || true

# Run with a tmpfs for node_modules so nothing lands on the host
"$DOCKER" run --rm \
  --network redis-admin_redis_net \
  -w /usr/src/app \
  -v "$APP_DIR":/usr/src/app \
  --env-file "$ENV_FILE" \
  --mount type=tmpfs,destination=/usr/src/app/node_modules \
  -e NPM_CONFIG_CACHE=/tmp/.npm \
  "$IMAGE" \
  bash -lc 'npm ci --omit=dev && npm run update_db_creds'


# "$DOCKER" run --rm \
#   -w /usr/src/app \
#   -v "$APP_DIR":/usr/src/app \
#   --env-file "$ENV_FILE" \
#   --add-host=host.docker.internal:host-gateway \
#   --mount type=tmpfs,destination=/usr/src/app/node_modules \
#   -e NPM_CONFIG_CACHE=/tmp/.npm \
#   "$IMAGE" \
#   bash -lc 'npm ci --omit=dev && npm run update_db_creds'