#!/bin/bash
files=$(lftp -c "set sftp:connect-program 'ssh -oKexAlgorithms=diffie-hellman-group1-sha1'; set net:timeout 5; set net:reconnect-interval-base 5; set net:max-retries 2; open sftp://$2:$3@$1; cd /cygdrive/c/ftproot/SaveDevData; ls")
echo $files
