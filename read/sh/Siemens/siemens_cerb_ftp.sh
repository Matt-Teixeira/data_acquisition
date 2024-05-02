[ ! -d "$6" ] && mkdir $6
current_date=$(date +'%Y_%m_%d')
echo $current_date

ftp -inv $1 <<EOF
user $2 $3
cd $4
binary  # Ensure binary mode is used for the transfer
mget *${4}${current_date}* -o $6/
bye
EOF


ftp
open 10.10.10.3
user matt_teixeira coremission
binary
put C0162/SHIP045/SME08929/XA157409_ERRORS_A1_2024_04_30_10_20_46_Evtlog.txt /home/matt-teixeira/XA157409_ERRORS_A1_2024_04_30_10_20_46_Evtlog.txt
quit