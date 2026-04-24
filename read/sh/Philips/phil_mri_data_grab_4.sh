[ ! -d "$4" ] && mkdir $4
[ ! -d "$4/monitoring" ] && mkdir $4/monitoring

lftp -c "set sftp:connect-program 'ssh -oConnectTimeout=15 -oKexAlgorithms=+diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-rsa,ssh-dss -oPubkeyAcceptedAlgorithms=+ssh-rsa -oStrictHostKeyChecking=accept-new'; set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 1; set xfer:clobber true; open sftp://$2:$3@$1; 
cd /cygdrive/g/Site; 
mget monitor_System* -O $4/monitoring; 
mget monitor_cryocompressor* -O $4/monitoring; 
mget monitor_magnet* -O $4/monitoring; 
cd /cygdrive/g/Log/; 
mget logcurrent.log -O $4; 
cd /cygdrive/g/stt/; 
mget STT_MAGNET.txt -O $4"

# Does not pull any rmmu files.

## logcurrent.log /cygdrive/g/Log/

## monitoring.dat /cygdrive/g/Site

## STT_MAGNET.txt /cygdrive/g/stt/