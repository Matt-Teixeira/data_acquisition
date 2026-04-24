#!/usr/bin/env bash
source "$(dirname "$0")/_phil_mri_lib.sh"

# Get current year and month to get rmmu files
# Ex: rmmu202307*
current_year_month=$(date +%Y%m)

ensure_dirs "$4" monitoring rmmu_short rmmu_long rmmu_magnet

lftp -c "set sftp:connect-program 'ssh $SSH_OPTS_MODERN'; set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 1; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/g/monitoring;
mget monitor_System* -O $4/monitoring;
mget monitor_cryocompressor* -O $4/monitoring;
mget monitor_magnet* -O $4/monitoring;
cd /cygdrive/g/Log/;
mget logcurrent.log -O $4;
mget rmmu_short_cryogenic$current_year_month* -O $4/rmmu_short;
mget rmmu_magnet$current_year_month* -O $4/rmmu_magnet;
mget rmmu_long_cryogenic$current_year_month* -O $4/rmmu_long;
cd /cygdrive/g/stt/;
mget STT_MAGNET.txt -O $4"

## logcurrent.log  /cygdrive/g/Log/
## monitoring.dat  /cygdrive/g/monitoring
## STT_MAGNET.txt  /cygdrive/g/stt/
