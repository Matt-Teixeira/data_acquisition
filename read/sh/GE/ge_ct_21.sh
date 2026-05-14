#!/bin/bash

[ ! -d "$4" ] && mkdir $4
timeout 240 lftp ftp://$2:$3@$1 -e "set net:timeout 10; set net:persist-retries 0; set net:reconnect-interval-base 5; set net:max-retries 1; mirror --max-errors=1 --only-newer --include='gesys*' --exclude ".\+/$" --newer-than=now-7days /usr/g/service/log/ $4"
