#!/bin/bash
[ ! -d "$4" ] && mkdir $4

SSH_OPTS="
  -o StrictHostKeyChecking=accept-new \
  -o KexAlgorithms=+diffie-hellman-group1-sha1 \
  -o HostKeyAlgorithms=+ssh-rsa \
  -o PubkeyAcceptedAlgorithms=+ssh-rsa \
  -o ConnectTimeout=10 \
  -o ServerAliveInterval=10 \
  -o ServerAliveCountMax=6
"
timeout 240 sshpass -p $3 scp $SSH_OPTS $2@$1:'/c/Program\ Files/GE\ Medical\ Systems/DL/Log/sysError.log' $4