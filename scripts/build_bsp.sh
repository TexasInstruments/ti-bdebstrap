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

    echo "> BSP sources: checking .."
    if [ ! -d core-secdev-k3 ]; then
        echo ">> core-secdev-k3: not found. cloning .."
        git clone \
            https://git.ti.com/git/security-development-tools/core-secdev-k3.git \
            --single-branch \
            --depth=1
        echo ">> core-secdev-k3: cloned"
    else
        echo ">> core-secdev-k3: available"
    fi
    TI_SECURE_DEV_PKG=${topdir}/build/${build}/bsp_sources/core-secdev-k3

    if [ ! -d trusted-firmware-a ]; then
        cd ${topdir}/build/${build}/bsp_sources
        echo ">> atf: not found. cloning .."
        atf_srcrev=($(read_bsp_config ${bsp_version} atf_srcrev))

        git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git

        cd trusted-firmware-a
        git checkout ${atf_srcrev}
        cd ..
        echo ">> atf: cloned"
    else
        echo ">> core-secdev-k3: available"
    fi
    TFA_DIR=${topdir}/build/${build}/bsp_sources/trusted-firmware-a

    if [ ! -d optee_os ]; then
        cd ${topdir}/build/${build}/bsp_sources
        echo ">> optee_os: not found. cloning .."
        optee_srcrev=($(read_bsp_config ${bsp_version} optee_srcrev))

        git clone https://github.com/OP-TEE/optee_os.git

        cd optee_os
        git checkout ${optee_srcrev}
        cd ..
        echo ">> optee_os: cloned"
    else
        echo ">> optee_os: available"
    fi
    OPTEE_DIR=${topdir}/build/${build}/bsp_sources/optee_os

    if [ ! -d ti-u-boot ]; then
        cd ${topdir}/build/${build}/bsp_sources
        echo ">> ti-u-boot: not found. cloning .."
        uboot_srcrev=($(read_bsp_config ${bsp_version} uboot_srcrev))
        git clone \
            https://git.ti.com/git/ti-u-boot/ti-u-boot.git \
            -b ${uboot_srcrev} \
            --single-branch \
            --depth=1
        echo ">> ti-u-boot: cloned"
        if [ -d ${topdir}/patches/ti-u-boot ]; then
            echo ">> ti-u-boot: patching .."
            cd ti-u-boot
            git apply ${topdir}/patches/ti-u-boot/*
            cd ..
        fi
    else
        echo ">> ti-u-boot: available"
    fi
    UBOOT_DIR=${topdir}/build/${build}/bsp_sources/ti-u-boot

    if [ ! -d k3-image-gen ]; then
        cd ${topdir}/build/${build}/bsp_sources
        echo ">> k3-image-gen: not found. cloning .."
        k3ig_srcrev=($(read_bsp_config ${bsp_version} k3ig_srcrev))
        git clone \
            https://git.ti.com/git/k3-image-gen/k3-image-gen.git \
            -b ${k3ig_srcrev} \
            --single-branch \
            --depth=1
        echo ">> k3-image-gen: cloned"
    else
        echo ">> k3-image-gen: available"
    fi
    K3IG_DIR=${topdir}/build/${build}/bsp_sources/k3-image-gen

    if [ ! -d ti-linux-firmware ]; then
        cd ${topdir}/build/${build}/bsp_sources
        echo ">> ti-linux-firmware: not found. cloning .."
        linux_fw_srcrev=($(read_bsp_config ${bsp_version} linux_fw_srcrev))
        git clone \
            https://git.ti.com/git/processor-firmware/ti-linux-firmware.git \
            -b ${linux_fw_srcrev} \
            --single-branch \
            --depth=1
        echo ">> ti-linux-firmware: cloned"
    else
        echo ">> ti-linux-firmware: available"
    fi
    dmfw_machine=($(read_machine_config ${machine} dmfw_machine))
    SYSFW_DIR=${topdir}/build/${build}/bsp_sources/ti-linux-firmware/ti-sysfw
    DMFW_DIR=${topdir}/build/${build}/bsp_sources/ti-linux-firmware/ti-dm/${dmfw_machine}

    if [ ! -d ti-linux-kernel ]; then
        cd ${topdir}/build/${build}/bsp_sources
        echo ">> ti-linux-kernel: not found. cloning .."
        linux_kernel_srcrev=($(read_bsp_config ${bsp_version} linux_kernel_srcrev))
        git clone \
            https://git.ti.com/git/ti-linux-kernel/ti-linux-kernel.git \
            -b ${linux_kernel_srcrev} \
            --single-branch \
            --depth=1
        echo ">> ti-linux-kernel: cloned"
        if [ -d ${topdir}/patches/ti-linux-kernel ]; then
            echo ">> ti-linux-kernel: patching .."
            cd ti-linux-kernel
            git apply ${topdir}/patches/ti-linux-kernel/*
            cd ..
        fi
    else
        echo ">> ti-linux-kernel: available"
    fi
    KERNEL_DIR=${topdir}/build/${build}/bsp_sources/ti-linux-kernel

    if [ ! -d ti-img-rogue-driver ]; then
        cd ${topdir}/build/${build}/bsp_sources
        echo ">> ti-img-rogue-driver: not found. cloning .."
        img_rogue_driver_srcrev=($(read_bsp_config ${bsp_version} img_rogue_driver_srcrev))
        git clone \
            https://git.ti.com/git/graphics/ti-img-rogue-driver.git \
            -b ${img_rogue_driver_srcrev} \
            --single-branch \
            --depth=1
        echo ">> ti-img-rogue-driver: cloned"
        if [ -d ${topdir}/patches/ti-img-rogue-driver ]; then
            echo ">> ti-img-rogue-driver: patching .."
            cd ti-img-rogue-driver
            git apply ${topdir}/patches/ti-img-rogue-driver/*
            cd ..
        fi
    else
        echo ">> ti-img-rogue-driver: available"
    fi
    IMG_ROGUE_DRIVER_DIR=${topdir}/build/${build}/bsp_sources/ti-img-rogue-driver

    echo "> BSP sources: cloned"
    echo "> BSP sources: creating backup .."
    cd ${topdir}/build/${build}
    tar --use-compress-program="pigz --best --recursive | pv" -cf bsp_sources.tar.xz bsp_sources
    echo "> BSP sources: backup created .."

    mkdir -p tisdk-${distro}-${machine}-boot
}

function build_atf() {
machine=$1

    cd $TFA_DIR
    target_board=($(read_machine_config ${machine} atf_target_board))

    echo "> ATF: building .."
    make -j`nproc` ARCH=aarch64 CROSS_COMPILE=aarch64-none-linux-gnu- PLAT=k3 TARGET_BOARD=${target_board} SPD=opteed

    echo "> ATF: signing .."
    ${TI_SECURE_DEV_PKG}/scripts/secure-binary-image.sh ${TFA_DIR}/build/k3/${target_board}/release/bl31.bin ${TFA_DIR}/build/k3/${target_board}/release/bl31.bin.signed
}

function build_optee() {
machine=$1

    cd ${OPTEE_DIR}
    platform=($(read_machine_config ${machine} optee_platform))

    echo "> optee: building .."
    make -j`nproc` CROSS_COMPILE64=aarch64-none-linux-gnu- CROSS_COMPILE=arm-none-linux-gnueabihf- PLATFORM=${platform} CFG_ARM64_core=y

    echo "> optee: signing .."
    ${TI_SECURE_DEV_PKG}/scripts/secure-binary-image.sh ${OPTEE_DIR}/out/arm-plat-k3/core/tee-pager_v2.bin ${OPTEE_DIR}/out/arm-plat-k3/core/tee-pager_v2.bin.signed
}

function build_uboot() {
machine=$1

    uboot_r5_defconfig=($(read_machine_config ${machine} uboot_r5_defconfig))
    uboot_a53_defconfig=($(read_machine_config ${machine} uboot_a53_defconfig))
    sysfw_soc=($(read_machine_config ${machine} sysfw_soc))

    echo "> dmfw: signing .."
    ${TI_SECURE_DEV_PKG}/scripts/secure-binary-image.sh ${DMFW_DIR}/ipc_echo_testb_mcu1_0_release_strip.xer5f ${DMFW_DIR}/ipc_echo_testb_mcu1_0_release_strip.xer5f.signed

    cd ${UBOOT_DIR}
    echo "> uboot-r5: building .."
    make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- ${uboot_r5_defconfig} O=${UBOOT_DIR}/out/r5
    make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- O=${UBOOT_DIR}/out/r5

    cd ${K3IG_DIR}
    make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- SOC=${sysfw_soc} SOC_TYPE=hs-fs SBL=${UBOOT_DIR}/out/r5/spl/u-boot-spl.bin SYSFW_DIR=${SYSFW_DIR}
    cp ${K3IG_DIR}/tiboot3.bin ${topdir}/build/${build}/tisdk-${distro}-${machine}-boot/
    # TODO: Also build for GP and HS
    # make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- SOC=${sysfw_soc} SOC_TYPE=gp SBL=${UBOOT_DIR}/out/r5/spl/u-boot-spl.bin SYSFW_DIR=${SYSFW_DIR}
    # make -j`nproc` ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- SOC=${sysfw_soc} SOC_TYPE=hs SBL=${UBOOT_DIR}/out/r5/spl/u-boot-spl.bin SYSFW_DIR=${SYSFW_DIR}

    cd ${UBOOT_DIR}
    echo "> uboot-a53: building .."
    make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-none-linux-gnu- ${uboot_a53_defconfig} O=${UBOOT_DIR}/out/a53
    make -j`nproc` ARCH=arm CROSS_COMPILE=aarch64-none-linux-gnu- ATF=${TFA_DIR}/build/k3/lite/release/bl31.bin.signed TEE=${OPTEE_DIR}/out/arm-plat-k3/core/tee-pager_v2.bin.signed DM=${DMFW_DIR}/ipc_echo_testb_mcu1_0_release_strip.xer5f.signed O=${UBOOT_DIR}/out/a53
    cp ${UBOOT_DIR}/out/a53/tispl.bin ${topdir}/build/${build}/tisdk-${distro}-${machine}-boot/
    cp ${UBOOT_DIR}/out/a53/u-boot.img ${topdir}/build/${build}/tisdk-${distro}-${machine}-boot/
}

function build_kernel() {
machine=$1
rootfs_dir=$2

    cd ${KERNEL_DIR}

    echo "kernel: generating defconfig .."
    make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig ti_arm64_prune.config

    echo "kernel: building Image .."
    make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- Image

    echo "kernel: building DTBs .."
    make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs

    echo "kernel: building modules .."
    make -j`nproc` ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules

    echo "kernel: installing Image .."
    cp arch/arm64/boot/Image ${rootfs_dir}/boot/

    echo "kernel: installing DTBs .."
    mkdir -p ${rootfs_dir}/boot/dtb
    cp -rf arch/arm64/boot/dts/ti ${rootfs_dir}/boot/dtb/

    echo "kernel: installing modules .."
    make ARCH=arm64  INSTALL_MOD_PATH=${rootfs_dir} modules_install
}

function build_ti_img_rogue_driver() {
machine=$1
rootfs_dir=$2
kernel_dir=$3

    pvr_target=($(read_machine_config ${machine} pvr_target))
    pvr_window_system=($(read_machine_config ${machine} pvr_window_system))
    cd ${IMG_ROGUE_DRIVER_DIR}

    echo "ti-img-rogue-driver: building .."
    make CROSS_COMPILE=aarch64-none-linux-gnu- ARCH=arm64 KERNELDIR=${kernel_dir} RGX_BVNC="33.15.11.3" BUILD=release PVR_BUILD_DIR=${pvr_target} WINDOW_SYSTEM=${pvr_window_system}

    echo "ti-img-rogue-driver: installing .."
    cd binary_am62_linux_wayland_release/target_aarch64/kbuild
    make -C ${kernel_dir} ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- INSTALL_MOD_PATH=${rootfs_dir} INSTALL_MOD_STRIP=1 M=`pwd` modules_install
}
