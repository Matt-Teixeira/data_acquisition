#!/bin/bash

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue
[ ! -d "$5" ] && mkdir $5
[ ! -d "$5/$4" ] && mkdir $5/$4
timeout 290 lftp -c "set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 1; set net:persist-retries 0; set cmd:fail-exit yes; set xfer:clobber true; open ftp://$2:$3@$1;
cd /SaveDevData;
mirror -c --verbose --max-errors=1 $4 $5/$4;"

RECENTFILE="$(find $5/$4 -type f -name 'Event.zip' -printf "%T+ - %p\n" | sort -n | tail -1 | awk '{print $3}')"
unzip -o "$RECENTFILE" -d $5/$4
mv "$5/$4/EventLog.txe" "$5/lod_EventLog.txe"