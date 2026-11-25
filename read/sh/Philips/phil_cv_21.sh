#!/bin/bash
# Fetch a Philips CV daily export: SaveDevData/<daily>/Event.zip -> $5/<daily>/Event.zip.
# Args: $1 host, $2 user, $3 password, $4 daily folder name, $5 local system folder.
#
# CV-1b (hhm_rpp_philips PLAN-PHILIPS-CV-INSIGHTS.md §7.12, review CV1B-COLLECTOR finding 2):
# the download goes to a private staging folder NEXT TO the daily folder ($5/.incoming.<daily>.<pid>), and
# only a finished, non-empty download is moved in as Event.zip (an atomic rename). A failed or cut transfer
# leaves nothing at $5/<daily>/Event.zip (a valid-looking prefix can't be unzipped as the export), never
# touches the daily folder (whose mtime the parser's 48 h rule reads), and is fetched again by a later run.
# The lftp commands, the exit status and stderr on failure are as before, so read/exec-phil_cv_data_grab.js
# classifies the outcome as before. The daily folder is still created first, as before.

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue
[ ! -d "$5" ] && mkdir $5
[ ! -d "$5/$4" ] && mkdir $5/$4
INC="$5/.incoming.$4.$$"
rm -rf "$INC"
mkdir "$INC"
trap 'rm -rf "$INC"' EXIT
lftp -c "set net:timeout 5; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 2; set xfer:clobber true; open ftp://$2:$3@$1; 
cd /SaveDevData/$4; 
mget Event.zip -O $INC;
quit"

[ -s "$INC/Event.zip" ] || { echo "phil_cv: downloaded Event.zip is missing or empty; nothing published" >&2; exit 1; }
mv -f "$INC/Event.zip" "$5/$4/Event.zip"

# RECENTFILE="$(find $5/*/* -type f -name 'Event.zip' -printf "%T+ - %p\n" | sort -n | tail -1 | awk '{print $3}')"
# unzip -o "$RECENTFILE" -d $5

## --{ Get Trace Dir
# cd /SaveDevData/$4;
# mirror -c --verbose Trace $5/$4/Trace;
