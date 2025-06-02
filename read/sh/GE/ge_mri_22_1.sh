[ ! -d "$4" ] && mkdir $4
sshpass -p $3 scp -o StrictHostKeyChecking=accept-new -oKexAlgorithms=diffie-hellman-group14-sha1 $2@$1:/usr/g/service/log/gesys*.log $4