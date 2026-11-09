#!/bin/bash
[ ! -d "$4" ] && mkdir $4

SSH_OPTS="-o StrictHostKeyChecking=accept-new -oKexAlgorithms=ecdh-sha2-nistp256 -o ConnectTimeout=30 -o ServerAliveInterval=10 -o ServerAliveCountMax=6"

# Download to a temporary name; replace sysError.log only when the transfer
# completed, so hhm_rpp_ge never parses a half-written file (hhm_rpp_ge
# PLAN-CV-INSIGHTS.md §5.5 D3a). Output and exit status are the transfer's own.
# The temporary name is per run ($$), so two runs for one system (scheduled
# + IP-reset retry) never move or delete each other's download; the trap
# removes it on any exit, and leftovers of killed runs (>2 h old) are swept.
tmp="$4/.sysError.log.part.$$"
trap 'rm -f "$tmp"' EXIT
find "$4" -maxdepth 1 -name '.sysError.log.part*' -mmin +120 -delete 2>/dev/null
sshpass -p $3 scp $SSH_OPTS $2@$1:'/C/Program\ Files/GE\ Medical\ Systems/DL/Log/sysError.log' $tmp
rc=$?
if [ $rc -eq 0 ]; then
  mv -f "$tmp" "$4/sysError.log" || exit 1
fi
exit $rc
