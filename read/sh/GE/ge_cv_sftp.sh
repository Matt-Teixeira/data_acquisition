#!/bin/bash
[ ! -d "$4" ] && mkdir $4

timeout 240 lftp -c "set sftp:connect-program 'ssh -oKexAlgorithms=diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1 -oConnectTimeout=10 -oServerAliveInterval=10 -oServerAliveCountMax=6'; set net:timeout 10; set ftp:ssl-allow off; set net:persist-retries 0; set net:reconnect-interval-base 5; set net:max-retries 1; set xfer:clobber true; open sftp://$2:$3@$1;
cd /C/Program\ Files/GE\ Medical\ Systems/DL/Log/;
mget sysError.log -O $4"
