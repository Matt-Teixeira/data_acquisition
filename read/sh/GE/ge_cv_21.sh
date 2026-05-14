#!/bin/bash
[ ! -d "$4" ] && mkdir $4

timeout 240 lftp -c "
set net:timeout 10;
set net:persist-retries 0;
set net:reconnect-interval-base 5;
set net:reconnect-interval-max 5;
set net:max-retries 1;
set ftp:ssl-allow off;
set xfer:clobber true;
open ftp://$2:$3@$1;
cd /C/Program\ Files/GE\ Medical\ Systems/DL/Log/;
mget sysError.log -O $4"