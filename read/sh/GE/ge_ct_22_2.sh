#!/bin/bash
[ ! -d "$4" ] && mkdir $4

lftp -c "set sftp:connect-program 'ssh -o KexAlgorithms=diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha256'; 
set net:timeout 10; 
set ftp:ssl-allow off;
set net:persist-retries 0;
set net:reconnect-interval-base 5; 
set net:max-retries 1; 
set xfer:clobber true; 
open sftp://$2:$3@$1; 
cd /usr/g/service/log; 
mget gesys*.log -O $4; 
cd /usr/g/service/state;
mget ssw.dastools.hist* -O $4; 
mget ssw.calreport.hist -O $4;
mget ssw.GenCal.hist -O $4;
mget ssw.GenCal.hist -O $4;
mget ssw.tube_align.hist -O $4;
mget air_bubble_detection_result.csv -O $4;
mget TubeSpits.csv -O $4;
mget image_analysis.csv -O $4;
mget ssw.srv_activity.ref -O $4;
mget ssw.diagSession.hist -O $4;
cd /var/log;
mget messages* -O $4;"
