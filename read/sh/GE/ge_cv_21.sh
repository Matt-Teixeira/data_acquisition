#!/bin/bash
[ ! -d "$4" ] && mkdir $4

lftp -c "
set net:timeout 20; 
set net:reconnect-interval-base 5;
set net:reconnect-interval-max 5; 
set net:max-retries 2; 
set ftp:ssl-allow off; 
set xfer:clobber true; 
open ftp://$2:$3@$1; 
cd /C/Program\ Files/GE\ Medical\ Systems/DL/Log/; 
mget sysError.log -O $4"

# set net:timeout 20; → timeout for each connection attempt (DNS, TCP, login, etc.)
# set net:reconnect-interval-base 5; → wait 5 seconds between retries
# set net:reconnect-interval-max 5; → cap retry delay at 5 seconds
# set net:max-retries 2; → retry only twice