#!/bin/bash

[ ! -d "$4" ] && mkdir $4
timeout 55 lftp ftp://$2:$3@$1 -e "set net:reconnect-interval-base 5; set net:max-retries 2; mirror --only-newer --include='gesys*' --exclude ".\+/$" --newer-than=now-7days /usr/g/service/log/ $4"
