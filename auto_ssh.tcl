#!/usr/bin/expect -f

package require cmdline

proc getDirectory {} {
    variable myLocation [file normalize [info script]]
    return [file dirname $myLocation]
}

set PROG_DIR  [getDirectory]

# read config from outside
source "${PROG_DIR}/config"
#source "${PROG_DIR}/external_commands.tcl"

set MASTER_PASS ""
set PARAMETERS {
    {c.arg  ""   "create a password-file, encrypting the file provided."}
    {d.arg  ""   "dump the password-file into the specified file."}
    {x.arg  ""   "extract only the specified password."}
    {env         "retrieve master-password from ENV."}
    {str         "encrypt a string asked on prompt. (Useful to set the master-password in an ENV var)."}
}

# ------------------------------------------------------------------------------
proc get_server_info {category nick1 nick2 nick3} {
    global FILE_HOSTS

    set host ""
    set user ""
    set pass_key ""
    set external_cmd ""

    set fp [open $FILE_HOSTS r]
    while {-1 != [gets $fp line]} {
        regsub -all {[ \t]} $line {} line
        if [
           regexp -nocase "${category},${nick1},${nick2},${nick3},\(\[\^,\]\+\),\(\[\^,\]\+\),\(\[\^,\]\+\),\?\(\.\*\)" $line match user host pass_key external_cmd
           ] then {
           break
        }
    }
    close $fp
    return [list $user $host $pass_key $external_cmd]
}
# ------------------------------------------------------------------------------
proc read_pass_file {} {
    global CIPHER_ALG
    global MASTER_PASS
    global FILE_PASS

    set exit_code [catch {exec openssl $CIPHER_ALG -d -pass pass:$MASTER_PASS -in $FILE_PASS} pass_list]
    if { $exit_code != 0 } {
        puts "Master password doesn't match with $FILE_PASS"
    }

    return [list $exit_code $pass_list]
}
# ------------------------------------------------------------------------------
proc prompt_for_masterp {prompt_text} {

    set input ""

    stty -echo
    send_user -- $prompt_text
    expect_user -re "(.*)\n"
    send_user "\n"
    stty echo

    catch {set input $expect_out(1,string)}
    if { $input eq "" } { exit }

    return $input
}
# ------------------------------------------------------------------------------
proc init_masterp {from_env} {
    global env
    global CIPHER_ALG
    global MASTER_PASS
    global CONFIG_MP_KEY
    global CONFIG_MP

    if { $from_env } {
        catch {set env_value "$env($CONFIG_MP)"} err
        set exit_code [catch {exec echo $env_value | openssl $CIPHER_ALG -d -a -pass pass:$CONFIG_MP_KEY} MASTER_PASS ]
        if { $exit_code == 0 } { return }

        puts "Unable to read master-password from env-var"
    }
    set MASTER_PASS [prompt_for_masterp "give master password:"]
}
# ------------------------------------------------------------------------------
proc set_masterp_for_env {} {
    global CIPHER_ALG
    global CONFIG_MP_KEY

    set masterp [prompt_for_masterp "give a string to be encrypted:"]
    set exit_code [catch {exec echo $masterp | openssl $CIPHER_ALG -a -pass pass:$CONFIG_MP_KEY} encrypt ]
    if { $exit_code == 0 } {
        set $encrypt ""
    }
    return $encrypt
}
# ------------------------------------------------------------------------------
proc get_pass_val {type pass_key} {
    global MASTER_PASS
    set pass_val ""

    puts "look up with pass-key: \[$pass_key]"
    set result [read_pass_file]
    set exit_code [lindex $result 0]
    set pass_list [split [lindex $result 1] "\n" ]

    if { $exit_code == 0 } {
        if { $type eq "i" } {
            set regex_str "\^\[ \\t\]\*i:\[ \\t]\*${pass_key}\[ \\t]\*,\(\.\+\)"
        } else {
            set regex_str "\^\[ \\t\]\*${pass_key}\[ \\t]\*,\(\.\+\)"
        }
        foreach line $pass_list {
            if [
               regexp -nocase $regex_str $line match pass_val
               ] then {
               break
            }
        }
    }
    return $pass_val
}
# ------------------------------------------------------------------------------
proc dump_pass_file {filename} {
    global MASTER_PASS

    set result [read_pass_file]
    set exit_code [lindex $result 0]

    if { $exit_code == 0 } {
        if [catch {set fp [open $filename w] }] {
            puts "unable to create file $filename"
        } else {
            puts $fp [lindex $result 1]
            close $fp
        }
    }
}
# ------------------------------------------------------------------------------
proc create_pass_file {filename} {
    global MASTER_PASS
    global FILE_PASS
    global CIPHER_ALG

    if { [file exist $filename] != 1 } {
        puts "file $filename does not exist"
        return
    }
    set exit_code [catch {exec cp $FILE_PASS ${FILE_PASS}.bk } errmsg]
    if { $exit_code == 0 } {
       puts "created backup: \[${FILE_PASS}.bk] for old file"
    }

    exec openssl $CIPHER_ALG -pass pass:$MASTER_PASS -in $filename -out $FILE_PASS

    catch {exec cat $filename | tr "\t" " " |  sed -n -E -e {s/((, | $))/\1<-- (space here) /p} } warn_lines
    if { $warn_lines ne "" } {
        set F_FG_RED [exec tput setaf 1]
        set F_RESET [exec tput sgr0]

        puts "\n$F_FG_RED Are you happy with these spaces/tabs ? $F_RESET\n\n $warn_lines"
    }
}
# ------------------------------------------------------------------------------
proc ssh {type user host pass ext_cmd} {
    puts " tryng to connect to ${user}@$host"
    if { $type eq "i" } {
        regsub -all {[ \t]} $pass {} pass
        spawn ssh -i  $pass ${user}@$host

    } else {
        # -o "StrictHostKeyChecking no"  to avoid typing 'yes' on "Are you sure you want to continue connecting (yes/no)?"
        spawn ssh -o "StrictHostKeyChecking no" -t ${user}@$host "HISTCONTROL=ignoreboth bash -l"
        expect "assword:*"
        send -- "$pass\r"
    }

    #if { $ext_cmd ne "" } {
    #    #wait for prompt
    #    #expect -re "> ?$"
    #    expect -re "\[>~$\]"
    #    external_cmd $user $host $pass $ext_cmd
    #}

    interact
}
# ------------------------------------------------------------------------------
proc check_files {} {
    global FILE_HOSTS
    global FILE_PASS

    if { [file exist $FILE_HOSTS] != 1 } {
        puts "missing file $FILE_HOSTS "
        return 1
    }
    if { [file exist $FILE_PASS] != 1 } {
        puts "missing file $FILE_PASS "
        return 1
    }
    return 0
}
# ------------------------------------------------------------------------------
proc print_usage {} {
    global PARAMETERS
    global FILE_HOSTS

    set usage ""
    foreach p $PARAMETERS {
        set p_name     [lindex $p 0]
        regsub {\.arg$} $p_name { file} p_name
        append usage  "\[-$p_name]"
    }
    append usage " \[category \[nick1] \[nick2] \[nick3]]\n"
    append usage "\n\t prog to ssh into the server matched in $FILE_HOSTS by category/nick1/nick2/nick3\n"
    puts [cmdline::usage $PARAMETERS $usage]
}
# ------------------------------------------------------------------------------
proc main {} {
    global argv
    global FILE_HOSTS
    global FILE_PASS
    global PARAMETERS
    global MASTER_PASS

    set err 0

    while {1} {

        if { [catch {array set options [cmdline::getoptions ::argv $PARAMETERS]}] } {
            set err 1
            break
        }

        if { $options(str) != 0 } { # 1. propmpt for a string and return it encrypted
            set masterp [set_masterp_for_env]
            puts $masterp
            break
        }

        init_masterp $options(env)


        if { $options(d) ne "" } {  # 2. dump
            dump_pass_file $options(d)
            break
        }
        if { $options(c) ne "" } {  # 3. create
            create_pass_file $options(c)
            break
        }

        if { $options(x) ne "" } {  # 4 extract only password
            set pass [get_pass_val "" $options(x)]
            puts $pass
            break
        }

        #--------------------------   5. then go for ssh
        set category   [lindex $argv 0]
        set nick1      [lindex $argv 1]
        set nick2      [lindex $argv 2]
        set nick3      [lindex $argv 3]

        if { $category eq "" || [check_files] != 0 } { # ssh
            set err 1
            break
        }

        set server_info [get_server_info $category $nick1 $nick2 $nick3]
        set user     [lindex $server_info 0]
        set host     [lindex $server_info 1]
        set pass_key [lindex $server_info 2]
        set ext_cmd  [lindex $server_info 3]

        if { $pass_key eq "" } {
            puts "no match found for \[$category\] \[$nick1\] \[$nick2\] \[$nick3\] in $FILE_HOSTS"
        } else {
            if [
               regexp -nocase "\(\[\^:\]\*\):\?\(\.\*\)\$" $pass_key match type val
               ] then {

                if { $type eq "2fa" } {      # "2fa:" dual factor auth.  Not much we can do. Just print the ssh command
                    puts "ssh $user@$host"
                } else {
                    if { $val eq "" } {      # :xxxxx or xxxxx are matched all into $type. Swap with $val"
                        set val $type
                        set type ""
                    }
                    set pass [get_pass_val $type $val]
                    if { $pass eq "" } {
                        puts "no pass found for type:\[${type}\] val:\[${val}\] in ${FILE_PASS}"
                    } else {
                        ssh $type $user $host $pass $ext_cmd
                    }
                }
            }
        }
        break
    }

    if { $err != 0 } { print_usage }
}

# ------------------------------------------------------------------------------
main

