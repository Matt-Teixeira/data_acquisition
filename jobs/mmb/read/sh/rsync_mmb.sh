#!/bin/bash

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue

# Copy SSH key to tmp with correct perms (once per container lifecycle)
# Host key at /opt/resources/ssh/ is 640 root:docker — OpenSSH rejects group-readable keys
KEY="/tmp/.ssh_runtime_key"
if [ ! -f "$KEY" ]; then
  cp "/opt/resources/ssh/${SSH_KEY}" "$KEY"
  chmod 600 "$KEY"
fi

SSH_CFG="/opt/resources/ssh/config"

# SYNC THE REMOTE MMB LOG TO LOCAL FILE MIRROR
# $1 SME identifier
# $2 REMOTE FILE PATH
# $3 ABSOLUTE LOCAL FILE PATH
# $4 IP ADDRESS
# $5 USER ID
rsync --timeout=20 -e "ssh -F $SSH_CFG -i $KEY" -rz $5@$4:$2 $3

# RETURN THE NEW FILESIZE IN BYTES
stat --printf="%s" $3
