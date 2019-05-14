#!/bin/bash

AUTO_SSH_DIR=${HOME}/auto_ssh

CHOICE_VARS=('' '' '' '')   # category / nick1 / nick2 / nick3

#--------------------------------------
function get_column {
    local C1=$1
    local C2=$2
    local C3=$3
    local col=$4
    OPTIONS=$(cat ${AUTO_SSH_DIR}/known_hosts | sed -e 's/#.*$//' | tr -d '[:blank:]' | awk -v C1="$C1" -v C2="$C2" -v C3="$C3" -v c="$col" \
        'BEGIN{FS=","} {if(NF>=7 && (C1=="" || ($1==C1 && (C2=="" || ($2==C2 && (C3=="" || $3==C3)))))){print $c}}' | sort -u)
}
#--------------------------------------
function sep {
    echo $(printf '=%.0s' {1..80})
}

#--------------------------------------
function choose {
    local max=${#CHOICE_VARS[@]}
    for c in $(seq 1 $max); do
        get_column "${CHOICE_VARS[0]}" "${CHOICE_VARS[1]}" "${CHOICE_VARS[2]}" $c
        local num_options=${#OPTIONS[@]}
        if [ $num_options ]
        then
            echo $(printf '=%.0s' {1..80})
            select option in ${OPTIONS[*]};
            do
                if [ "$option" ];
                then
                    CHOICE_VARS[$((c-1))]="${option}"
                    break
                else
                    echo "Invalid entry."
                fi
            done
        else
            break
        fi
    done
}
#--------------------------------------
choose
sep
${AUTO_SSH_DIR}/auto_ssh.tcl -- -env ${CHOICE_VARS[*]}

