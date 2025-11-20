#!/bin/bash

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue

# SYNC THE REMOTE MMB LOG TO LOCAL FILE MIRROR
# $1 DERIVES FROM HOST VALUE OF .ssh/config -> SME#
# $2 REMOTE FILE PATH
# $3 ABSOLUTE LOCAL FILE PATH
# EX rsync SME0123:~/v2_magmon.log /home/mmb-avante-client/mmb-files/SME0123.v2_magmon.log
# -z COMPRESS PAYLOAD
#rsync -z $1:$2 $3
rsync --timeout=20 -e ssh -rz $5@$4:$2 $3

# RETURN THE NEW FILESIZE IN BYTES
# stat --printf="%s" /home/mmb-avante-client/mmb-files/$1.$2.log
stat --printf="%s" $3

# rsync --timeout=20 -e ssh -rz $1@$2:/home/avante/host_logfiles $3