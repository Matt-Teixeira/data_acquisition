[ ! -d "$6" ] && mkdir $6
current_date=$(date +'%Y_%m_%d')
echo $current_date

path="$4$current_date$5"

curl -u matt_teixeira:coremission ftp://172.31.1.1/C0162/SHIP045/SME08929/XA157409_ERRORS_A1_2024_04_30_10_20_46_Evtlog.txt -o $6/XA157409_ERRORS_A1_2024_04_30_10_20_46_Evtlog.txt


[ ! -d "$6" ] && mkdir $6
current_date=$(date +'%Y_%m_%d')
echo $current_date

username=$2
password=$3
host="172.31.1.1"
remote_dir=$4
file_prefix=$5
local_dir=$6

lftp -d -c "set net:timeout 10; set ftp:ssl-allow on; set net:reconnect-interval-base 5; set net:max-retries 1; set xfer:clobber true; 
open sftp://${username}:${password}@${host};
cd ${remote_dir};
mget XA157409_ERRORS_A1_2024_05_07_09_05_27_Evtlog.txt -O ${local_dir}"

# curl -u ${username}:${password} sftp://${host}/${remote_dir}*${file_prefix}${current_date}* -o $6/

#1 '10.10.10.3',
#2 'matt_teixeira',
#3 'coremission',
#4 'C0162/SHIP045/SME08929/XA157409_ERRORS_A1_',
#5 '_Evtlog.txt'
# lftp ftp://matt_teixeira@172.31.1.1

#1 '10.10.10.3',
#2 'matt_teixeira',
#3 'coremission',
#4 'C0162/SHIP045/SME08929/XA157409_ERRORS_A1_',
#5 '_Evtlog.txt'