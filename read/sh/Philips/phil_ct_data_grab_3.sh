## set -ue

[ ! -d "$4/" ] && mkdir $4/

## timeout 60 sshpass -p $3 scp -o StrictHostKeyChecking=accept-new $2@$1:/cygdrive/d/Data_Logger/Logger.mdb $4
sshpass -p "$3" scp -o KexAlgorithms=diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1 -o StrictHostKeyChecking=accept-new "$2@$1:/cygdrive/d/Data_Logger/Logger.mdb" "$4/Output.mdb"

chmod +0644 $4/Output.mdb
# { BEGIN CONVERSION
now_ISO8601=$(date -u +"%Y-%m-%dT%H:%M:00Z")

test "$(ls -l $4/Output.mdb | awk '{print $5}')" -gt "0" && chmod +0644 $4/Output.mdb

EALINFO_TABLEVAR=$(mdb-tables $4/Output.mdb | sed 's/ /\n/g' | sed -n 1p)
EVENTS_TABLEVAR=$(mdb-tables $4/Output.mdb | sed 's/ /\n/g' | sed -n 2p)
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
mdb-export $4/Output.mdb $EVENTS_TABLEVAR | tr -cd [:alnum:]'\n''\ ''"'',''['']'':''\-''_''.''/''=' | awk -v FS="," '{print $9, $1, $2, $3, $4, $5, $6, $7, $8}' | sort | sed -n -e "/^\"[0-9][0-9]\/.*/p" >>$4/Events.output
#echo "[/reading] : $EVENTS_TABLEVAR" >> /opt/files/$PATH/Events.output
#echo "[END CAPTURE BLOCK : ${now_ISO8601}]" >> /opt/files/$PATH/Events.output
#echo "[START CAPTURE BLOCK : ${now_ISO8601}]" >> /opt/files/$PATH/EALInfo.output
#echo "[reading] : $EALINFO_TABLEVAR" >> /opt/files/$PATH/EALInfo.output
# MAY HAVE TO FUDGE HEADERS IN BELOW THIS COMMENTED LINE
echo "DTime,Controller,DataType,LogNumber,TmStamp,ERR_TYPE,ErrNum,vxwErrNo,File,Line,Param1,Param2,Info,EalTime" >>$4/EALInfo.output
mdb-export $4/Output.mdb $EALINFO_TABLEVAR | tail -n +2 | sort | awk 'NF > 2' >>$4/EALInfo.output

# { PHILIPS CT
# - name: Philips CT (SSH Copy)
#[ ! -d "/home/matt-teixeira/hep3/hhm_data_acquisition/test_hhm/Philips/CT/$4" ] && mkdir /home/matt-teixeira/hep3/hhm_data_acquisition/test_hhm/Philips/CT/$4
#timeout 120 sshpass -p $3 ssh -o StrictHostKeyChecking=accept-new $2@$1 "cd /cygdrive/d/Data_Logger/; cp Logger.mdb Output.mdb"
# ----------------------------------------------------------------------------------------
# - name: Philips CT (SCP)
#timeout 240 sshpass -p $3 scp -o StrictHostKeyChecking=accept-new $2@$1:/cygdrive/d/Data_Logger/Logger.mdb /home/matt-teixeira/hep3/hhm_data_acquisition/test_hhm/Philips/CT/$4
