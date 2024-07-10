#!/bin/bash

function read_config() {
    config_file=$1
    section=$2
    param=$3

    value=($(toml get ${section}.${param} --toml-path ${config_file}))

    # Read from common section if not found in the provided section
    if [ "$value" == "" ]; then
        value=($(toml get common.${param} --toml-path ${config_file}))
    fi

    echo "${value}"
}

function read_machine_config() {
machine=$1
config=$2
bsp_version=${3}

    read_config ${topdir}/configs/machines/${bsp_version}.yaml $machine $config
}

function read_bsp_config() {
bsp_version=$1
config=$2

    read_config ${topdir}/configs/bsp_sources.toml $bsp_version $config
}

function read_build_config() {
build=$1
config=$2

    read_config ${topdir}/builds.toml $build $config
}

function validate_section() {
section_type=$1
section=$2
config=$3

    if  ! grep -q -x "\[$section\]" ${config}  ; then
        log "${section_type} \"${section}\" does not exist. Exiting."
        exit 1
    fi
}

function validate_build() {
machine=$1
bsp_version=$2
distro_file=$3

    validate_section "BSP Version" ${bsp_version} "${topdir}/configs/bsp_sources.toml"
    validate_section "Machine" ${machine} "${topdir}/configs/machines/${bsp_version}.yaml"

    if [ ! -f "${topdir}/configs/bdebstrap_configs/${distro_file}" ] ; then
        log "Distro Variant \"${distro_file}\" does not exist. Exiting."
        exit 1
    fi
}

function log() {
    command echo "$@"
    command echo "$@" >> "$LOG_FILE"
}
