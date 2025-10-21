#!/bin/bash
# Usage: ./pull_althea_file.sh <remote_host> <username> <password> <local_dir>

HOST="$1"
USER="$2"
PASS="$3"
DEST="$4"

lftp -c "
set sftp:connect-program "ssh -F ~/.ssh/config althea-env"
set net:timeout 10;
set ftp:ssl-allow off;
set net:reconnect-interval-base 5;
set net:max-retries 1;
set xfer:clobber true;

open -u $USER,$PASS sftp://$HOST;

# Navigate to directory containing Althea DP files
cd /usr/local/bin/althea/dp;

# Download all files (or specify pattern)
mget * -O $DEST;
"

