#!/usr/bin/env bash
set -euxo pipefail  # add -x for debug

host="$1"
user="$2"
password="$3"
dest_dir="$4"

# Make sure destination directory exists
mkdir -p "$dest_dir"

# Put SSH options in an *array* so they’re passed correctly
SSH_OPTS=(
  -o StrictHostKeyChecking=accept-new
  -o KexAlgorithms=+diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group14-sha256
  -o HostKeyAlgorithms=+ssh-rsa
  -o PubkeyAcceptedAlgorithms=+ssh-rsa
  -o ConnectTimeout=10
  -o ServerAliveInterval=10
  -o ServerAliveCountMax=6
)

sshpass -p "$password" scp \
  "${SSH_OPTS[@]}" \
  "${user}@${host}:/usr/g/service/log/gesys*.log" \
  "$dest_dir"
