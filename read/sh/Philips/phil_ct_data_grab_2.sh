#!/usr/bin/env bash
# Philips CT acquisition — pull phase only.
# mdb-export conversion is now split into phil_ct_convert.sh, called
# separately by exec-hhm_postprocess after a successful pull. See S7 split.
[ ! -d "$4" ] && mkdir "$4"

cd "$4"
lftp -c "set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 2; set sftp:connect-program 'ssh -oKexAlgorithms=diffie-hellman-group14-sha1'; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/d/Data_Logger;
mget Logger.mdb;"

if [ $? -ne 0 ]; then
    echo "Connection timed out" >&2
    exit 1
fi
