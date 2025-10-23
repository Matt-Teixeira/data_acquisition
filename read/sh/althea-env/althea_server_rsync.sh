#!/bin/bash
set -ue
#rsync -z $1:$2 $3
rsync --timeout=20 -e ssh -rz $5@$4:$2 $3

# RETURN THE NEW FILESIZE IN BYTES
# stat --printf="%s" /home/mmb-avante-client/mmb-files/$1.$2.log
stat --printf="%s" $3

# rsync --timeout=20 -e ssh -rz $1@$2:/home/avante/host_logfiles $3

