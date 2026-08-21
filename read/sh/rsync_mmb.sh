#!/bin/bash

# Philips-MRI directory-mirror rsync — invoked by
# jobs/philips_mri/rsync_philips-mri.js via ./read/sh/rsync_mmb.sh.
# Args: $1=user  $2=ip  $3=dest  (mirrors $1@$2:/home/avante/host_logfiles -> $3)
#
# Hardened 2026-08-21 (BACKLOG 1d): host-key policy now comes from the shared
# /opt/resources/ssh/config (StrictHostKeyChecking yes + central known_hosts),
# replacing an inline accept-new that bypassed verification — and, with the
# bundle mounted :ro, could never persist accepted keys anyway (every cycle was
# a blind first contact). An unknown host now fails loudly and classifies as
# host_key_unknown; fix = import/verify the key (doc 2.1, SHARED SSH BUNDLE).
# Distinct from jobs/mmb/read/sh/rsync_mmb.sh, which pulls a single named file
# with different args — this one stays the directory-mirror variant.

# BOMB SCRIPT FOR UNDEFINED VAR OR ERR DURING EXECUTION
set -ue

# Copy SSH key to a per-process tmp file with correct perms — source is group-read
# on a read-only mount; OpenSSH wants a private 600 copy.
KEY="/tmp/.ssh_runtime_key.$$"
trap 'rm -f "$KEY"' EXIT
install -m 600 "/opt/resources/ssh/${SSH_KEY}" "$KEY"

SSH_CFG="/opt/resources/ssh/config"

# SYNC THE REMOTE MMB LOG DIRECTORY TO LOCAL FILE MIRROR
rsync --timeout=20 --delete -e "ssh -F $SSH_CFG -i $KEY" -rz $1@$2:/home/avante/host_logfiles $3


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