#!/bin/bash
# Unzip a Philips CV daily export: $1 = the daily folder (files/<SME>/daily_YYYY_MM_DD), which holds Event.zip.
#
# CV-1b (hhm_rpp_philips PLAN-PHILIPS-CV-INSIGHTS.md §7.3, §7.12):
# - The zip is extracted into a temporary folder NEXT TO the daily folder (files/<SME>/.unzip_tmp.<daily>.<pid>),
#   never inside it. The parser measures the daily folder's mtime to decide when to give up on a missing
#   EventLog.txe, so nothing may touch the daily folder until EventLog.txe is published.
# - Only known entries are published (an allowlist; 9,940 real zips hold exactly these, review CV1B-COLLECTOR
#   finding 3): EventLog.txe (required), then EventLogSystem.txe and EventLogSecurity.txe if present. Anything
#   else in the zip is dropped with the temp folder.
# - EventLog.txe is published FIRST, with mv (an atomic rename on the same file system). If that fails, the
#   daily folder is untouched (mtime unchanged) and the exit is non-zero. Once it is published the sweep
#   never selects the folder again, so a companion that fails to move afterwards can't reset the parser's
#   clock on every retry (review finding 1): it is reported on stderr and the exit stays 0.

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue

DIR="${1%/}"
ZIP="$DIR/Event.zip"
[ -n "$DIR" ] && [ "$DIR" != "/" ] && [ -d "$DIR" ] || { echo "parse_event_zip: not a folder: '$DIR'" >&2; exit 2; }
[ -f "$ZIP" ] || { echo "parse_event_zip: no Event.zip in $DIR" >&2; exit 2; }

TMP="$(dirname "$DIR")/.unzip_tmp.$(basename "$DIR").$$"
rm -rf "$TMP"
mkdir "$TMP"
trap 'rm -rf "$TMP"' EXIT

unzip -o "$ZIP" -d "$TMP"
[ -f "$TMP/EventLog.txe" ] || { echo "parse_event_zip: no EventLog.txe in $ZIP" >&2; exit 3; }

mv -f "$TMP/EventLog.txe" "$DIR/EventLog.txe"
echo "published: $DIR/EventLog.txe"

for f in EventLogSystem.txe EventLogSecurity.txe; do
  [ -f "$TMP/$f" ] || continue
  mv -f "$TMP/$f" "$DIR/$f" || echo "parse_event_zip: $f not published (EventLog.txe is)" >&2
done
exit 0
