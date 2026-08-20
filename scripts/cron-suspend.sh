#!/usr/bin/env bash
# cron-suspend.sh — back up the current user's live crontab to cron-bk/crontab.bak,
# then clear the live crontab entirely.
#
# Use instead of hand-commenting jobs when the whole schedule needs to go quiet
# (maintenance, migrations, etc). Restore with scripts/cron-restore.sh.
#
# Single backup file, overwritten each run. Running this twice in a row is safe:
# after the first run there is no crontab, so `crontab -l` fails and the script
# aborts before it can overwrite the good backup with an empty one.

set -euo pipefail

BACKUP="$(cd "$(dirname "$0")/.." && pwd)/cron-bk/crontab.bak"

current=$(crontab -l)   # aborts here if no crontab exists (nothing to suspend)

printf '%s\n' "$current" > "$BACKUP"
crontab -r

jobs=$(printf '%s\n' "$current" | grep -c -v -e '^\s*#' -e '^\s*$' || true)
echo "Saved ${jobs} active job(s) to ${BACKUP} and cleared the live crontab."
echo "Restore with: scripts/cron-restore.sh"
