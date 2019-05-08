#!/usr/bin/expect -f

proc su_user {user pass_key} {

    set pass [get_pass_val "" $pass_key]
    #puts " tryng to sudo -  ${user} == $pass"
    send -- "su - $user\r"
    expect "assword:*"
    send -- "$pass\r"
}

# ------------------------------------------------------------------------------
proc external_cmd {user host pass ext_cmd} {

    #puts "received $ext_cmd"
    regexp "\(\[\^:\]\+\):\?\(\.\*\)\$" $ext_cmd all cmd args
    #puts "extracted $cmd -- $args"
    switch $cmd {
        "su_user" {
            su_user $user $args
        }
        default {
            puts "No external command found for $cmd"
        }
    }
}

# ------------------------------------------------------------------------------

