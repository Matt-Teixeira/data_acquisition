#!/bin/bash
# SIEMENS CV/IR (Artis) - DAILY *_LogFiles.zip PULL
#
# The Artis pushes a daily <prefix><yyyy_mm_dd>_LogFiles.zip to an Avante file
# server. This script mirrors those zips (only *_LogFiles.zip - not MonLogFiles /
# ShortLogFiles) into <system dir>/LogFiles_zips, then extracts the daily
# XA<serial>_<yyyy_mm_dd>_AppEventLog.txt files flat into <system dir>, which is
# where hhm_rpp_siemens (jobs/win_10/siemens_cv_app_event.js) reads them.
#
# Each zip holds the previous day's complete AppEventLog plus today's partial
# one. unzip -u keeps whichever copy is newest, so tomorrow's zip upgrades
# today's partial file to the complete one. The parser only reads days before
# today, so the partial file is never parsed.
#
# $1 IP Address
## Ex: '172.31.3.120'
# $2 Username
# $3 Password
# $4 Remote directory the Artis pushes to
## Ex: '/srv/ftp/arts'
# $5 File name prefix (config.acquisition.cerb_file)
## Ex: 'XA160418_'
# $6 Path on debian
## Ex: '/home/prod/hhm_data_acquisition/files/SME10007'

set -u

if [ "$#" -ne 6 ]; then
  echo "siemens_cv_logfiles_zip.sh: expected 6 args (ip user pass remote_dir prefix local_dir), got $#" >&2
  exit 2
fi

ip="$1"
user="$2"
remote_dir="$4"
prefix="$5"
sys_dir="$6"
zip_dir="$sys_dir/LogFiles_zips"
marker_dir="$zip_dir/.extracted"

mkdir -p "$sys_dir" "$zip_dir" "$marker_dir" || exit 1

# Password goes to lftp through the environment, not its command line.
export LFTP_PASSWORD="$3"

# mirror: downloads zips that are missing locally or differ in size/time.
# xfer:use-temp-file: a download is renamed into place only once complete.
lftp -c "set net:timeout 10; set net:max-retries 1; set net:reconnect-interval-base 5; set cmd:fail-exit yes; set xfer:use-temp-file yes;
open --env-password -u '$user' sftp://$ip;
mirror --no-recursion --no-perms --include-glob '${prefix}*_LogFiles.zip' --verbose=1 '$remote_dir' '$zip_dir'"
lftp_status=$?
unset LFTP_PASSWORD

if [ "$lftp_status" -ne 0 ]; then
  echo "lftp mirror failed with status $lftp_status" >&2
  exit "$lftp_status"
fi

shopt -s nullglob
zips=("$zip_dir"/"${prefix}"*_LogFiles.zip)
if [ "${#zips[@]}" -eq 0 ]; then
  echo "No ${prefix}*_LogFiles.zip on host" >&2
  exit 1
fi

failed=0
for zip in "${zips[@]}"; do
  name=$(basename "$zip")
  marker="$marker_dir/$name"
  stamp=$(stat -c '%s %Y' "$zip")

  # Already extracted this exact copy of the zip.
  [ -f "$marker" ] && [ "$(cat "$marker")" = "$stamp" ] && continue

  if ! unzip -tqq "$zip" >/dev/null 2>&1; then
    echo "Corrupt or incomplete zip, skipping: $name" >&2
    failed=1
    continue
  fi

  unzip -uoqj "$zip" '*/Event_Logs/*_AppEventLog.txt' -d "$sys_dir"
  unzip_status=$?
  if [ "$unzip_status" -ne 0 ]; then
    echo "unzip status $unzip_status (no AppEventLog in zip?): $name" >&2
    failed=1
    continue
  fi

  echo "$stamp" >"$marker"
  echo "Extracted AppEventLog from $name"
done

exit "$failed"
