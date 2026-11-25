#!/bin/bash
# Unzip a Philips CV daily export: $1 = the daily folder (files/<SME>/daily_YYYY_MM_DD), which holds Event.zip.
#
# CV-1b (hhm_rpp_philips PLAN-PHILIPS-CV-INSIGHTS.md §7.3): atomic. The zip is extracted into a temporary
# folder NEXT TO the daily folder (files/<SME>/.unzip_tmp.<daily>.<pid>), never inside it: the parser
# measures the daily folder's mtime to decide when to give up on a missing EventLog.txe, and a temp folder
# inside it would refresh that mtime on every failed attempt. Files are then moved in with mv (an atomic
# rename on the same file system), EventLog.txe LAST: the parser only ever sees a complete EventLog.txe.
# A damaged zip, or one without EventLog.txe, changes nothing in the daily folder and exits non-zero.

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

for f in "$TMP"/*; do
  [ "$(basename "$f")" = "EventLog.txe" ] && continue
  mv -f "$f" "$DIR/"
done
mv -f "$TMP/EventLog.txe" "$DIR/EventLog.txe"
echo "published: $DIR/EventLog.txe"
