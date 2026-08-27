#!/usr/bin/env bash
# prune-run-logs.sh — run-log lifecycle: daily bundling + retention.
# (FLEET-TODO 2b, approved 2026-08-27; layout standard in
#  docs/stamp-compress-refactor-proposal.md)
#
# Three stages, all scoped to per-run log files ONLY — the narrow pattern
# '*-log.*' is the whole selection rule: cron.<job>.out captures, append-mode
# *.log files and subdirs never match, so naming discipline and bundling are
# the same rule.
#
#   1) BUNDLE (central): files in /opt/run-logs/<app>/ older than
#      BUNDLE_AFTER_DAYS are tar'd per mtime-day into
#      /opt/run-logs/<app>/archive/YYYY-MM-DD.tar.gz (verified readable
#      before the originals are deleted). A day whose bundle already exists
#      is skipped — late stragglers stay loose until the safety net.
#   2) PRUNE loose (safety net): central loose files > CENTRAL_DAYS and
#      repo-local dev-mode logs > REPO_DAYS are deleted (pre-bundling
#      behavior, unchanged).
#   3) PRUNE bundles: archive/*.tar.gz older than BUNDLE_RETENTION_DAYS.
#
# ~15x compression measured on real run logs, so 180-day bundle retention
# costs about what 12 loose days used to.
#
# --dry-run prints what each stage WOULD do and touches nothing.
# Safe to run any time (flock'd; skips if an instance is already running).
# Summary appends to /opt/run-logs/data_acquisition/prune.log (moved from
# the /opt/run-logs root 2026-08-27 — nothing loose lives at root).

set -euo pipefail

REPO_DAYS=14
CENTRAL_DAYS=30
BUNDLE_AFTER_DAYS=2
BUNDLE_RETENTION_DAYS=180
SUMMARY=/opt/run-logs/data_acquisition/prune.log

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

# Single writer: a slow previous run means skip, never overlap.
exec 9>/tmp/prune-run-logs.lock
flock -n 9 || { echo "prune-run-logs: already running, skipping"; exit 0; }

deleted=0
freed_kb=0
bundled_files=0
bundled_days=0
expired_bundles=0

prune() {
  local dir=$1 pattern=$2 days=$3
  [ -d "$dir" ] || return 0
  local n kb
  n=$(find "$dir" -maxdepth 1 -type f -name "$pattern" -mtime +"$days" | wc -l)
  if [ "$n" -gt 0 ]; then
    kb=$(find "$dir" -maxdepth 1 -type f -name "$pattern" -mtime +"$days" -print0 \
         | du -ck --files0-from=- 2>/dev/null | tail -1 | cut -f1)
    if [ "$DRY" = 1 ]; then
      echo "DRY: would prune $n loose files (${kb} KB) from $dir"
    else
      find "$dir" -maxdepth 1 -type f -name "$pattern" -mtime +"$days" -delete
    fi
    deleted=$((deleted + n))
    freed_kb=$((freed_kb + kb))
  fi
}

bundle() {
  local dir=$1
  [ -d "$dir" ] || return 0
  local day files listfile tarball
  # Days present among bundle-eligible files (mtime strictly older than
  # BUNDLE_AFTER_DAYS-1 => at least BUNDLE_AFTER_DAYS*24h old).
  for day in $(find "$dir" -maxdepth 1 -type f -name '*-log.*' \
                 -mtime +"$((BUNDLE_AFTER_DAYS - 1))" -printf '%TY-%Tm-%Td\n' \
               | sort -u); do
    tarball="$dir/archive/$day.tar.gz"
    listfile=$(mktemp)
    find "$dir" -maxdepth 1 -type f -name '*-log.*' \
         -newermt "$day 00:00:00" ! -newermt "$day 23:59:59.999999" \
         -printf '%f\n' > "$listfile"
    local n; n=$(wc -l < "$listfile")
    if [ "$n" -eq 0 ]; then rm -f "$listfile"; continue; fi
    if [ -e "$tarball" ]; then
      # Stragglers for an already-bundled day stay loose; the safety net
      # (CENTRAL_DAYS) eventually removes them. Never rewrite a bundle.
      [ "$DRY" = 1 ] && echo "DRY: $tarball exists — skipping $n straggler(s) in $dir"
      rm -f "$listfile"; continue
    fi
    if [ "$DRY" = 1 ]; then
      echo "DRY: would bundle $n files from $dir into $tarball"
      rm -f "$listfile"
      bundled_files=$((bundled_files + n)); bundled_days=$((bundled_days + 1))
      continue
    fi
    mkdir -p "$dir/archive"
    if tar -czf "$tarball" -C "$dir" -T "$listfile" \
       && tar -tzf "$tarball" > /dev/null 2>&1; then
      # Delete exactly what was bundled, by name.
      (cd "$dir" && xargs -d '\n' rm -f -- < "$listfile")
      bundled_files=$((bundled_files + n)); bundled_days=$((bundled_days + 1))
    else
      echo "WARN: bundle failed for $tarball — originals kept" >&2
      rm -f "$tarball"
    fi
    rm -f "$listfile"
  done
}

# --- 1. bundle central per-run logs ------------------------------------------
for d in /opt/run-logs/*/; do
  bundle "$d"
done

# --- 2. safety-net prune of loose files --------------------------------------
for d in /opt/apps/*/utils/logger; do
  prune "$d" '*-log.*.json' "$REPO_DAYS"
done
for d in /opt/run-logs/*/; do
  prune "$d" '*-log.*' "$CENTRAL_DAYS"
done

# --- 3. expire old bundles ----------------------------------------------------
for d in /opt/run-logs/*/archive; do
  [ -d "$d" ] || continue
  n=$(find "$d" -maxdepth 1 -type f -name '*.tar.gz' -mtime +"$BUNDLE_RETENTION_DAYS" | wc -l)
  if [ "$n" -gt 0 ]; then
    if [ "$DRY" = 1 ]; then
      echo "DRY: would expire $n bundle(s) from $d"
    else
      find "$d" -maxdepth 1 -type f -name '*.tar.gz' -mtime +"$BUNDLE_RETENTION_DAYS" -delete
    fi
    expired_bundles=$((expired_bundles + n))
  fi
done

msg="$(date -Is) bundled ${bundled_files} files into ${bundled_days} day-bundles, pruned ${deleted} loose files ($((freed_kb / 1024)) MB), expired ${expired_bundles} bundles"
if [ "$DRY" = 1 ]; then
  echo "DRY: $msg"
else
  echo "$msg" | tee -a "$SUMMARY"
fi
