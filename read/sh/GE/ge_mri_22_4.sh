#!/usr/bin/env bash
set -euo pipefail

host="$1"
user="$2"
pass="$3"
dest="$4"

mkdir -p "$dest"

SSH_OPTS=(
  -T
  -o StrictHostKeyChecking=accept-new
  -o KexAlgorithms=diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group14-sha256
  -o ConnectTimeout=30
  -o ServerAliveInterval=10
  -o ServerAliveCountMax=6
)

# Get file list and FILTER OUT remote banner noise
file_list="$(
  sshpass -p "$pass" ssh "${SSH_OPTS[@]}" "$user@$host" \
    "/bin/sh -lc 'ls -1 /usr/g/service/log/gesys*.log 2>/dev/null || true'" \
  | tr -d '\r' \
  | grep -E '^/usr/g/service/log/gesys.*\.log$' \
  || true
)"

if [[ -z "${file_list//$'\n'/}" ]]; then
  echo "No matching files found (or output was filtered away)." >&2
  exit 0
fi

while IFS= read -r remote_file; do
  [[ -z "$remote_file" ]] && continue

  base="$(basename "$remote_file")"
  tmp="$dest/$base.tmp"
  out="$dest/$base"

  echo "Downloading $remote_file -> $out"

  sshpass -p "$pass" ssh "${SSH_OPTS[@]}" "$user@$host" \
    "/bin/sh -lc 'cat \"$remote_file\"'" \
  | sed '/^DICTIONARYDIR is not set - defaulting to /d;
         /^ODINA_DICTIONARY is not set - defaulting to /d;
         /^DICOM_DICTIONARY is not set - defaulting to /d;' \
  > "$tmp"

  mv -f "$tmp" "$out"
done <<< "$file_list"
