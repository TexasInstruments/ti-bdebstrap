#!/bin/bash

function generate_rootfs() {
build=$1
machine=$2
distro=$3

    hostname=($(read_machine_config ${machine} hostname))
    bdebstrap \
        -c ${topdir}/configs/bdebstrap_configs/${distro}.yaml \
        --name ${topdir}/build/${build} \
        --target tisdk-${distro}-${machine}-rootfs \
        --hostname "${hostname}" -f

    cd ${topdir}/build/

    ROOTFS_DIR=${topdir}/build/${build}/tisdk-${distro}-${machine}-rootfs
}

function package_and_clean() {
build=$1
    
    cd ${topdir}/build/${build}

    echo "> Cleaning up ${build}"
    cd tisdk-${distro}-${machine}-rootfs
    tar --use-compress-program="pigz --best --recursive | pv" -cf ../tisdk-${distro}-${machine}-rootfs.tar.xz *
    cd ../
    rm -rf tisdk-${distro}-${machine}-rootfs

    cd tisdk-${distro}-${machine}-boot
    tar --use-compress-program="pigz --best --recursive | pv" -cf ../tisdk-${distro}-${machine}-boot.tar.xz *
    cd ../
    rm -rf tisdk-${distro}-${machine}-boot

    rm -rf bsp_sources

    cd ${topdir}/build/

    echo "> Packaging ${build}"
    tar --use-compress-program="pigz --best --recursive | pv" -cf ${build}.tar.xz ${build}
}

