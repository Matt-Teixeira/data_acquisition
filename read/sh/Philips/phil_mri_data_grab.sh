[ ! -d "$4" ] && mkdir $4
# { PHILIPS MRI
# ----------------------------------------------------------------------------------------
# - name: Philips MR (SCP/All)
mkdir -p $4/rmmu_long
mkdir -p $4/rmmu_short
mkdir -p $4/rmmu_magnet
mkdir -p $4/monitoring
# - name: Philips MR (SCP, default credentials)
timeout 120 sshpass -p $3 scp -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new $2@$1:/cygdrive/g/Log/logcurrent.log $4
timeout 120 sshpass -p $3 scp -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new $2@$1:/cygdrive/g/Log/rmmu* $4/rmmu_long
timeout 120 sshpass -p $3 scp -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new $2@$1:/cygdrive/g/Site/rmmu* $4/rmmu_long
timeout 120 sshpass -p $3 scp -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new $2@$1:/cygdrive/g/Site/monitor_* $4/monitoring
timeout 120 sshpass -p $3 scp -o ConnectTimeout=15 -o StrictHostKeyChecking=accept-new $2@$1:/cygdrive/g/monitoring/monitor_* $4/monitoring
