#!/usr/bin/env bash
source "$(dirname "$0")/_phil_mri_lib.sh"

ensure_dirs "$4" monitoring

lftp -c "set sftp:connect-program 'ssh $SSH_OPTS_MODERN'; set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 1; set net:persist-retries 0; set cmd:fail-exit yes; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/g/Site;
mget monitor_System* -O $4/monitoring;
mget monitor_cryocompressor* -O $4/monitoring;
mget monitor_magnet* -O $4/monitoring;
cd /cygdrive/g/Log/;
mget logcurrent.log -O $4"

# Does not pull any rmmu files.

## logcurrent.log /cygdrive/g/Log/

## monitoring.dat /cygdrive/g/Site/
