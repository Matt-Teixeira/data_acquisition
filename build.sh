#!/usr/bin/env bash
# Build for data_acquisition: deps + image. Fleet paradigm (docs/migration_CLAUDE.md Part 1).
#
#   1. npm install at the project root, run inside a throwaway node:lts container
#      as the CALLING host user, so node_modules lands IN-TREE with ownership
#      matching the host (no shared cache dir — each copy owns its deps).
#   2. docker compose build app_tools. All build args (USER_ID, DOCKER_GID,
#      UID_0/1/2) are interpolated by compose from .env — host identity lives
#      only there, and the Dockerfile ARGs have no defaults on purpose, so a
#      missing value fails the build instead of baking a wrong uid.
set -euo pipefail
cd "$(dirname "$0")"

# Load .env so the USER_ID guard below sees what compose will interpolate.
set -a
[ -f .env ] && . ./.env
set +a

: "${USER_ID:?USER_ID is not set — add it to .env (drives the image tag data-acqu:\$USER_ID)}"

echo "==> npm install (in-tree, as $(id -un))"
docker run --rm \
  -v "$(pwd)":/workspace -w /workspace \
  --user "$(id -u):$(id -g)" \
  -e NPM_CONFIG_CACHE=/tmp/.npm \
  node:lts npm install

echo "==> docker compose build app_tools (image data-acqu:${USER_ID})"
docker compose build app_tools

echo "==> done: data-acqu:${USER_ID}"
