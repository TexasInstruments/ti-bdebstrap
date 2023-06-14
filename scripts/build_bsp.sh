#!/bin/bash

function build_bsp() {
build=$1
machine=$2
bsp_version=$3

    setup_bsp_build ${build} ${machine} ${bsp_version}
    build_atf $machine
    build_optee $machine
    build_uboot $machine
}


function setup_bsp_build() {
build=$1
machine=$2
bsp_version=$3

    mkdir -p ${topdir}/build/${build}/bsp_sources; cd ${topdir}/build/${build}/bsp_sources

    log "> BSP sources: checking .."

    if [ ! -d trusted-firmware-a ]; then
        cd ${topdir}/build/${build}/bsp_sources
        log ">> atf: not found. cloning .."
        atf_srcrev=($(read_bsp_config ${bsp_version} atf_srcrev))

        git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git &>>"${LOG_FILE}"

        cd trusted-firmware-a
        git checkout ${atf_srcrev} &>>"${LOG_FILE}"
        cd ..
        log ">> atf: cloned"
    else
        log ">> core-secdev-k3: available"
    fi
    TFA_DIR=${topdir}/build/${build}/bsp_sources/trusted-firmware-a

    if [ ! -d optee_os ]; then
        cd ${topdir}/build/${build}/bsp_sources
        log ">> optee_os: not found. cloning .."
        optee_srcrev=($(read_bsp_config ${bsp_version} optee_srcrev))

        git clone https://github.com/OP-TEE/optee_os.git &>>"${LOG_FILE}"

        cd optee_os
        git checkout ${optee_srcrev} &>>"${LOG_FILE}"
        cd ..
        log ">> optee_os: cloned"
    else
        log ">> optee_os: available"
    fi
    OPTEE_DIR=${topdir}/build/${build}/bsp_sources/optee_os

    if [ ! -d ti-u-boot ]; then
        cd ${topdir}/build/${build}/bsp_sources
        log ">> ti-u-boot: not found. cloning .."
        uboot_srcrev=($(read_bsp_config ${bsp_version} uboot_srcrev))
        git clone \
            https://git.ti.com/git/ti-u-boot/ti-u-boot.git \
            -b ${uboot_srcrev} \
            --single-branch \
            --depth=1 &>>"${LOG_FILE}"
        log ">> ti-u-boot: cloned"
        if [ -d ${topdir}/patches/ti-u-boot ]; then
            log ">> ti-u-boot: patching .."
            cd ti-u-boot
            git apply ${topdir}/patches/ti-u-boot/* &>>"${LOG_FILE}"
            cd ..
        fi
    else
        log ">> ti-u-boot: available"
    fi
    UBOOT_DIR=${topdir}/build/${build}/bsp_sources/ti-u-boot

    if [ ! -d ti-linux-firmware ]; then
        cd ${topdir}/build/${build}/bsp_sources
        log ">> ti-linux-firmware: not found. cloning .."
        linux_fw_srcrev=($(read_bsp_config ${bsp_version} linux_fw_srcrev))
        git clone \
            https://git.ti.com/git/processor-firmware/ti-linux-firmware.git \
            -b ${linux_fw_srcrev} \
            --single-branch \
            --depth=1 &>>"${LOG_FILE}"
        log ">> ti-linux-firmware: cloned"
    else
        log ">> ti-linux-firmware: available"
    fi
    dmfw_machine=($(read_machine_config ${machine} dmfw_machine))
    SYSFW_DIR=${topdir}/build/${build}/bsp_sources/ti-linux-firmware/ti-sysfw
    DMFW_DIR=${topdir}/build/${build}/bsp_sources/ti-linux-firmware/ti-dm/${dmfw_machine}

    if [ ! -d ti-linux-kernel ]; then
        cd ${topdir}/build/${build}/bsp_sources
        log ">> ti-linux-kernel: not found. cloning .."
        linux_kernel_srcrev=($(read_bsp_config ${bsp_version} linux_kernel_srcrev))
        git clone \
            https://git.ti.com/git/ti-linux-kernel/ti-linux-kernel.git \
            -b ${linux_kernel_srcrev} \
            --single-branch \
            --depth=1 &>>"${LOG_FILE}"
        log ">> ti-linux-kernel: cloned"
        if [ -d ${topdir}/patches/ti-linux-kernel ]; then
            log ">> ti-linux-kernel: patching .."
            cd ti-linux-kernel
            git apply ${topdir}/patches/ti-linux-kernel/*
            cd ..
        fi
    else
        log ">> ti-linux-kernel: available"
    fi
    KERNEL_DIR=${topdir}/build/${build}/bsp_sources/ti-linux-kernel

    if [ ! -d ti-img-rogue-driver ]; then
        cd ${topdir}/build/${build}/bsp_sources
        log ">> ti-img-rogue-driver: not found. cloning .."
        img_rogue_driver_srcrev=($(read_bsp_config ${bsp_version} img_rogue_driver_srcrev))
        git clone \
            https://git.ti.com/git/graphics/ti-img-rogue-driver.git \
            -b ${img_rogue_driver_srcrev} \
            --single-branch \
            --depth=1 &>>"${LOG_FILE}"
        log ">> ti-img-rogue-driver: cloned"
        if [ -d ${topdir}/patches/ti-img-rogue-driver ]; then
            log ">> ti-img-rogue-driver: patching .."
            cd ti-img-rogue-driver
            git apply ${topdir}/patches/ti-img-rogue-driver/* &>>"${LOG_FILE}"
            cd ..
        fi
    else
        log ">> ti-img-rogue-driver: available"
    fi
    IMG_ROGUE_DRIVER_DIR=${topdir}/build/${build}/bsp_sources/ti-img-rogue-driver

    log "> BSP sources: cloned"
    log "> BSP sources: creating backup .."
    cd ${topdir}/build/${build}
    tar --use-compress-program="pigz --best --recursive | pv" -cf bsp_sources.tar.xz bsp_sources &>>"${LOG_FILE}"
    log "> BSP sources: backup created .."

    mkdir -p tisdk-${distro}-${machine}-boot
}

function build_atf() {
machine=$1

    cd $TFA_DIR
    target_board=($(read_machine_config ${machine} atf_target_board))

    log "> ATF: building .."
    make -j`nproc` ARCH=aarch64 CROSS_COMPILE=aarch64-none-linux-gnu- PLAT=k3 TARGET_BOARD=${target_board} SPD=opteed &>>"${LOG_FILE}"

    log "> ATF: signing .."
}

function build_optee() {
machine=$1

    cd ${OPTEE_DIR}
    platform=($(read_machine_config ${machine} optee_platform))

    log "> optee: building .."
    make -j`nproc` CROSS_COMPILE64=aarch64-none-linux-gnu- CROSS_COMPILE=arm-none-linux-gnueabihf- PLATFORM=${platform} CFG_ARM64_core=y &>>"${LOG_FILE}"

    log "> optee: signing .."
}

function build_uboot() {
machine=$1

    uboot_r5_defconfig=($(read_machine_config ${machine} uboot_r5_defconfig))
    uboot_a53_defconfig=($(read_machine_config ${machine} uboot_a53_defconfig))
    sysfw_soc=($(read_machine_config ${machine} sysfw_soc))

    log "> dmfw: signing .."

    cd ${UBOOT_DIR}
    log "> uboot-r5: building .."
    make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- ${uboot_r5_defconfig} O=${UBOOT_DIR}/out/r5 &>>"${LOG_FILE}"
    make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- O=${UBOOT_DIR}/out/r5 BINMAN_INDIRS=${topdir}/build/${build}/bsp_sources/ti-linux-firmware &>>"${LOG_FILE}"
    cp ${UBOOT_DIR}/out/r5/tiboot3*.bin ${topdir}/build/${build}/tisdk-${distro}-${machine}-boot/ &>> ${LOG_FILE}

    # TODO: Also build for GP and HS
    # make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- SOC=${sysfw_soc} SOC_TYPE=gp SBL=${UBOOT_DIR}/out/r5/spl/u-boot-spl.bin SYSFW_DIR=${SYSFW_DIR}
    # make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- SOC=${sysfw_soc} SOC_TYPE=hs SBL=${UBOOT_DIR}/out/r5/spl/u-boot-spl.bin SYSFW_DIR=${SYSFW_DIR}

    cd ${UBOOT_DIR}
    log "> uboot-a53: building .."
    make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-none-linux-gnu- ${uboot_a53_defconfig} O=${UBOOT_DIR}/out/a53 &>>"${LOG_FILE}"
    make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-none-linux-gnu- BL31=${TFA_DIR}/build/k3/lite/release/bl31.bin TEE=${OPTEE_DIR}/out/arm-plat-k3/core/tee-pager_v2.bin O=${UBOOT_DIR}/out/a53 BINMAN_INDIRS=${topdir}/build/${build}/bsp_sources/ti-linux-firmware &>>"${LOG_FILE}"
    cp ${UBOOT_DIR}/out/a53/tispl.bin ${topdir}/build/${build}/tisdk-${distro}-${machine}-boot/ &>> ${LOG_FILE}
    cp ${UBOOT_DIR}/out/a53/u-boot.img ${topdir}/build/${build}/tisdk-${distro}-${machine}-boot/ &>> ${LOG_FILE}
}

function build_kernel() {
machine=$1
rootfs_dir=$2

    cd ${KERNEL_DIR}

    log "kernel: generating defconfig .."
    make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig ti_arm64_prune.config &>>"${LOG_FILE}"

    log "kernel: building Image .."
    make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- Image &>>"${LOG_FILE}"

    log "kernel: building DTBs .."
    make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs &>>"${LOG_FILE}"

    log "kernel: building modules .."
    make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules &>>"${LOG_FILE}"

    log "kernel: installing Image .."
    cp arch/arm64/boot/Image ${rootfs_dir}/boot/

    log "kernel: installing DTBs .."
    mkdir -p ${rootfs_dir}/boot/dtb
    cp -rf arch/arm64/boot/dts/ti ${rootfs_dir}/boot/dtb/

    log "kernel: installing modules .."
    make ARCH=arm64  INSTALL_MOD_PATH=${rootfs_dir} modules_install &>>"${LOG_FILE}"
}

function build_ti_img_rogue_driver() {
machine=$1
rootfs_dir=$2
kernel_dir=$3

    pvr_target=($(read_machine_config ${machine} pvr_target))
    pvr_window_system=($(read_machine_config ${machine} pvr_window_system))
    cd ${IMG_ROGUE_DRIVER_DIR}

    log "ti-img-rogue-driver: building .."
    make CROSS_COMPILE=aarch64-none-linux-gnu- ARCH=arm64 KERNELDIR=${kernel_dir} RGX_BVNC="33.15.11.3" BUILD=release PVR_BUILD_DIR=${pvr_target} WINDOW_SYSTEM=${pvr_window_system} &>>"${LOG_FILE}"

    log "ti-img-rogue-driver: installing .."
    cd binary_am62_linux_wayland_release/target_aarch64/kbuild
    make -C ${kernel_dir} ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- INSTALL_MOD_PATH=${rootfs_dir} INSTALL_MOD_STRIP=1 M=`pwd` modules_install &>>"${LOG_FILE}"
}
