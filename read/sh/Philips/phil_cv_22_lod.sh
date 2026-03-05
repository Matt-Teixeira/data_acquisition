#!/bin/bash

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue
mkdir -p "$5/$4"
lftp -c "set sftp:connect-program 'ssh -oKexAlgorithms=diffie-hellman-group1-sha1'; set net:timeout 5; set net:reconnect-interval-base 5; set net:max-retries 2; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/c/ftproot/SaveDevData/;
mirror -c --verbose $4 $5/$4;"

RECENTFILE="$(find $5/$4 -type f -name 'Event.zip' -printf "%T+ - %p\n" | sort -n | tail -1 | awk '{print $3}')"
unzip -o "$RECENTFILE" -d $5/$4
mv "$5/$4/EventLog.txe" "$5/lod_EventLog.txe"
