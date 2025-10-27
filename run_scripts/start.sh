#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/mattteixeira/app/hhm_data_acquisition"
ENV_FILE="$APP_DIR/.env"
DOCKER="/usr/bin/docker"
#TASK="${1:?npm script name required}"

exec "$DOCKER" run --rm \
  -w /usr/src/app \
  -v "$APP_DIR":/usr/src/app \
  --env-file "$ENV_FILE" \
  --add-host=host.docker.internal:host-gateway \
  node:lts \
  bash -lc "npm ci --omit=dev && npm run start"