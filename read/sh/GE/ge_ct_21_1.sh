#!/bin/bash

[ ! -d "$4" ] && mkdir $4
lftp -c "set net:timeout 5; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 2; set xfer:clobber true; open ftp://$2:$3@$1; 
cd /usr/g/service/log/; 
mget gesys*.log -O $4"