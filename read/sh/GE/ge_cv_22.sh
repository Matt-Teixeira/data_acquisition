#!/bin/bash
[ ! -d "$4" ] && mkdir $4

SSH_OPTS="-o StrictHostKeyChecking=accept-new -o KexAlgorithms=diffie-hellman-group1-sha1,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group14-sha256 -o ConnectTimeout=30 -o ServerAliveInterval=10 -o ServerAliveCountMax=6"

# Download to a temporary name; replace sysError.log only when the transfer
# completed, so hhm_rpp_ge never parses a half-written file (hhm_rpp_ge
# PLAN-CV-INSIGHTS.md §5.5 D3a). Output and exit status are the transfer's own.
# The temporary name is per run ($$), so two runs for one system (scheduled
# + IP-reset retry) never move or delete each other's download; the trap
# removes it on any exit, and leftovers of killed runs (>2 h old) are swept.
# GE keeps the previous log generation as sysErrorPrev.log; it holds the old
# file's records written after our last download before GE started a new
# file. It is fetched too and published only when the sysError.log transfer
# succeeded; its own failure (e.g. no previous file yet) changes neither the
# exit status nor sysError.log. hhm_rpp_ge ingests that tail
# (PLAN-CV-INSIGHTS.md §5.5 D5).
tmp="$4/.sysError.log.part.$$"
tmpp="$4/.sysErrorPrev.log.part.$$"
trap 'rm -f "$tmp" "$tmpp"' EXIT
find "$4" -maxdepth 1 -name '.sysError*.part*' -mmin +120 -delete 2>/dev/null
sshpass -p $3 scp $SSH_OPTS $2@$1:'/C/Program\ Files/GE\ Medical\ Systems/DL/Log/sysError.log' $tmp
rc=$?
if [ $rc -eq 0 ]; then
  sshpass -p $3 scp $SSH_OPTS $2@$1:'/C/Program\ Files/GE\ Medical\ Systems/DL/Log/sysErrorPrev.log' $tmpp >/dev/null 2>&1 &&
    mv -f "$tmpp" "$4/sysErrorPrev.log" 2>/dev/null
  mv -f "$tmp" "$4/sysError.log" || exit 1
fi
exit $rc
