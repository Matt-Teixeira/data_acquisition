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
  -o ConnectTimeout=10
  -o ServerAliveInterval=10
  -o ServerAliveCountMax=6
)

# Get file list and FILTER OUT remote banner noise
file_list="$(
  timeout 240 sshpass -p "$pass" ssh "${SSH_OPTS[@]}" "$user@$host" \
    "/bin/sh -c 'for f in /usr/g/service/log/gesys*.log; do [ -f \"\$f\" ] && echo \"\$f\"; done'" \
  | tr -d '\r' \
  | grep -E '^/usr/g/service/log/gesys.*\.log$' \
  || true
)"

if [[ -z "${file_list//$'\n'/}" ]]; then
  echo "No matching files found (or output was filtered away)." >&2
  exit 0
fi

echo "File list:"
echo "$file_list"

errors=0
while IFS= read -r remote_file; do
  [[ -z "$remote_file" ]] && continue

  base="$(basename "$remote_file")"
  tmp="$dest/$base.tmp"
  out="$dest/$base"

  echo "Downloading $remote_file -> $out"

  if timeout 240 sshpass -p "$pass" ssh "${SSH_OPTS[@]}" "$user@$host" \
    "/bin/sh -c 'cat \"$remote_file\"'" < /dev/null \
    | sed '/^DICTIONARYDIR is not set/d;
           /^ODINA_DICTIONARY is not set/d;
           /^DICOM_DICTIONARY is not set/d;
           /can'\''t set the locale/d;
           /^chown: /d;
           /BrainWave\.config: Permission denied/d;
           /^\/usr\/ucb\/tset/d;
           /^?$/d' \
    > "$tmp"
  then
    mv -f "$tmp" "$out"
  else
    echo "WARNING: Failed to download $remote_file" >&2
    rm -f "$tmp"
    errors=$((errors + 1))
  fi
done <<< "$file_list"

if [[ $errors -gt 0 ]]; then
  echo "$errors file(s) failed to download." >&2
  exit 1
fi
