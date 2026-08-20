#!/usr/bin/env bash
#
# Repeatable Redis RDB export + transfer to staging.
# Runs entirely as the prod user — no sudo, no /tmp, no root-owned artifacts.
#
# Usage:  ./redis_migrate.sh
#
set -euo pipefail

CONTAINER="redis-PROD"
REMOTE="data-acqu-vm-staging"     # ssh alias in ~/.ssh/config
WORKDIR="$HOME/redis_dumps"       # prod-owned; overwrite never blocked
REMOTE_DIR="redis_dumps"          # relative to remote user's home
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$WORKDIR/${CONTAINER}-dump-${STAMP}.rdb"

mkdir -p "$WORKDIR"

echo "[1/5] SAVE (synchronous snapshot inside container)"
docker exec "$CONTAINER" redis-cli SAVE

echo "[2/5] Locate the RDB file inside the container"
DIR="$(docker exec "$CONTAINER" redis-cli CONFIG GET dir       | sed -n 2p | tr -d '\r')"
DBFILE="$(docker exec "$CONTAINER" redis-cli CONFIG GET dbfilename | sed -n 2p | tr -d '\r')"
SRC="${DIR%/}/$DBFILE"
echo "      -> $SRC"

echo "[3/5] Copy out of the container to $OUT"
docker cp "$CONTAINER:$SRC" "$OUT"
ls -lh "$OUT"

echo "[4/5] Transfer to $REMOTE:~/$REMOTE_DIR/"
ssh "$REMOTE" "mkdir -p ~/$REMOTE_DIR"
scp -q "$OUT" "$REMOTE:$REMOTE_DIR/"

echo "[5/5] Verify checksum end-to-end"
LOCAL_MD5="$(md5sum "$OUT" | awk '{print $1}')"
REMOTE_MD5="$(ssh "$REMOTE" "md5sum ~/$REMOTE_DIR/$(basename "$OUT")" | awk '{print $1}')"
if [ "$LOCAL_MD5" = "$REMOTE_MD5" ]; then
  echo "      OK  md5 match: $LOCAL_MD5"
  echo
  echo "DONE. On $REMOTE the dump is at: ~/$REMOTE_DIR/$(basename "$OUT")"
else
  echo "      FAIL  checksum mismatch  local=$LOCAL_MD5  remote=$REMOTE_MD5" >&2
  exit 1
fi