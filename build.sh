#!/bin/bash
# Filename: build.sh
# Author: "Sai Sree Kartheek Adivi <s-adivi@ti.com>"
# Description: Script to build a Debian SD card image for TI Platforms
###############################################################################

passwd=""
for n in {1..3};
do
    read -s -p "[sudo] password for $USER: " passwd
    if sudo -S -k echo <<< $passwd > /dev/null 2>&1 && [[ $? -eq 0 ]]; then
        break
    else
        echo
        if [ $n -eq 3 ]; then
            echo "Incorrect Password"
            exit 1
        fi
        echo "Sorry, try again."
    fi
done
echo ""

# set -x

export topdir=$(git rev-parse --show-toplevel)

source ${topdir}/scripts/common.sh

# Override the machines list if machine is passed as argument
if [ "$#" -ne 0 ]; then
    machines=($1)
fi

mkdir -p ${topdir}/build

source ${topdir}/scripts/setup.sh

setup_build_tools
echo $passwd | sudo -k -S setup_package_dependencies

source ${topdir}/scripts/build_bsp.sh

for machine in "${machines[@]}"
do
    setup_bsp_build $machine
    build_atf $machine
    build_optee $machine
    build_uboot $machine
    # build_linux $machine
    # build_km_gpu $machine
    cd ${topdir}/build
    tar --use-compress-program="pigz --best --recursive | pv" -cf boot_${machine}.tar.xz boot_${machine}
done

for distro in "${distros[@]}"
do
    for machine in "${machines[@]}"
    do
        echo "building ${distro} for ${machine}"

        # Read config options from machines.conf
        hostname=`read_machine_config ${machine} hostname`

        set -x
        bdebstrap --mode auto \
            -c ${topdir}/configs/${distro}.yaml \
            --name ${topdir}/build/metadata-${distro}-${machine} \
            --target ${distro}-${machine}-rootfs.tar.xz \
            --hostname "${hostname}" -f

        cd ${topdir}/build
        mv ${topdir}/build/metadata-${distro}-${machine}/${distro}-${machine}-rootfs.tar.xz ${topdir}/build/
        tar --use-compress-program="pigz --best --recursive | pv" -cf metadata-${distro}-${machine}.tar.xz metadata-${distro}-${machine}
    done
done

echo "> Cleaning up .."
cd ${topdir}/build
rm -rf metadata-${distro}-${machine} bsp_sources

