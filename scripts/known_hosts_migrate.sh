#!/usr/bin/env bash
# known_hosts_migrate.sh — push this server's verified SSH known_hosts to the
# acquisition server and append-merge it there (no target entries removed).
#
# Runs ON THE SOURCE (prod) SERVER as the prod user — no sudo; mirrors
# redis_migrate.sh. Use after a database migration seeds the target with a
# systems inventory containing hosts it has never keyed — strict checking then
# fails every cycle ("No ED25519 host key is known for <ip>"; 905 errors in
# 17 h on 2026-08-19). Policy (doc 2.1, SHARED SSH BUNDLE): never ssh-keyscan
# production endpoints — this script only moves already-verified keys.
#
# Merge semantics: APPEND-ONLY with exact-line dedupe. Every line already on
# the target survives in place (comments included); only genuinely new lines
# append at the end. A host whose key CHANGED ends up with old+new entries —
# OpenSSH accepts when any entry matches, so jobs keep working; pruning stale
# keys stays a deliberate manual task. The install is atomic (temp file in the
# same directory + mv), so consumers reading mid-cycle — data_acquisition and
# odd-jobs both mount the file :ro — only ever see a complete file.
#
# Usage:  ./known_hosts_migrate.sh [--dry-run]
#   --dry-run: validate, ship, and report what would append — no backup,
#              no install on the target.

set -euo pipefail

SRC="$HOME/.ssh/known_hosts"               # this (source) server's verified file —
                                           # the legacy prod server keeps it in the
                                           # user's ~/.ssh, NOT the /opt/resources/ssh
                                           # bundle layout (that's a docker-server thing)
REMOTE="data-acqu-vm-staging"              # ssh alias in ~/.ssh/config
TARGET="/opt/resources/ssh/known_hosts"    # path on the remote
BACKUP_DIR="/opt/resources/backups"        # on the remote
STAMP="$(date +%Y%m%d-%H%M%S)"
SHIPPED="known_hosts.prod-${STAMP}"        # lands in the remote user's home

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

echo "[1/5] Validate $SRC"
CLEAN="$(mktemp)"
trap 'rm -f "$CLEAN"' EXIT
tr -d '\r' < "$SRC" > "$CLEAN"
# Every content line: [@marker] hosts keytype key...  Abort on anything else —
# a truncated or corrupted file must not merge.
awk '
  /^[[:space:]]*(#|$)/ { next }
  {
    type = ($1 ~ /^@/) ? $3 : $2
    min  = ($1 ~ /^@/) ? 4 : 3
    if (NF < min || type !~ /^(ssh-(ed25519|rsa|dss)|ecdsa-sha2-|sk-)/) {
      printf "FATAL: malformed line %d: %s\n", NR, $0 > "/dev/stderr"
      exit 1
    }
  }
' "$CLEAN"
KEYS=$(awk '!/^[[:space:]]*(#|$)/ { n++ } END { print n + 0 }' "$CLEAN")
echo "      OK  $KEYS key lines"

echo "[2/5] Ship to $REMOTE:~/$SHIPPED"
scp -q "$CLEAN" "$REMOTE:$SHIPPED"
LOCAL_MD5="$(md5sum "$CLEAN" | awk '{print $1}')"
REMOTE_MD5="$(ssh "$REMOTE" "md5sum ~/$SHIPPED" | awk '{print $1}')"
if [ "$LOCAL_MD5" != "$REMOTE_MD5" ]; then
  echo "      FAIL  checksum mismatch  local=$LOCAL_MD5  remote=$REMOTE_MD5" >&2
  exit 1
fi
echo "      OK  md5 match: $LOCAL_MD5"

echo "[3/5] Remote backup + [4/5] append-only merge (dry-run=$DRY_RUN)"
ssh "$REMOTE" bash -s -- "$TARGET" "$BACKUP_DIR" "$SHIPPED" "$STAMP" "$DRY_RUN" <<'REMOTE_EOF'
set -euo pipefail
TARGET="$1"; BACKUP_DIR="$2"; SHIPPED_PATH="$HOME/$3"; STAMP="$4"; DRY="$5"

before=$(wc -l < "$TARGET")
TMP="$(mktemp "$(dirname "$TARGET")/.kh.import.XXXXXX")"
trap 'rm -f "$TMP"' EXIT
awk '!seen[$0]++' "$TARGET" "$SHIPPED_PATH" > "$TMP"
after=$(wc -l < "$TMP")
appended=$((after - before))
echo "      target: $before lines; new from source: $appended; merged: $after"

if [ "$DRY" = "1" ]; then
  echo "      DRY RUN — lines that would append (first 20):"
  awk 'NR==FNR { seen[$0]=1; next } !seen[$0]' "$TARGET" "$SHIPPED_PATH" | head -20
  exit 0
fi

[ -s "$TMP" ] || { echo "FATAL: merged file is empty — aborting before install" >&2; exit 1; }
cp -p "$TARGET" "$BACKUP_DIR/known_hosts.pre-import-$STAMP"
chmod 644 "$TMP"
mv "$TMP" "$TARGET"
trap - EXIT
post=$(wc -l < "$TARGET")
[ "$post" -eq "$after" ] || { echo "FATAL: post-install line count $post != expected $after" >&2; exit 1; }
echo "      installed. backup: $BACKUP_DIR/known_hosts.pre-import-$STAMP"
REMOTE_EOF

echo "[5/5] Done."
if [ "$DRY_RUN" = "1" ]; then
  echo "      Dry run only — nothing installed. Shipped copy left at $REMOTE:~/$SHIPPED"
else
  cat <<EOF
      Verify on $REMOTE:
        ssh-keygen -F <new-host-ip> -f $TARGET        # must print a match
        (then: zero '%host key%' err_msg rows in util.app_run_logs on the
         next :00/:30 cron burst)
      Rollback on $REMOTE (temp+mv — works for any docker-group member):
        cp $BACKUP_DIR/known_hosts.pre-import-$STAMP /opt/resources/ssh/.kh.rb \\
          && chmod 644 /opt/resources/ssh/.kh.rb \\
          && mv /opt/resources/ssh/.kh.rb $TARGET
EOF
fi
