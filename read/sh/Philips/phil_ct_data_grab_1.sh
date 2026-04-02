# set -ue
[ ! -d "$4" ] && mkdir $4

lftp -c "set net:timeout 10; set ftp:ssl-allow off; set net:reconnect-interval-base 3; set net:max-retries 1; set sftp:connect-program 'ssh -oConnectTimeout=10 -oKexAlgorithms=diffie-hellman-group14-sha1'; set xfer:clobber true; open sftp://$2:$3@$1; 
cd /cygdrive/d/Data_Logger/; 
mget Logger.mdb -O $4; exit"

if [ $? -ne 0 ]; then
    echo "Connection timed out" >&2
    exit 1
fi

chmod +0644 $4/Logger.mdb
# { BEGIN CONVERSION
now_ISO8601=$(date -u +"%Y-%m-%dT%H:%M:00Z")

test "$(ls -l $4/Logger.mdb | awk '{print $5}')" -gt "0" && chmod +0644 $4/Logger.mdb

EALINFO_TABLEVAR=$(mdb-tables $4/Logger.mdb | sed 's/ /\n/g' | sed -n 1p)
EVENTS_TABLEVAR=$(mdb-tables $4/Logger.mdb | sed 's/ /\n/g' | sed -n 2p)
# { ACCOUNT FOR EXISTING LOGS
touch $4/Events.output
test "$(ls -l $4/Events.output | awk '{print $5}')" -gt "0" && echo -n "" >$4/Events.output

touch $4/EALInfo.output
test "$(ls -l $4/EALInfo.output | awk '{print $5}')" -gt "0" && echo -n "" >$4/EALInfo.output

echo "Type,Level,Module,TStampNum,DataTime,Msg,EAL,BLOB,EventTime" >>$4/Events.output
# IN ORDER PIPED COMMANDS:
# EXPORT FROM MDB
# REMOVE ALL NON-ALPHANUMERIC CHARACTERS, KEEP THOSE IN SINGLE QUOTES
# REORDER COLUMNS
# SORT REORDERED COLUMNS
# REMOVE ALL NON-COMPLIANT ROWS
# OUTPUT FILE
mdb-export $4/Logger.mdb $EVENTS_TABLEVAR | tr -cd [:alnum:]'\n''\ ''"'',''['']'':''\-''_''.''/''=' | awk -v FS="," '{print $9, $1, $2, $3, $4, $5, $6, $7, $8}' | sort | sed -n -e "/^\"[0-9][0-9]\/.*/p" >>$4/Events.output
#echo "[/reading] : $EVENTS_TABLEVAR" >> /opt/files/$PATH/Events.output
#echo "[END CAPTURE BLOCK : ${now_ISO8601}]" >> /opt/files/$PATH/Events.output
#echo "[START CAPTURE BLOCK : ${now_ISO8601}]" >> /opt/files/$PATH/EALInfo.output
#echo "[reading] : $EALINFO_TABLEVAR" >> /opt/files/$PATH/EALInfo.output
# MAY HAVE TO FUDGE HEADERS IN BELOW THIS COMMENTED LINE
echo "DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime" >>$4/EALInfo.output
mdb-export $4/Logger.mdb $EALINFO_TABLEVAR | tail -n +2 | sort | awk 'NF > 2' >>$4/EALInfo.output

exit
