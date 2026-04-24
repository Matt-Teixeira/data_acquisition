# Get current year and month to get rmmu files
# Ex: rmmu202307*
current_year_month=$(date +%Y%m)

[ ! -d "$4" ] && mkdir $4
[ ! -d "$4/monitoring" ] && mkdir $4/monitoring
[ ! -d "$4/rmmu" ] && mkdir $4/rmmu

lftp -c "set sftp:connect-program 'ssh -oConnectTimeout=15 -oKexAlgorithms=diffie-hellman-group14-sha1'; set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 2; set net:max-retries 1; set xfer:clobber true; open sftp://$2:$3@$1; 
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