#!/bin/bash

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue
[ ! -d "$5" ] && mkdir $5
[ ! -d "$5/$4" ] && mkdir $5/$4
lftp -c "set sftp:connect-program 'ssh -oKexAlgorithms=+diffie-hellman-group1-sha1 -oHostKeyAlgorithms=+ssh-rsa,ssh-dss -oPubkeyAcceptedAlgorithms=+ssh-rsa -oStrictHostKeyChecking=accept-new'; set net:timeout 5; set net:reconnect-interval-base 5; set net:max-retries 2; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/c/ftproot/SaveDevData/$4;
mget Event.zip -O $5/$4;
quit"
