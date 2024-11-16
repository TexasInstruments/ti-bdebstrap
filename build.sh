#!/bin/bash
# Filename: build.sh
# Author: "Sai Sree Kartheek Adivi <s-adivi@ti.com>"
# Description: Script to build a Debian SD card image for TI Platforms
###############################################################################

# set -x

export topdir=$(git rev-parse --show-toplevel)

source ${topdir}/scripts/setup.sh
source ${topdir}/scripts/common.sh
source ${topdir}/scripts/build_bsp.sh
source ${topdir}/scripts/build_distro.sh

if [ "$EUID" -ne 0 ] ; then
    echo "Failed to run: requires root privileges"
    echo "Exiting"
    exit 1
fi

# exit if no arguments are passed
if [ "$#" -ne 0 ]; then
    builds="$@"
else
    echo "build.sh: missing operand"
    echo "Specify one or more builds from the \"builds.toml\" file."
    exit 1
fi

mkdir -p ${topdir}/build

for build in ${builds}
do

    echo "${build}"

    validate_section "Build" ${build} "${topdir}/builds.toml"

    machine=($(read_build_config ${build} machine))
    distro_codename=($(read_build_config ${build} distro_codename))
    rt_linux=($(read_build_config ${build} rt_linux))

    if [ ${rt_linux} == "true" ]; then
        distro=${distro_codename}-rt-${machine}
    else
        distro=${distro_codename}-${machine}
    fi

    bsp_version=($(read_bsp_config ${distro_codename} bsp_version))

    export host_arch=`uname -m`
    export native_build=false
    export cross_compile=aarch64-none-linux-gnu-
    if [ "$host_arch" == "aarch64" ]; then
        native_build=true
        cross_compile=
    fi

    echo "machine: ${machine}"
    echo "bsp_version: ${bsp_version}"
    echo "distro: ${distro}"
    echo "host_arch: ${host_arch}"

    setup_build_tools

    setup_log_file "${build}"

    validate_build ${machine} ${bsp_version} ${distro_codename}/${distro}.yaml

    generate_rootfs ${distro} ${distro_codename} ${machine}
    # build_bsp ${distro} ${machine} ${bsp_version}
    package_and_clean ${distro}

done

