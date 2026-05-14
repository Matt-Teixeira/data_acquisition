#!/usr/bin/env bash
# Philips CT acquisition — pull phase only.
# mdb-export conversion is now split into phil_ct_convert.sh, called
# separately by exec-hhm_postprocess after a successful pull. See S7 split.
[ ! -d "$4" ] && mkdir "$4"

timeout 240 lftp -c "set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 1; set net:persist-retries 0; set cmd:fail-exit yes; set sftp:connect-program 'ssh -oConnectTimeout=10 -oServerAliveInterval=10 -oServerAliveCountMax=6 -oKexAlgorithms=diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-rsa,ssh-dss'; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/d/Data_Logger/;
mget Logger.mdb -O $4; exit"

if [ $? -ne 0 ]; then
    echo "Connection timed out" >&2
    exit 1
fi

chmod +0644 "$4/Logger.mdb"
