#!/bin/bash

distros=($(basename -s ".yaml" -a `ls ${topdir}/configs/*.yaml`))

machines=(`${topdir}/scripts/read-config.py ${topdir}/machines.ini`)

function read_machine_config() {
    section=$1
    param=$2

    value=`${topdir}/scripts/read-config.py ${topdir}/machines.ini ${section} ${param}`

    if [ "$value" == "" ]; then
        value=`${topdir}/scripts/read-config.py ${topdir}/machines.ini "common" ${param}`
    fi

    echo "${value}"
}


