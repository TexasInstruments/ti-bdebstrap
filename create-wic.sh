#!/bin/bash
#!/bin/bash
# Authors:
#    Sai Sree Kartheek Adivi <s-adivi@ti.com>
#    LT Thomas <ltjr@ti.com>
#    Chase Maupin
#    Franklin Cooper Jr.
#
# create-img.sh v0.1

# This distribution contains contributions or derivatives under copyright
# as follows:
#
# Copyright (c) 2024, Texas Instruments Incorporated
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# - Neither the name of Texas Instruments nor the names of its
#   contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Force locale language to be set to English. This avoids issues when doing
# text and string processing.
export LANG=C

# Determine the absolute path to the executable
# EXE will have the PWD removed so we can concatenate with the PWD safely
PWD=`pwd`
EXE=`echo $0 | sed s=$PWD==`
EXEPATH="$PWD"/"$EXE"
clear

export topdir=$(git rev-parse --show-toplevel)

BUILD=$1
BUILDPATH=${topdir}/build/

cat << EOM

################################################################################

This script will create a flashable/bootable SD card image from the built
binaries.

The script must be run with root permissions and from the bin directory of
the SDK

Usage:
 $ sudo ./create-wic.sh <build-id>

################################################################################

EOM

AMIROOT=`whoami | awk {'print $1'}`
if [ "$AMIROOT" != "root" ] ; then

	echo "	**** Error *** must run script with sudo"
	echo ""
	exit
fi

source ${topdir}/scripts/common.sh

validate_section "Build" ${BUILD} "${topdir}/builds.toml"

if [ ! -f ${topdir}/build/${BUILD}/tisdk-debian-${BUILD}-boot.tar.xz ]; then
    echo "Error: Boot partition tarball not found for ${BUILD}."
    exit -1
fi

if [ ! -f ${topdir}/build/${BUILD}/tisdk-debian-${BUILD}-rootfs.tar.xz ]; then
    echo "Error: RootFS partition tarball not found for ${BUILD}."
    exit -1
fi

IMAGE=tisdk-debian-${BUILD}.wic

echo "Creating an empty image"
dd if=/dev/zero of=${BUILDPATH}/${BUILD}/${IMAGE} count=10485760 status=progress
sync ; sync

cat << END | fdisk ${BUILDPATH}/${BUILD}/${IMAGE}
o
n
p


+128M
t
c
a
n
p



w
END

echo "Mount the image"
LOOPDEV=$(losetup -fP ${BUILDPATH}/${BUILD}/${IMAGE} --show)

echo "Partitioning Boot"
mkfs.fat -F32 -a -v -I -n "BOOT" ${LOOPDEV}p1

echo "Partitioning RootFS"
mkfs.ext3 -F -L "rootfs" ${LOOPDEV}p2

echo "Mounting Boot Paritition"
mkdir -p ${BUILDPATH}/${BUILD}/temp/ ; cd ${BUILDPATH}/${BUILD}/temp/
mkdir img_boot
mount ${LOOPDEV}p1 ./img_boot

echo "Copy Boot Partition files"
cd ./img_boot
tar -xf ${BUILDPATH}/${BUILD}/tisdk-debian-${BUILD}-boot.tar.xz
mv tisdk-debian-${BUILD}-boot/* ./
rmdir tisdk-debian-${BUILD}-boot

echo "Sync and Unmount Boot Partition"
cd ${BUILDPATH}/${BUILD}/temp/
sync ; sync
umount ./img_boot ; rmdir ./img_boot

echo "Mounting RootFS Paritition"
mkdir -p ${BUILDPATH}/${BUILD}/temp/ ; cd ${BUILDPATH}/${BUILD}/temp/
mkdir img_rootfs
mount ${LOOPDEV}p2 ./img_rootfs

echo "Copy RootFS Partition files"
cd ./img_rootfs
tar -xf ${BUILDPATH}/${BUILD}/tisdk-debian-${BUILD}-rootfs.tar.xz
mv tisdk-debian-${BUILD}-rootfs/* ./
rmdir tisdk-debian-${BUILD}-rootfs

echo "Sync and Unmount RootFS Partition"
cd ${BUILDPATH}/${BUILD}/temp/
sync ; sync
umount ./img_rootfs ; rmdir ./img_rootfs

echo "Unmount the image"
losetup -d ${LOOPDEV}

echo "Compress the image"
cd ${BUILDPATH}/${BUILD}/
xz -T 0 ${IMAGE}

echo "Cleanup"
rm -rf ${BUILDPATH}/${BUILD}/temp

echo "Done"
