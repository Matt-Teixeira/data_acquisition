#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-node:16.20.2}"
DOCKER="/usr/bin/docker"

APP_DIR="/opt/apps/data_acquisition"
ENV_FILE="$APP_DIR/.env"

# Ensure image exists
if ! "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Image $IMAGE not found locally. Pulling..."
  "$DOCKER" pull "$IMAGE"
fi

# Just in case a previous run created node_modules on the host
rm -rf "$APP_DIR/node_modules" || true

# Run with a tmpfs for node_modules so nothing lands on the host.
# NOTE: this bypasses docker-compose AND the image entrypoint (no gosu, no
# log-dir repair), so the run-log mount must be wired by hand: the logger
# always writes ./utils/logger/logs inside the container, so mount the
# production log dir over that path (mirrors compose's LOG_DIR mount).
"$DOCKER" run --rm \
  --network pg_net \
  -w /usr/src/app \
  -v "$APP_DIR":/usr/src/app \
  -v /opt/run-logs/data_acquisition:/usr/src/app/utils/logger/logs \
  --env-file "$ENV_FILE" \
  --mount type=tmpfs,destination=/usr/src/app/node_modules \
  -e NPM_CONFIG_CACHE=/tmp/.npm \
  "$IMAGE" \
  bash -lc 'npm ci --omit=dev && npm run update_db_creds'

# "/home/matt-teixeira/apps/data_acquisition"
# "/opt/apps/data_acquisition"

# "$DOCKER" run --rm \
#   -w /usr/src/app \
#   -v "$APP_DIR":/usr/src/app \
#   --env-file "$ENV_FILE" \
#   --add-host=host.docker.internal:host-gateway \
#   --mount type=tmpfs,destination=/usr/src/app/node_modules \
#   -e NPM_CONFIG_CACHE=/tmp/.npm \
#   "$IMAGE" \
#   bash -lc 'npm ci --omit=dev && npm run update_db_creds'