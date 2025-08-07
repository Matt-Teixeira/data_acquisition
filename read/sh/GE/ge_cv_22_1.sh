#!/bin/bash
[ ! -d "$4" ] && mkdir $4

SSH_OPTS="-o StrictHostKeyChecking=accept-new -oKexAlgorithms=ecdh-sha2-nistp256 -o ConnectTimeout=30 -o ServerAliveInterval=10 -o ServerAliveCountMax=6"

sshpass -p $3 scp $SSH_OPTS $2@$1:'/C/Program\ Files/GE\ Medical\ Systems/DL/Log/sysError.log' $4
