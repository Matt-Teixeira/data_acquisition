#!/bin/bash
# SIEMENS CV/IR (Artis) - DAILY *_LogFiles.zip PULL
#
# The Artis pushes a daily <prefix><yyyy_mm_dd>_LogFiles.zip to an Avante file
# server. This script mirrors those zips (only *_LogFiles.zip - not MonLogFiles /
# ShortLogFiles) into <system dir>/LogFiles_zips, then extracts the daily
# XA<serial>_<yyyy_mm_dd>_AppEventLog.txt files flat into <system dir>, which is
# where hhm_rpp_siemens (jobs/win_10/siemens_cv_app_event.js) reads them.
#
# Tracking:
#   - Pulled zips are kept in LogFiles_zips; mirror only downloads a zip that is
#     missing there or changed on the host.
#   - LogFiles_zips/.extracted/<zip> holds "size mtime" of the copy already
#     extracted, so each zip is extracted once (again only if it changes).
#
# Only COMPLETE days are published. A zip named for day Z holds day Z-1's full
# log plus a partial day Z log. A file dated before Z is complete; the day Z
# file is skipped and arrives complete in the next day's zip. A published file
# is never overwritten, so a day already parsed cannot change underneath rpp.
# Each file is unzipped to LogFiles_zips/.work.* and renamed into place, so rpp
# never sees a half-written file.
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

date_re='^[0-9]{4}_[0-9]{2}_[0-9]{2}$'
app_re='_([0-9]{4}_[0-9]{2}_[0-9]{2})_AppEventLog\.txt$'

# Scratch space on the same filesystem, so publishing a file is an atomic rename.
work_dir=$(mktemp -d "$zip_dir/.work.XXXXXX") || exit 1
trap 'rm -rf "$work_dir"' EXIT

failed=0
for zip in "${zips[@]}"; do
  name=$(basename "$zip")
  marker="$marker_dir/$name"
  stamp=$(stat -c '%s %Y' "$zip")

  # Already extracted this exact copy of the zip.
  [ -f "$marker" ] && [ "$(cat "$marker")" = "$stamp" ] && continue

  rest="${name#"$prefix"}"
  zip_date="${rest%_LogFiles.zip}"
  if ! [[ "$zip_date" =~ $date_re ]]; then
    echo "Cannot read date from zip name, skipping: $name" >&2
    failed=1
    continue
  fi

  if ! unzip -tqq "$zip" >/dev/null 2>&1; then
    echo "Corrupt or incomplete zip, skipping: $name" >&2
    failed=1
    continue
  fi

  entries=$(unzip -Z1 "$zip" '*/Event_Logs/*_AppEventLog.txt' 2>/dev/null)
  if [ -z "$entries" ]; then
    echo "No AppEventLog in zip, skipping: $name" >&2
    failed=1
    continue
  fi

  zip_failed=0
  while IFS= read -r entry; do
    base=$(basename "$entry")
    [[ "$base" =~ $app_re ]] || continue
    file_date="${BASH_REMATCH[1]}"

    # A day's log is complete only in a zip made on a later day. The zip's
    # own-day log is partial (the zip is cut just after midnight), so it is
    # left for the next day's zip.
    if ! [[ "$file_date" < "$zip_date" ]]; then
      continue
    fi

    dest="$sys_dir/$base"
    if ! unzip -qq -o -j "$zip" "$entry" -d "$work_dir"; then
      echo "unzip failed for $entry in $name" >&2
      zip_failed=1
      continue
    fi

    if [ ! -e "$dest" ]; then
      mv "$work_dir/$base" "$dest" || { zip_failed=1; continue; }
      echo "New complete day: $base (from $name)"
    elif cmp -s "$work_dir/$base" "$dest"; then
      rm -f "$work_dir/$base"
    else
      # A complete day was already published (and may be parsed). Keep it.
      echo "Kept existing $base; copy in $name differs" >&2
      rm -f "$work_dir/$base"
    fi
  done <<<"$entries"

  if [ "$zip_failed" -ne 0 ]; then
    failed=1
    continue
  fi

  echo "$stamp" >"$marker"
done

exit "$failed"
