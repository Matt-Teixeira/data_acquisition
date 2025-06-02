#!/usr/bin/expect -f

set timeout -1
set host "10.72.61.17"
set user "user"
set password "password"
set remote_path "/usr/g/service/log"
set file_pattern "gesys*.log"
set local_path "/home/prod"

spawn bash -c "ssh -oKexAlgorithms=diffie-hellman-group14-sha1 $user@$host 'cd $remote_path && tar -cf - $file_pattern' | tar -xf - -C $local_path"

expect {
    "*assword:*" {
        send "$password\r"
        exp_continue
    }
    eof
}

######################## ### WITH ARGS ### ########################
# set local_path [lindex $argv 3]
# if { ! [file isdirectory $local_path] } {
#    file mkdir $local_path
# }

# set timeout -1
# set host [lindex $argv 0]
# set user [lindex $argv 1]
# set password [lindex $argv 2]
# set remote_path "/usr/g/service/log"
# set file_pattern "gesys*.log"

# spawn bash -c "ssh -oKexAlgorithms=diffie-hellman-group14-sha1 $user@$host 'cd $remote_path && tar -cf - $file_pattern' | tar -xf - -C $local_path"

# expect {
#     "*assword:*" {
#         send "$password\r"
#         exp_continue
#     }
#     eof
# }

# sshpass -p $3 scp -o StrictHostKeyChecking=accept-new -oKexAlgorithms=diffie-hellman-group1-sha1 $2@$1:'/c/Program\ Files/GE\ Medical\ Systems/DL/Log/sysError.log' $4
