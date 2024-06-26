# Get current year and month to get rmmu files
# Ex: rmmu202307*
current_year_month=$(date +%Y%m)

[ ! -d "$4" ] && mkdir $4
[ ! -d "$4/monitoring" ] && mkdir $4/monitoring

sshpass -p $3 scp -o KexAlgorithms=diffie-hellman-group1-sha1 $2@$1:"G:/Log/logcurrent.log" $4/
sshpass -p $3 scp -o KexAlgorithms=diffie-hellman-group1-sha1 $2@$1:"G:/stt/STT_MAGNET.txt" $4/
sleep 5
chmod 644 $4/STT_MAGNET.txt 