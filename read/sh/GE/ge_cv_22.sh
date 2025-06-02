[ ! -d "$4" ] && mkdir $4
sshpass -p $3 scp -o StrictHostKeyChecking=accept-new -oKexAlgorithms=diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group14-sha256 $2@$1:'/C/Program\ Files/GE\ Medical\ Systems/DL/Log/sysError.log' $4
