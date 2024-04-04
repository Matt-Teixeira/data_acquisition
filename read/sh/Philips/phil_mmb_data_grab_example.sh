#!/bin/bash
chmod 644 ./host_logfiles/*.*
YEAR=$(date | awk '{print $4}')
CURRENT_YEAR_MONTH=$(date +%Y%m)

sshpass -p manager sftp -o HostkeyAlgorithms=ssh-rsa Remote@10.20.30.11 <<EOF

lcd  /home/avante/host_logfiles

cd /cygdrive/g/Log
get logcurrent.log

cd /cygdrive/g/Site
get rmmu$CURRENT_YEAR_MONTH*
get rmmu_short_cryogenic$CURRENT_YEAR_MONTH*
get rmmu_magnet$CURRENT_YEAR_MONTH*

get monitor_System_HumTechRoom*
get monitor_System_TempTechRoom*
get monitor_cryocompressor_cerr*
get monitor_cryocompressor_palm*
get monitor_cryocompressor_talm*
get monitor_cryocompressor_time_status*
get monitor_magnet_helium_level_value*
get monitor_magnet_lt_boiloff*
get monitor_magnet_quench*
get monitor_magnet_pressure*

cd /cygdrive/g/stt
get STT_MAGNET.txt
EOF