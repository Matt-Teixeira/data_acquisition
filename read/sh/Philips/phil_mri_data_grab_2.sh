#!/usr/bin/env bash
source "$(dirname "$0")/_phil_mri_lib.sh"

# Get current year and month to get rmmu files
# Ex: rmmu202307*
current_year_month=$(date +%Y%m)

ensure_dirs "$4" monitoring rmmu

lftp -c "set sftp:connect-program 'ssh $SSH_OPTS_MODERN'; set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 2; set net:max-retries 1; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/g/Site;
mget monitor_System* -O $4/monitoring;
mget monitor_cryocompressor* -O $4/monitoring;
mget monitor_magnet* -O $4/monitoring;
mget rmmu$current_year_month* -O $4/rmmu;
cd /cygdrive/g/Log/;
mget logcurrent.log -O $4"

## logcurrent.log  /cygdrive/g/Log/

## rmmu            /cygdrive/g/Site/

## monitoring.dat /cygdrive/g/Site/
