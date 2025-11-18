#!/usr/bin/expect -f
set local_path [lindex $argv 3]
if { ! [file isdirectory $local_path] } {
    file mkdir $local_path
}

set timeout 45
set host [lindex $argv 0]
set user [lindex $argv 1]
set password [lindex $argv 2]
set remote_path "/usr/g/service/log"
set file_pattern "gesys*.log"
set local_path [lindex $argv 3]

spawn bash -c "ssh -oKexAlgorithms=diffie-hellman-group14-sha1 -oMACs=hmac-sha2-256 $user@$host 'cd $remote_path && tar -cf - $file_pattern' | tar -xf - -C $local_path"

expect {
    "*assword:*" {
        send "$password\r"
        exp_continue
    }
    eof
}
