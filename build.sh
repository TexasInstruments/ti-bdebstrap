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

setup_build_tools

for build in ${builds}
do

    echo "${build}"
    setup_log_file "${build}"

    machine=($(read_build_config ${build} machine))
    bsp_version=($(read_build_config ${build} bsp_version))
    distro_variant=($(read_build_config ${build} distro_variant))

    echo "machine: ${machine}"
    echo "bsp_version: ${bsp_version}"
    echo "distro_variant: ${distro_variant}"

    generate_rootfs ${build} ${machine} ${distro_variant}
    build_bsp ${build} ${machine} ${bsp_version}
    # FIXME: Kernel and IMG rogue driver should be .deb packages
    build_kernel ${machine} ${ROOTFS_DIR}
    build_ti_img_rogue_driver ${machine} ${ROOTFS_DIR} ${KERNEL_DIR}
    package_and_clean ${build}

done

