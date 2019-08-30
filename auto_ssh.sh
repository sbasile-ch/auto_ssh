#!/usr/local/bin/bash      #wherever a bash 4 is

AUTO_SSH_DIR=${HOME}/auto_ssh

CHOICE_VARS=('' '' '' '')   # category / nick1 / nick2 / nick3
PRE_CHOICE=($1 $2 $3 $4)    # to skip all the selects in repetitive known journeys

#--------------------------------------
function get_column {
    local C1=$1
    local C2=$2
    local C3=$3
    local col=$4
    OPTIONS=$(cat ${AUTO_SSH_DIR}/known_hosts | sed -e 's/#.*$//' | tr -d '[:blank:]' | awk -v C1="$C1" -v C2="$C2" -v C3="$C3" -v c="$col" \
        'BEGIN{FS=","} {if(NF>=7 && (C1=="" || ($1==C1 && (C2=="" || ($2==C2 && (C3=="" || $3==C3)))))){print $c}}' | sort -u)
    readarray -t OPTIONS <<<"$OPTIONS"
}
#--------------------------------------
function sep {
    echo $(printf '=%.0s' {1..80})
}

#--------------------------------------
function choose {
    local max=${#CHOICE_VARS[@]}
    local pre_ch_journey=
    for c in $(seq 1 $max); do
        get_column "${CHOICE_VARS[0]}" "${CHOICE_VARS[1]}" "${CHOICE_VARS[2]}" $c
        local num_options=${#OPTIONS[@]}
        if [ $num_options ]
        then
            local option=${PRE_CHOICE[$((c-1))]}   # check if a pre_choice was specified
            if [ "$option" ]
            then
                pre_ch_journey="${pre_ch_journey}[${option}:"
                option=${OPTIONS[$(($option-1))]}
                pre_ch_journey="${pre_ch_journey}${option}]"
            else
                sep
                select option in ${OPTIONS[*]};
                do
                    if [ "$option" ];
                    then
                        break
                    else
                        echo "Invalid entry."
                    fi
                done
            fi
            CHOICE_VARS[$((c-1))]="${option}"
        else
            break
        fi
    done
    if [ $pre_ch_journey ]
    then
        echo "connecting with ${pre_ch_journey}"
    fi
}
#--------------------------------------
choose
sep
${AUTO_SSH_DIR}/auto_ssh.tcl -- -env ${CHOICE_VARS[*]}

