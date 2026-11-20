#!/bin/sh
# Philips CT (Brilliance / Ingenuity): pull D:\Data_Logger\Logger.mdb and export its two tables.
# Args: $1 host, $2 user, $3 password, $4 local system directory.
# Runs under /bin/sh (dash): POSIX only, no pipefail.
#
# Outputs in $4. Nothing in $4 changes until the download and every export succeed; then each
# file is replaced atomically (written in $4/.incoming, then mv on the same filesystem):
#   Logger.mdb                   the downloaded database
#   EALInfo.output, Events.output  legacy exports read by hhm_rpp_philips today. Same commands
#                                  as before, so the bytes are unchanged (format, column order,
#                                  sort, the Events tr/awk/sed filtering).
#   EALInfo.csv, Events.csv        complete exports (PCT-C): every row of each table, in table
#                                  order, header first; mdb-export -e escapes \n \r \t \\ inside
#                                  fields, so one physical line per row; BLOB stripped;
#                                  datetimes as YYYY-MM-DD HH:MM:SS (device local); NUL bytes removed.
#   Data_Logger.ls                 listing of D:\Data_Logger\ (does the scanner keep the old
#                                  Logger.mdb when it starts a new one?). Best effort.
#
# Exit status and stderr:
#   - download failed: "Connection timed out" on stderr, exit 0, outputs untouched (as before;
#     read/exec-hhm_data_grab.js classifies the stderr text).
#   - another grab of the same system still running: message on stderr, exit 0, nothing changed.
#   - download empty or an export failed: "phil_ct: ..." on stderr, exit 1, outputs untouched.

if [ -z "$4" ] || [ "$4" = "/" ]; then
    echo "phil_ct: no system directory given" >&2
    exit 1
fi
[ ! -d "$4" ] && mkdir "$4"

# One grab per system at a time (the staging directory is per system).
exec 9>"$4/.grab.lock"
if ! flock -n 9; then
    echo "phil_ct: previous grab of this system still running; skipped" >&2
    exit 0
fi

inc="$4/.incoming"
rm -rf "$inc"
if ! mkdir "$inc"; then
    echo "phil_ct: cannot create staging directory" >&2
    exit 1
fi
trap 'rm -rf "$inc"' EXIT

lftp -c "set net:timeout 20; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 2; set sftp:connect-program 'ssh -oKexAlgorithms=diffie-hellman-group14-sha1'; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/d/Data_Logger/ && cls -l > $inc/Data_Logger.ls;
mget Logger.mdb -O $inc; exit" 9>&-

if [ $? -ne 0 ]; then
    echo "Connection timed out" >&2
    exit
fi

mdb="$inc/Logger.mdb"
if [ ! -s "$mdb" ]; then
    echo "phil_ct: downloaded Logger.mdb is empty; previous outputs kept" >&2
    exit 1
fi
chmod +0644 "$mdb"

fail() {
    echo "phil_ct: $1 failed; previous outputs kept" >&2
    exit 1
}

# { LEGACY EXPORTS: the same commands as before, written to staging files.
EALINFO_TABLEVAR=$(mdb-tables $mdb | sed 's/ /\n/g' | sed -n 1p)
EVENTS_TABLEVAR=$(mdb-tables $mdb | sed 's/ /\n/g' | sed -n 2p)
[ -n "$EALINFO_TABLEVAR" ] && [ -n "$EVENTS_TABLEVAR" ] || fail "mdb-tables"

# Each mdb-export goes to a file first, so its exit status is seen (no pipefail in dash).
mdb-export $mdb $EVENTS_TABLEVAR >"$inc/events.raw" || fail "mdb-export $EVENTS_TABLEVAR (legacy)"
mdb-export $mdb $EALINFO_TABLEVAR >"$inc/ealinfo.raw" || fail "mdb-export $EALINFO_TABLEVAR (legacy)"

echo "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime" >"$inc/Events.output"
# IN ORDER PIPED COMMANDS:
# EXPORT FROM MDB (above)
# REMOVE ALL NON-ALPHANUMERIC CHARACTERS, KEEP THOSE IN SINGLE QUOTES
# REORDER COLUMNS
# SORT REORDERED COLUMNS
# REMOVE ALL NON-COMPLIANT ROWS
# OUTPUT FILE
tr -cd [:alnum:]'\n''\ ''"'',''['']'':''\-''_''.''/''=' <"$inc/events.raw" | awk -v FS="," '{print $9, $1, $2, $3, $4, $5, $6, $7, $8}' | sort | sed -n -e "/^\"[0-9][0-9]\/.*/p" >>"$inc/Events.output"

echo "DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime" >"$inc/EALInfo.output"
tail -n +2 "$inc/ealinfo.raw" | sort | awk 'NF > 2' >>"$inc/EALInfo.output"

# { COMPLETE EXPORTS (PCT-C)
mdb-export -e -b strip -T '%Y-%m-%d %H:%M:%S' "$mdb" EALInfo >"$inc/ealinfo.csv.raw" || fail "mdb-export EALInfo (csv)"
mdb-export -e -b strip -T '%Y-%m-%d %H:%M:%S' "$mdb" Events >"$inc/events.csv.raw" || fail "mdb-export Events (csv)"
tr -d '\000' <"$inc/ealinfo.csv.raw" >"$inc/EALInfo.csv" || fail "tr EALInfo.csv"
tr -d '\000' <"$inc/events.csv.raw" >"$inc/Events.csv" || fail "tr Events.csv"

# { PUBLISH: database first, then the exports made from it.
mv -f "$mdb" "$4/Logger.mdb" || fail "publish Logger.mdb"
for f in EALInfo.output Events.output EALInfo.csv Events.csv; do
    mv -f "$inc/$f" "$4/$f" || fail "publish $f"
done
[ -s "$inc/Data_Logger.ls" ] && mv -f "$inc/Data_Logger.ls" "$4/Data_Logger.ls"

exit 0
