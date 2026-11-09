#!/bin/bash
[ ! -d "$4" ] && mkdir $4

# Download to a temporary name; replace sysError.log only when the transfer
# completed, so hhm_rpp_ge never parses a half-written file (hhm_rpp_ge
# PLAN-CV-INSIGHTS.md §5.5 D3a). Output and exit status are the transfer's own.
# The temporary name is per run ($$), so two runs for one system (scheduled
# + IP-reset retry) never move or delete each other's download; the trap
# removes it on any exit, and leftovers of killed runs (>2 h old) are swept.
tmp="$4/.sysError.log.part.$$"
trap 'rm -f "$tmp"' EXIT
find "$4" -maxdepth 1 -name '.sysError.log.part*' -mmin +120 -delete 2>/dev/null
lftp -c "
set net:timeout 20; 
set net:reconnect-interval-base 5;
set net:reconnect-interval-max 5; 
set net:max-retries 2; 
set ftp:ssl-allow off; 
set xfer:clobber true; 
open ftp://$2:$3@$1; 
cd /C/Program\ Files/GE\ Medical\ Systems/DL/Log/; 
get sysError.log -o $tmp"
rc=$?
if [ $rc -eq 0 ]; then
  mv -f "$tmp" "$4/sysError.log" || exit 1
fi
exit $rc

# set net:timeout 20; → timeout for each connection attempt (DNS, TCP, login, etc.)
# set net:reconnect-interval-base 5; → wait 5 seconds between retries
# set net:reconnect-interval-max 5; → cap retry delay at 5 seconds
# set net:max-retries 2; → retry only twice