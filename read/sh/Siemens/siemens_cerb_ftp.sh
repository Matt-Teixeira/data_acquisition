[ ! -d "$6" ] && mkdir $6
current_date=$(date +'%Y_%m_%d')
echo $current_date

path="$4$current_date$5"

curl -u matt_teixeira:coremission ftp://172.31.1.1/C0162/SHIP045/SME08929/XA157409_ERRORS_A1_2024_04_30_10_20_46_Evtlog.txt -o $6/XA157409_ERRORS_A1_2024_04_30_10_20_46_Evtlog.txt

#1 '10.10.10.3',
#2 'matt_teixeira',
#3 'coremission',
#4 'C0162/SHIP045/SME08929/XA157409_ERRORS_A1_',
#5 '_Evtlog.txt'