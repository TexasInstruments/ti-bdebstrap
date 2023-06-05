#!/bin/bash

builds=($(toml get builds --toml-path ${topdir}/builds.toml | tr -d "[],'"))

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

# There are many echo statements in the scripts. To save the scripts from being
# cluttered by twice the number of "echo" statements, override the "echo"
# command to call the original "echo" twice behind-the-scenes.
echo() {
	command echo "$@"
	command echo "$@" >> "$LOG_FILE"
	#run_cmd command echo "$@"
}
