[ ! -d "$6" ] && mkdir $6
current_date=$(date +'%Y_%m_%d')
echo $current_date

## ftp -inv $1 <<EOF
user $2 $3
cd $4
binary  # Ensure binary mode is used for the transfer
mget *${4}${current_date}* -o $6/
bye
EOF


curl -u matt_teixeira:coremission ftp://172.31.1.1/*$5$current_date* -o $6/