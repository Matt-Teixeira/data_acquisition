#!/bin/sh
# Philips CT (Brilliance / Ingenuity): pull D:\Data_Logger\Logger.mdb and export its two tables.
# Args: $1 host, $2 user, $3 password, $4 local system directory.
# Runs under /bin/sh (dash): POSIX only, no pipefail, so every step that matters writes to a
# file and its own exit status is checked.
#
# Outputs in $4. Nothing in $4 changes until the download and every export succeed; then each
# file is replaced atomically (written in a private staging directory $4/.incoming.XXXXXX, then
# mv -T on the same filesystem), with mode 0644 whatever the umask:
#   Logger.mdb                     the downloaded database
#   EALInfo.output, Events.output  legacy exports read by hhm_rpp_philips today. Same commands
#                                  as before (each step now checked), so the bytes are unchanged.
#   EALInfo.csv, Events.csv        complete exports (PCT-C): every row of each table, in table
#                                  order, header first; mdb-export -e escapes \n \r \t \\ inside
#                                  fields, so one physical line per row; quotes doubled; BLOB
#                                  stripped; datetimes YYYY-MM-DD HH:MM:SS (device local); NUL removed.
#   Data_Logger.ls                 listing of D:\Data_Logger\ (does the scanner keep the old
#                                  Logger.mdb when it starts a new one?). Best effort and silent:
#                                  its own session after publishing, installed only if the session
#                                  succeeded. Attempted at most once a day (by attempt time), and
#                                  when the database shrank (a possible reset): then retried at
#                                  most hourly until a listing succeeds.
#
# Deadlines: both lftp sessions run under timeout -k, which signals the whole process group (lftp
# and its ssh child) and kills it after a grace period. timeout stops supervising once its direct
# child exits, so when a session ends (however it ends) anything left in its process group is
# killed too: nothing from a session can outlive it or keep the lock. Defaults: download 600 s,
# listing 120 s, grace 15 s. PHIL_CT_DL_TIMEOUT / PHIL_CT_LIST_TIMEOUT / PHIL_CT_KILL_GRACE
# override them with whole seconds from 1 to 86400; anything else (0 included, which would disable
# a deadline) falls back to the default. A download that hits its deadline is reported like any
# other failed download ("Connection timed out", exit 0).
#
# Exit status and stderr (read/exec-hhm_data_grab.js classifies them):
#   0  success, stderr empty.
#   0  download failed: "Connection timed out" on stderr, nothing changed (as before).
#   75 another grab of this system still holds the lock: "phil_ct: ... skipped", nothing changed.
#      Nonzero on purpose: the runner then logs it and does not record a successful acquisition.
#   1  any other failure: "phil_ct: ..." on stderr. Before publishing: nothing changed. During
#      publishing: the message names the file that failed and says the set is partly updated.

