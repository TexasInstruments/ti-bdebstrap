#!/bin/bash

source ${topdir}/scripts/common.sh

function generate_rootfs() {
distro=$1
distro_codename=$2
machine=$3

    cd ${topdir}

    log "> Building rootfs .."
    bdebstrap \
        -c ${topdir}/configs/bdebstrap_configs/${distro_codename}/${distro}.yaml \
        --name ${topdir}/build/${distro} \
        --target tisdk-debian-${distro}-rootfs \
        --hostname ${machine} \
        -f \
        &>>"${LOG_FILE}"

    cd ${topdir}/build/

    ROOTFS_DIR=${topdir}/build/${distro}/tisdk-debian-${distro}-rootfs
}

function package_and_clean() {
build=$1

    cd ${topdir}/build/${build}

    log "> Cleaning up ${build}"
    tar --use-compress-program="pigz --best --recursive | pv" -cf tisdk-debian-${distro}-rootfs.tar.xz tisdk-debian-${distro}-rootfs &>>"${LOG_FILE}"
    rm -rf tisdk-debian-${distro}-rootfs

    tar --use-compress-program="pigz --best --recursive | pv" -cf tisdk-debian-${distro}-boot.tar.xz tisdk-debian-${distro}-boot &>>"${LOG_FILE}"
    rm -rf tisdk-debian-${distro}-boot

    rm -rf bsp_sources

    cd ${topdir}/build/

    log "> Packaging ${build}"
    tar --use-compress-program="pigz --best --recursive | pv" -cf ${build}.tar.xz ${build} &>>"${LOG_FILE}"
}

