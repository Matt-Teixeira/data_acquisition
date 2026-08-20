#!/usr/bin/env bash
# cron-restore.sh — reinstall the crontab saved by scripts/cron-suspend.sh
# from cron-bk/crontab.bak.
#
# Replaces whatever crontab is currently live (normally none, since suspend
# cleared it). The backup file is left in place after restoring.

set -euo pipefail

BACKUP="$(cd "$(dirname "$0")/.." && pwd)/cron-bk/crontab.bak"

if [ ! -s "$BACKUP" ]; then
  echo "ERROR: ${BACKUP} is missing or empty — nothing to restore." >&2
  exit 1
fi

crontab "$BACKUP"

jobs=$(grep -c -v -e '^\s*#' -e '^\s*$' "$BACKUP" || true)
echo "Restored crontab from ${BACKUP} (${jobs} active job(s) now live)."
