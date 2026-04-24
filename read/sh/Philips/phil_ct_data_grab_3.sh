#!/usr/bin/env bash
# Philips CT acquisition — pull phase only.
# mdb-export conversion is now split into phil_ct_convert.sh, called
# separately by exec-hhm_postprocess after a successful pull. See S7 split.
#
# Historical note: this script previously scp'd to Output.mdb so the inlined
# convert block could distinguish it from siblings. The split now uses a
# uniform Logger.mdb filename across all 4 variants.
[ ! -d "$4/" ] && mkdir "$4/"

sshpass -p "$3" scp -o KexAlgorithms=diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1 -o StrictHostKeyChecking=accept-new "$2@$1:/cygdrive/d/Data_Logger/Logger.mdb" "$4/Logger.mdb"

chmod +0644 "$4/Logger.mdb"
