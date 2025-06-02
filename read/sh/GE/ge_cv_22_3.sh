[ ! -d "$4" ] && mkdir $4
sshpass -p $3 scp -o StrictHostKeyChecking=accept-new -oKexAlgorithms=diffie-hellman-group1-sha1 $2@$1:'/c/Program\ Files/GE\ Medical\ Systems/DL/Log/sysError.log' $4
