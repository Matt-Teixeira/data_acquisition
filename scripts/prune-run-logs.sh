#!/usr/bin/env bash
# prune-run-logs.sh — delete aged per-run JSON log files.
#
# Two targets, two retentions:
#   1) Repo-local dev-mode logs: /opt/apps/<app>/utils/logger/*-log.*.json
#      (written when RUN_ENV=dev; ~140 MB/day fleet-wide)     -> keep 14 days
#   2) Central run logs:         /opt/run-logs/<app>/*-log.*  -> keep 30 days
#
# Patterns are deliberately narrow (*-log.*.json / *-log.*) so logger source
# files (log.js, enums.js) in the same directory are never matched.
# Safe to run any time; intended from cron nightly. Summary appends to
# /opt/run-logs/prune.log.

set -euo pipefail

REPO_DAYS=14
CENTRAL_DAYS=30
SUMMARY=/opt/run-logs/prune.log

deleted=0
freed_kb=0

prune() {
  local dir=$1 pattern=$2 days=$3
  [ -d "$dir" ] || return 0
  local n kb
  n=$(find "$dir" -maxdepth 1 -type f -name "$pattern" -mtime +"$days" | wc -l)
  if [ "$n" -gt 0 ]; then
    kb=$(find "$dir" -maxdepth 1 -type f -name "$pattern" -mtime +"$days" -print0 \
         | du -ck --files0-from=- 2>/dev/null | tail -1 | cut -f1)
    find "$dir" -maxdepth 1 -type f -name "$pattern" -mtime +"$days" -delete
    deleted=$((deleted + n))
    freed_kb=$((freed_kb + kb))
  fi
}

for d in /opt/apps/*/utils/logger; do
  prune "$d" '*-log.*.json' "$REPO_DAYS"
done

for d in /opt/run-logs/*/; do
  prune "$d" '*-log.*' "$CENTRAL_DAYS"
done

msg="$(date -Is) pruned ${deleted} files, freed $((freed_kb / 1024)) MB"
echo "$msg" | tee -a "$SUMMARY"
