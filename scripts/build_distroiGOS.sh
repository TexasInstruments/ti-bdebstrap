#!/bin/bash

source ${topdir}/scripts/common.sh

function generate_rootfs() {
distro=$1
distro_codename=$2
machine=$3
bsp_version=$4

    cd ${topdir}

    log "> Building rootfs .."
    bdebstrap \
        -c ${topdir}/configs/bdebstrap_configs/${distro_codename}/${distro}.yaml \
        --name ${topdir}/build/${distro} \
        --target tisdk-debian-${distro}-${bsp_version}-rootfs \
        --hostname ${machine} \
        -f \
        &>>"${LOG_FILE}"

    cd ${topdir}/build/

    ROOTFS_DIR=${topdir}/build/${distro}/tisdk-debian-${distro}-rootfs
}

function package_and_clean() {
build=$1
bsp_version=$2

    mkdir -p ${topdir}/images/${build}
    cd ${topdir}/build/${build}
    rm -rf tisdk-debian-${distro}-${bsp_version}-rootfs
    cp -ra ../fs/ tisdk-debian-${distro}-${bsp_version}-rootfs

    log "> Cleaning up ${build}"
#    If we tar file system, it cause to be missing special file capabilities. (by Dennis Kong).
#    So we will not tar it and copy the folder to SD card directly (Inside "create-sdcardiGOS.sh" line 715)
#    refer to commit 351c0c1cbc1189fb659295251674e51799dd8be4
#    tar --use-compress-program="pigz --best --recursive | pv" -cf tisdk-debian-${distro}-${bsp_version}-rootfs.tar.xz tisdk-debian-${distro}-${bsp_version}-rootfs &>>"${LOG_FILE}"
#    rm -rf tisdk-debian-${distro}-${bsp_version}-rootfs

# latest changes to save the boot and rootfs inside squashfs files that preserve capabilites and file attrs and allows portability in burning an sdcard 
    mksquashfs tisdk-debian-${distro}-${bsp_version}-rootfs tisdk-debian-${distro}-${bsp_version}-rootfs.squashfs -comp xz -noappend  &>>"${LOG_FILE}"
    mv tisdk-debian-${distro}-${bsp_version}-rootfs.squashfs ${topdir}/images/${build}

#   tar --use-compress-program="pigz --best --recursive | pv" -cf tisdk-debian-${distro}-${bsp_version}-boot.tar.xz tisdk-debian-${distro}-${bsp_version}-boot &>>"${LOG_FILE}"
#   rm -rf tisdk-debian-${distro}-${bsp_version}-boot

    mksquashfs tisdk-debian-${distro}-${bsp_version}-boot tisdk-debian-${distro}-${bsp_version}-boot.squashfs -comp xz -noappend &>>"${LOG_FILE}"
    mv tisdk-debian-${distro}-${bsp_version}-boot.squashfs ${topdir}/images/${build}

    rm -rf bsp_sources

    cd ${topdir}/build/

    log "> Packaging ${build}"
    tar --use-compress-program="pigz --best --recursive | pv" -cf ${distro}-${bsp_version}.tar.xz ${build} &>>"${LOG_FILE}"
}
