#!/bin/bash
files=$(timeout 290 lftp -c "set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 1; set net:persist-retries 0; set cmd:fail-exit yes; open ftp://$2:$3@$1; cd SaveDevData; ls")
echo $files
