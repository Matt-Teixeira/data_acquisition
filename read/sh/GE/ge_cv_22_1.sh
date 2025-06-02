[ ! -d "$4" ] && mkdir $4
sshpass -p $3 scp -o StrictHostKeyChecking=accept-new -oKexAlgorithms=ecdh-sha2-nistp256 $2@$1:'/C/Program\ Files/GE\ Medical\ Systems/DL/Log/sysError.log' $4
