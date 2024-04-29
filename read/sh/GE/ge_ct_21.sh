[ ! -d "$4" ] && mkdir $4
timeout 130 lftp ftp://$2:$3@$1 -e "set net:reconnect-interval-base 5; set net:max-retries 2; mirror --only-newer --include='gesys*' --exclude ".\+/$" --newer-than=now-7days /usr/g/service/log/ $4"

## lftp -c "open ftp://$2:$3@$1; cd /C/Program\ Files/GE\ Medical\ Systems/DL/Log/; mget -e sysError.log -O $4/sysError"
## vs ftp