# whole seconds, 1..86400 (leading zeros allowed, read as decimal); otherwise the default
num() {
    case "$1" in ''|*[!0-9]*) echo "$2"; return ;; esac
    [ ${#1} -le 6 ] || { echo "$2"; return; }
    n=$(expr "$1" + 0)
    if [ "$n" -ge 1 ] && [ "$n" -le 86400 ]; then echo "$n"; else echo "$2"; fi
}

# Run one lftp session under timeout as a background job, wait for it, then kill whatever is left
# in its process group (GNU timeout leads its own group unless --foreground). Returns the
# session's status. $1 = limit (s), $2 = lftp command string.
session() {
    timeout -k "$kill_grace" "$1" lftp -c "$2" &
    sess_pid=$!
    wait "$sess_pid"
    sess_rc=$?
    kill -s KILL -- "-$sess_pid" 2>/dev/null
    return $sess_rc
}
dl_timeout=$(num "$PHIL_CT_DL_TIMEOUT" 600)
list_timeout=$(num "$PHIL_CT_LIST_TIMEOUT" 120)
kill_grace=$(num "$PHIL_CT_KILL_GRACE" 15)

if [ -z "$4" ] || [ "$4" = "/" ]; then
    echo "phil_ct: no system directory given" >&2
    exit 1
fi
[ ! -d "$4" ] && mkdir "$4"

# One grab per system at a time. Every process this script starts inherits fd 9, including lftp
# and its ssh child, so the lock stays held while any writer of this grab is alive, even if this
# shell is killed. flock -E 75: status 75 means the lock is taken; any other nonzero is an error.
exec 9>"$4/.grab.lock" || { echo "phil_ct: cannot open lock file" >&2; exit 1; }
flock -n -E 75 9
lock_rc=$?
if [ $lock_rc -eq 75 ]; then
    echo "phil_ct: previous grab of this system still running; skipped" >&2
    exit 75
elif [ $lock_rc -ne 0 ]; then
    echo "phil_ct: flock failed (status $lock_rc)" >&2
    exit 1
fi

# Holding the lock means no earlier grab's writer is alive, so leftover staging is safe to remove.
rm -rf "$4"/.incoming "$4"/.incoming.*
inc=$(mktemp -d "$4/.incoming.XXXXXX") || { echo "phil_ct: cannot create staging directory" >&2; exit 1; }
trap 'rm -rf "$inc"' EXIT

session "$dl_timeout" "set net:timeout 20; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 2; set sftp:connect-program 'ssh -oKexAlgorithms=diffie-hellman-group14-sha1'; set xfer:clobber true; open sftp://$2:$3@$1;
cd /cygdrive/d/Data_Logger/;
mget Logger.mdb -O $inc; exit"

if [ $? -ne 0 ]; then
    echo "Connection timed out" >&2
    exit
fi

mdb="$inc/Logger.mdb"
if [ ! -s "$mdb" ]; then
    echo "phil_ct: downloaded Logger.mdb is empty; previous outputs kept" >&2
    exit 1
fi

fail() {
    echo "phil_ct: $1 failed; previous outputs kept" >&2
    exit 1
}

# { LEGACY EXPORTS: the same commands as before, one checked step at a time.
mdb-tables $mdb >"$inc/tables.txt" || fail "mdb-tables"
sed 's/ /\n/g' "$inc/tables.txt" >"$inc/tables.lines" || fail "mdb-tables (split)"
EALINFO_TABLEVAR=$(sed -n 1p "$inc/tables.lines") || fail "mdb-tables (table names)"
EVENTS_TABLEVAR=$(sed -n 2p "$inc/tables.lines") || fail "mdb-tables (table names)"
[ -n "$EALINFO_TABLEVAR" ] && [ -n "$EVENTS_TABLEVAR" ] || fail "mdb-tables (table names)"

# Each raw export is made when its table is processed and removed as soon as it has been read.
mdb-export $mdb $EVENTS_TABLEVAR >"$inc/events.raw" || fail "mdb-export $EVENTS_TABLEVAR (legacy)"

# Events, in order: REMOVE ALL NON-ALPHANUMERIC CHARACTERS, KEEP THOSE IN SINGLE QUOTES;
# REORDER COLUMNS; SORT REORDERED COLUMNS; REMOVE ALL NON-COMPLIANT ROWS
echo "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime" >"$inc/Events.output" || fail "Events.output header"
tr -cd [:alnum:]'\n''\ ''"'',''['']'':''\-''_''.''/''=' <"$inc/events.raw" >"$inc/ev.1" || fail "Events legacy tr"
rm -f "$inc/events.raw"
awk -v FS="," '{print $9, $1, $2, $3, $4, $5, $6, $7, $8}' "$inc/ev.1" >"$inc/ev.2" || fail "Events legacy awk"
rm -f "$inc/ev.1"
sort "$inc/ev.2" >"$inc/ev.3" || fail "Events legacy sort"
rm -f "$inc/ev.2"
sed -n -e "/^\"[0-9][0-9]\/.*/p" "$inc/ev.3" >>"$inc/Events.output" || fail "Events legacy sed"
rm -f "$inc/ev.3"

mdb-export $mdb $EALINFO_TABLEVAR >"$inc/ealinfo.raw" || fail "mdb-export $EALINFO_TABLEVAR (legacy)"
echo "DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime" >"$inc/EALInfo.output" || fail "EALInfo.output header"
tail -n +2 "$inc/ealinfo.raw" >"$inc/eal.1" || fail "EALInfo legacy tail"
rm -f "$inc/ealinfo.raw"
sort "$inc/eal.1" >"$inc/eal.2" || fail "EALInfo legacy sort"
rm -f "$inc/eal.1"
awk 'NF > 2' "$inc/eal.2" >>"$inc/EALInfo.output" || fail "EALInfo legacy awk"
rm -f "$inc/eal.2"

# { COMPLETE EXPORTS (PCT-C)
mdb-export -e -b strip -T '%Y-%m-%d %H:%M:%S' "$mdb" EALInfo >"$inc/ealinfo.csv.raw" || fail "mdb-export EALInfo (csv)"
tr -d '\000' <"$inc/ealinfo.csv.raw" >"$inc/EALInfo.csv" || fail "tr EALInfo.csv"
rm -f "$inc/ealinfo.csv.raw"
mdb-export -e -b strip -T '%Y-%m-%d %H:%M:%S' "$mdb" Events >"$inc/events.csv.raw" || fail "mdb-export Events (csv)"
tr -d '\000' <"$inc/events.csv.raw" >"$inc/Events.csv" || fail "tr Events.csv"
rm -f "$inc/events.csv.raw"

chmod 0644 "$mdb" "$inc/EALInfo.output" "$inc/Events.output" "$inc/EALInfo.csv" "$inc/Events.csv" || fail "chmod"

# { PUBLISH: database first, then the exports made from it. From here a failure is partial.
prev_size=$(stat -c %s "$4/Logger.mdb" 2>/dev/null || echo 0)
new_size=$(stat -c %s "$mdb")
published=""
for f in Logger.mdb EALInfo.output Events.output EALInfo.csv Events.csv; do
    if ! mv -fT "$inc/$f" "$4/$f"; then
        echo "phil_ct: publish $f failed; outputs partly updated (already published:${published:- none})" >&2
        exit 1
    fi
    published="$published $f"
done

# { LISTING (best effort, silent, isolated): runs in a subshell, so nothing it does (a failed
# state-file update included) can reach stderr, the exit status, or the published outputs.
# Throttled by the time of the last attempt, not of the last success: if that time can't be
# recorded, no attempt is made. A shrunk database (a possible reset) sets a pending flag: attempt
# now, then at most hourly until a listing succeeds.
(
    attempt="$4/.listing.attempt"
    pending="$4/.listing.reset_pending"
    shrank=0
    [ "$new_size" -lt "$prev_size" ] && shrank=1 && touch "$pending"
    due=0
    { [ ! -e "$attempt" ] || [ -n "$(find "$attempt" -mmin +1440)" ]; } && due=1
    [ $shrank = 1 ] && due=1
    [ -e "$pending" ] && [ -n "$(find "$attempt" -mmin +60)" ] && due=1
    [ $due = 1 ] || exit 0
    touch "$attempt" || exit 0
    if session "$list_timeout" "set net:timeout 20; set ftp:ssl-allow off; set net:reconnect-interval-base 5; set net:max-retries 2; set sftp:connect-program 'ssh -oKexAlgorithms=diffie-hellman-group14-sha1'; open sftp://$2:$3@$1; 
cd /cygdrive/d/Data_Logger/ && cls -l > $inc/Data_Logger.ls" &&
        [ -s "$inc/Data_Logger.ls" ] &&
        chmod 0644 "$inc/Data_Logger.ls" &&
        mv -fT "$inc/Data_Logger.ls" "$4/Data_Logger.ls"; then
        rm -f "$pending"
    fi
) >/dev/null 2>&1

exit 0
