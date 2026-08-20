#!/bin/bash

# LEGACY — still invoked by jobs/philips_mri/rsync_philips-mri.js:82 via the
# cwd-relative path ./read/sh/rsync_mmb.sh. Uses StrictHostKeyChecking=accept-new
# and skips -F /opt/resources/ssh/config, BYPASSING the fleet host-key policy;
# and because the bundle is mounted :ro, accepted keys are never persisted — the
# host is blind-accepted again every cycle. Do NOT copy this pattern (BACKLOG
# item 1d). Delete only after the Philips job is repointed to
# jobs/mmb/read/sh/rsync_mmb.sh — note the arg orders differ:
#   this script: $1=user  $2=ip          $3=dest
#   hardened:    $1=sme   $2=remote_path $3=dest  $4=ip  $5=user

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue

# SYNC THE REMOTE MMB LOG TO LOCAL FILE MIRROR

# "ssh -o KexAlgorithms=ecdh-sha2-nistp521"
# rsync -e ssh -r avante@172.31.3.51:/home/avante/host_logfiles /home/matt-teixeira/hep3/hhm_data_acquisition/test/15805
# echo $4 | sudo -S 
rsync --timeout=20 --delete -e "ssh -i /opt/resources/ssh/${SSH_KEY} -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/opt/resources/ssh/known_hosts" -rz $1@$2:/home/avante/host_logfiles $3


# sudo chown -R remoteservices:ansible_users /opt/files/SMEXXXXX

# The following command "sudo chown -R remoteservices:ansible_users /opt/files/SME" will change the ownership of the "/opt/files/SME" 
# directory and all its contents to the "remoteservices" user and the "ansible_users" group, recursively.

# Here's a breakdown of the command:

# "sudo": runs the command with administrative privileges.
# "chown": changes the owner and group of the specified files or directories.
# "-R": applies the changes recursively to all files and subdirectories in the specified directory.
# "remoteservices": specifies the new owner of the directory.
# "ansible_users": specifies the new group of the directory.
# "/opt/files/SME": specifies the directory that is being modified.
# Therefore, after running this command, the "remoteservices" user will become the owner of the "/opt/files/SME" directory and all its contents, 
# and the "ansible_users" group will be the group owner.

# sudo chmod +664 -R /opt/files/SMEXXXXX

# The following command "sudo chmod +664 -R" will give read and write permission to the owner and group, 
# and read permission to others for all files and subdirectories in the specified directory, recursively.

# Here's a breakdown of the command:

# "sudo": runs the command with administrative privileges.
# "chmod": changes the file mode bits of the specified files or directories.
# "+664": adds read and write permission to the owner and group, and read permission to others.
# "-R": applies the permission changes recursively to all files and subdirectories in the specified directory.
# Therefore, after running this command, all files and directories in the specified directory will have the following permission:

# The owner will have read and write permission.
# The group will have read and write permission.
# Others will have read permission.