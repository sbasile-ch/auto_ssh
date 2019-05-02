#!/bin/bash

AUTO_SSH_DIR=${HOME}/auto_ssh

function get_column {
    local C1=$1
    local C2=$2
    local col=$3
    OPTIONS=$(cat ${AUTO_SSH_DIR}/known_hosts | awk -v C1=$C1 -v C2=$C2 -v c=$col 'BEGIN{FS=","} {if(NF==7 && match($1,C1) && match($2,C2)){print $c}}' | sort -u)
}

function _ssh {
    echo $1 $2 $3
    #${AUTO_SSH_DIR}/assh -- -mp $1 $2 $3
    exit
}

get_column "" "" 1
select service in ${OPTIONS[*]}; do break; done

if [ ${#OPTIONS[@]} ]
then
    get_column $service "" 2
    select system in ${OPTIONS[*]}; do break; done

    if [ ${#OPTIONS[@]} ]
    then
        get_column $service $system 3
        select instance in ${OPTIONS[*]}; do break; done
    fi
fi

_ssh $service $system $instance

