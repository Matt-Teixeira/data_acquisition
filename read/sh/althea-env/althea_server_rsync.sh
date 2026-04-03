#!/bin/bash
set -ue

# Copy SSH key to a per-process tmp file with correct perms — source is 640 root:docker
# (read-only mount), OpenSSH rejects group-readable keys so we need a 600 copy.
KEY="/tmp/.ssh_runtime_key.$$"
trap 'rm -f "$KEY"' EXIT
install -m 600 "/opt/resources/ssh/${SSH_KEY}" "$KEY"

SSH_CFG="/opt/resources/ssh/config"

# $1 SME identifier
# $2 REMOTE FILE PATH
# $3 ABSOLUTE LOCAL FILE PATH
# $4 IP ADDRESS
# $5 USER ID
rsync --timeout=20 -e "ssh -F $SSH_CFG -i $KEY" -rz $5@$4:$2 $3

# RETURN THE NEW FILESIZE IN BYTES
stat --printf="%s" $3

