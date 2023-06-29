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

    read_config ${topdir}/configs/machines.toml $machine $config
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

function log() {
    command echo "$@"
    command echo "$@" >> "$LOG_FILE"
}
