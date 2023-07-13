#!/bin/bash
# Authors:
#    LT Thomas <ltjr@ti.com>
#    Chase Maupin
#    Franklin Cooper Jr.
#
# create-sdcard.sh v0.3

# This distribution contains contributions or derivatives under copyright
# as follows:
#
# Copyright (c) 2023, Texas Instruments Incorporated
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

PARSEPATH=./build/$1

cat << EOM

################################################################################

This script will create a bootable SD card from the built binaries.

The script must be run with root permissions and from the bin directory of
the SDK

Usage:
 $ sudo ./create-sdcard.sh <build-id>

Formatting can be skipped if the SD card is already formatted and
partitioned properly.

################################################################################

EOM

AMIROOT=`whoami | awk {'print $1'}`
if [ "$AMIROOT" != "root" ] ; then

	echo "	**** Error *** must run script with sudo"
	echo ""
	exit
fi

#Precentage function
untar_progress ()
{
    TARBALL=$1;
    DIRECTPATH=$2;
    REALPATH=`realpath $TARBALL`
    echo "Copying $REALPATH"
    cd $DIRECTPATH
    tar -xf $REALPATH
    sudo mv tisdk*/* .
    sudo rm -rf tisdk*
    cd - > /dev/null
}

#copy/paste programs
cp_progress ()
{
	CURRENTSIZE=0
	while [ $CURRENTSIZE -lt $TOTALSIZE ]
	do
		TOTALSIZE=$1;
		TOHERE=$2;
		CURRENTSIZE=`sudo du -c $TOHERE | grep total | awk {'print $1'}`
		echo -e -n "$CURRENTSIZE /  $TOTALSIZE copied \r"
		sleep 1
	done
}

check_for_sdcards()
{
        # find the avaible SD cards
        ROOTDRIVE=`mount | grep 'on / ' | awk {'print $1'} |  cut -c6-8`
        PARTITION_TEST=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''`
        if [ "$PARTITION_TEST" = "" ]; then
	        echo -e "Please insert a SD card to continue\n"
	        while [ "$PARTITION_TEST" = "" ]; do
		        read -p "Type 'y' to re-detect the SD card or 'n' to exit the script: " REPLY
		        if [ "$REPLY" = 'n' ]; then
		            exit 1
		        fi
		        ROOTDRIVE=`mount | grep 'on / ' | awk {'print $1'} |  cut -c6-8`
		        PARTITION_TEST=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''`
	        done
        fi
}

populate_3_partitions() {
    ENTERCORRECTLY="0"
	while [ $ENTERCORRECTLY -ne 1 ]
	do
		read -e -p 'Enter path where SD card tarballs were downloaded : '  TARBALLPATH

		echo ""
		ENTERCORRECTLY=1
		if [ -d $TARBALLPATH ]
		then
			echo "Directory exists"
			echo ""
			echo "This directory contains:"
			ls $TARBALLPATH
			echo ""
			read -p 'Is this correct? [y/n] : ' ISRIGHTPATH
				case $ISRIGHTPATH in
				"y" | "Y") ;;
				"n" | "N" ) ENTERCORRECTLY=0;continue;;
				*)  echo "Please enter y or n";ENTERCORRECTLY=0;continue;;
				esac
		else
			echo "Invalid path make sure to include complete path"
			ENTERCORRECTLY=0
            continue
		fi
        # Check that tarballs were found
        if [ ! -e "$TARBALLPATH""/boot_partition.tar.xz" ]
        then
            echo "Could not find boot_partition.tar.xz as expected.  Please"
            echo "point to the directory containing the boot_partition.tar.xz"
            ENTERCORRECTLY=0
            continue
        fi

        if [ ! -e "$TARBALLPATH""/rootfs_partition.tar.xz" ]
        then
            echo "Could not find rootfs_partition.tar.xz as expected.  Please"
            echo "point to the directory containing the rootfs_partition.tar.xz"
            ENTERCORRECTLY=0
            continue
        fi

        if [ ! -e "$TARBALLPATH""/start_here_partition.tar.xz" ]
        then
            echo "Could not find start_here_partition.tar.xz as expected.  Please"
            echo "point to the directory containing the start_here_partition.tar.xz"
            ENTERCORRECTLY=0
            continue
        fi
	done

        # Make temporary directories and untar mount the partitions
        mkdir $PWD/boot
        mkdir $PWD/rootfs
        mkdir $PWD/start_here
        mkdir $PWD/tmp

        mount -t vfat ${DRIVE}${P}1 boot
        mount -t ext3 ${DRIVE}${P}2 rootfs
        mount -t ext3 ${DRIVE}${P}3 start_here

        # Remove any existing content in case the partitions were not
        # recreated
        sudo rm -rf boot/*
        sudo rm -rf rootfs/*
        sudo rm -rf start_here/*

        # Extract the tarball contents.
cat << EOM

################################################################################
        Extracting boot partition tarball

################################################################################
EOM
        untar_progress $TARBALLPATH/boot_partition.tar.xz tmp/
        if [ -e "./tmp/MLO" ]
        then
            cp ./tmp/MLO boot/
        fi
        cp -rf ./tmp/* boot/

cat << EOM

################################################################################
        Extracting rootfs partition tarball

################################################################################
EOM
        untar_progress $TARBALLPATH/rootfs_partition.tar.xz rootfs/

cat << EOM

################################################################################
        Extracting start_here partition to temp directory

################################################################################
EOM
        rm -rf tmp/*
        untar_progress $TARBALLPATH/start_here_partition.tar.xz tmp/

cat << EOM

################################################################################
        Copying Contents to START_HERE

################################################################################
EOM

        TOTALSIZE=`sudo du -c tmp/* | grep total | awk {'print $1'}`
        cp -rf tmp/* start_here/ &
        cp_progress $TOTALSIZE start_here/
        sync;sync
        # Fix up the START_HERE partitoin permissions
        chown nobody -R start_here
        chgrp nogroup -R start_here

        umount boot rootfs start_here
        sync;sync

        # Clean up the temp directories
        rm -rf boot rootfs start_here tmp
}


# find the avaible SD cards
ROOTDRIVE=`mount | grep 'on / ' | awk {'print $1'} |  cut -c6-9`
if [ "$ROOTDRIVE" = "root" ]; then
    ROOTDRIVE=`readlink /dev/root | cut -c1-3`
else
    ROOTDRIVE=`echo $ROOTDRIVE | cut -c1-3`
fi

PARTITION_TEST=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''`

# Check for available mounts
check_for_sdcards

echo -e "\nAvailable Drives to write images to: \n"
echo "#  major   minor    size   name "
cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''
echo " "

DEVICEDRIVENUMBER=
while true;
do
	read -p 'Enter Device Number or 'n' to exit: ' DEVICEDRIVENUMBER
	echo " "
        if [ "$DEVICEDRIVENUMBER" = 'n' ]; then
                exit 1
        fi

        if [ "$DEVICEDRIVENUMBER" = "" ]; then
                # Check to see if there are any changes
                check_for_sdcards
                echo -e "These are the Drives available to write images to:"
                echo "#  major   minor    size   name "
                cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''
                echo " "
               continue
        fi

	DEVICEDRIVENAME=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n '' | grep "${DEVICEDRIVENUMBER}:" | awk '{print $5}'`
	if [ -n "$DEVICEDRIVENAME" ]
	then
	        DRIVE=/dev/$DEVICEDRIVENAME
	        DEVICESIZE=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n '' | grep "${DEVICEDRIVENUMBER}:" | awk '{print $4}'`
		break
	else
		echo -e "Invalid selection!"
                # Check to see if there are any changes
                check_for_sdcards
                echo -e "These are the only Drives available to write images to: \n"
                echo "#  major   minor    size   name "
                cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<sd.\>\|\<mmcblk.\>' | grep -n ''
                echo " "
	fi
done

echo "$DEVICEDRIVENAME was selected"
#Check the size of disk to make sure its under 16GB
if [ $DEVICESIZE -gt 17000000 ] ; then
cat << EOM

################################################################################

		**********WARNING**********

	Selected Device is greater then 16GB
	Continuing past this point will erase data from device
	Double check that this is the correct SD Card

################################################################################

EOM
	ENTERCORRECTLY=0
	while [ $ENTERCORRECTLY -ne 1 ]
	do
		read -p 'Would you like to continue [y/n] : ' SIZECHECK
		echo ""
		echo " "
		ENTERCORRECTLY=1
		case $SIZECHECK in
		"y")  ;;
		"n")  exit;;
		*)  echo "Please enter y or n";ENTERCORRECTLY=0;;
		esac
		echo ""
	done

fi
echo ""

DRIVE=/dev/$DEVICEDRIVENAME
NUM_OF_DRIVES=`df | grep -c $DEVICEDRIVENAME`

# This if statement will determine if we have a mounted sdX or mmcblkX device.
# If it is mmcblkX, then we need to set an extra char in the partition names, 'p',
# to account for /dev/mmcblkXpY labled partitions.
if [[ ${DEVICEDRIVENAME} =~ ^sd. ]]; then
	echo "$DRIVE is an sdx device"
	P=''
else
	echo "$DRIVE is an mmcblkx device"
	P='p'
fi

if [ "$NUM_OF_DRIVES" != "0" ]; then
        echo "Unmounting the $DEVICEDRIVENAME drives"
        for ((c=1; c<="$NUM_OF_DRIVES"; c++ ))
        do
                unmounted=`df | grep '\<'$DEVICEDRIVENAME$P$c'\>' | awk '{print $1}'`
                if [ -n "$unmounted" ]
                then
                     echo " unmounted ${DRIVE}$P$c"
                     sudo umount -f ${DRIVE}$P$c
                fi

        done
fi

# Refresh this variable as the device may not be mounted at script instantiation time
# This will always return one more then needed
NUM_OF_PARTS=`cat /proc/partitions | grep -v $ROOTDRIVE | grep -c $DEVICEDRIVENAME`
for ((c=1; c<"$NUM_OF_PARTS"; c++ ))
do
        SIZE=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<'$DEVICEDRIVENAME$P$c'\>'  | awk '{print $3}'`
        echo "Current size of $DEVICEDRIVENAME$P$c $SIZE bytes"
done

# check to see if the device is already partitioned
for ((  c=1; c<5; c++ ))
do
	eval "SIZE$c=`cat /proc/partitions | grep -v $ROOTDRIVE | grep '\<'$DEVICEDRIVENAME$P$c'\>'  | awk '{print $3}'`"
done

PARTITION="0"
if [ -n "$SIZE1" -a -n "$SIZE2" ] ; then
	if  [ "$SIZE1" -gt "128000" -a "$SIZE2" -gt "700000" ]
	then
		PARTITION=1

		if [ -z "$SIZE3" -a -z "$SIZE4" ]
		then
			#Detected 2 partitions
			PARTS=2

		elif [ "$SIZE3" -gt "1000" -a -z "$SIZE4" ]
		then
			#Detected 3 partitions
			PARTS=3

		else
			echo "SD Card is not correctly partitioned"
			PARTITION=0
		fi
	fi
else
	echo "SD Card is not correctly partitioned"
	PARTITION=0
	PARTS=0
fi


#Partition is found
if [ "$PARTITION" -eq "1" ]
then
cat << EOM

################################################################################

   Detected device has $PARTS partitions already

   Re-partitioning will allow the choice of 2 or 3 partitions

################################################################################

EOM

	ENTERCORRECTLY=0
	while [ $ENTERCORRECTLY -ne 1 ]
	do
		read -p 'Would you like to re-partition the drive anyways [y/n] : ' CASEPARTITION
		echo ""
		echo " "
		ENTERCORRECTLY=1
		case $CASEPARTITION in
		"y")  echo "Now partitioning $DEVICEDRIVENAME ...";PARTITION=0;;
		"n")  echo "Skipping partitioning";;
		*)  echo "Please enter y or n";ENTERCORRECTLY=0;;
		esac
		echo ""
	done

fi

#Partition is not found, choose to partition 2 or 3 segments
if [ "$PARTITION" -eq "0" ]
then
cat << EOM

################################################################################

	Select 2 partitions if only need boot and rootfs (most users).
	Select 3 partitions if need SDK & other content on SD card.  This is
        usually used by device manufacturers with access to partition tarballs.

	****WARNING**** continuing will erase all data on $DEVICEDRIVENAME

################################################################################

EOM
	ENTERCORRECTLY=0
	while [ $ENTERCORRECTLY -ne 1 ]
	do

		read -p 'Number of partitions needed [2/3] : ' CASEPARTITIONNUMBER
		echo ""
		echo " "
		ENTERCORRECTLY=1
		case $CASEPARTITIONNUMBER in
		"2")  echo "Now partitioning $DEVICEDRIVENAME with 2 partitions...";PARTITION=2;;
		"3")  echo "Now partitioning $DEVICEDRIVENAME with 3 partitions...";PARTITION=3;;
		"n")  exit;;
		*)  echo "Please enter 2 or 3";ENTERCORRECTLY=0;;
		esac
		echo " "
	done
fi



#Section for partitioning the drive

#create 3 partitions
if [ "$PARTITION" -eq "3" ]
then

# set the PARTS value as well
PARTS=3

cat << EOM

################################################################################

		Now making 3 partitions

################################################################################

EOM

dd if=/dev/zero of=$DRIVE bs=1024 count=1024

SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`

echo DISK SIZE - $SIZE bytes

cat << END | fdisk $DRIVE
n
p
1

+128M
n
p
2

+2.4G
n
p
3


t
1
c
a
1
w
END


cat << EOM

################################################################################

		Partitioning Boot

################################################################################
EOM
	mkfs.vfat -F 32 -n "boot" ${DRIVE}${P}1
cat << EOM

################################################################################

		Partitioning Rootfs

################################################################################
EOM
	mkfs.ext3 -L "rootfs" ${DRIVE}${P}2
cat << EOM

################################################################################

		Partitioning START_HERE

################################################################################
EOM
	mkfs.ext3 -L "START_HERE" ${DRIVE}${P}3
	sync
	sync

#create only 2 partitions
elif [ "$PARTITION" -eq "2" ]
then

# Set the PARTS value as well
PARTS=2
cat << EOM

################################################################################

		Now making 2 partitions

################################################################################

EOM
dd if=/dev/zero of=$DRIVE bs=1024 count=1024

SIZE=`fdisk -l $DRIVE | grep Disk | awk '{print $5}'`

echo DISK SIZE - $SIZE bytes

cat << END | fdisk $DRIVE
n
p
1

+128M
n
p
2


t
1
c
a
1
w
END

cat << EOM

################################################################################

		Partitioning Boot

################################################################################
EOM
	mkfs.vfat -F 32 -n "boot" ${DRIVE}${P}1
cat << EOM

################################################################################

		Partitioning rootfs

################################################################################
EOM
	mkfs.ext3 -L "rootfs" ${DRIVE}${P}2
	sync
	sync
	INSTALLSTARTHERE=n
fi



#Break between partitioning and installing file system
cat << EOM


################################################################################

   Partitioning is now done
   Continue to install filesystem or select 'n' to safe exit

   **Warning** Continuing will erase files any files in the partitions

################################################################################


EOM
ENTERCORRECTLY=0
while [ $ENTERCORRECTLY -ne 1 ]
do
	read -p 'Would you like to continue? [y/n] : ' EXITQ
	echo ""
	echo " "
	ENTERCORRECTLY=1
	case $EXITQ in
	"y") ;;
	"n") exit;;
	*)  echo "Please enter y or n";ENTERCORRECTLY=0;;
	esac
done

# If this is a three partition card then we will jump to a function to
# populate the three partitions and then exit the script.  If not we
# go on to prompt the user for input on the two partitions
if [ "$PARTS" -eq "3" ]
then
    populate_3_partitions
    exit 0
fi

#Add directories for images
export START_DIR=$PWD
mkdir $START_DIR/tmp
export PATH_TO_SDBOOT=boot
export PATH_TO_SDROOTFS=rootfs
export PATH_TO_TMP_DIR=$START_DIR/tmp


echo " "
echo "Mount the partitions "
mkdir $PATH_TO_SDBOOT
mkdir $PATH_TO_SDROOTFS

sudo mount -t vfat ${DRIVE}${P}1 boot/
sudo mount -t ext3 ${DRIVE}${P}2 rootfs/



echo " "
echo "Emptying partitions "
echo " "
sudo rm -rf  $PATH_TO_SDBOOT/*
sudo rm -rf  $PATH_TO_SDROOTFS/*

echo ""
echo "Syncing...."
echo ""
sync
sync
sync

BOOTFILEPATH="$PARSEPATH/tisdk*boot.tar.xz"
ROOTFILEPATH="$PARSEPATH/tisdk*rootfs.tar.xz"

cat << EOM
################################################################################

	Copying files now... will take minutes

################################################################################

Copying boot partition
EOM


untar_progress $BOOTFILEPATH $PATH_TO_SDBOOT
echo ""

sync

echo "Copying rootfs System partition"
untar_progress $ROOTFILEPATH $PATH_TO_SDROOTFS

echo ""
echo ""
sync
sync
sync
sync
sync
sync

echo " "
echo "Un-mount the partitions "
sudo umount -f $PATH_TO_SDBOOT
sudo umount -f $PATH_TO_SDROOTFS


echo " "
echo "Remove created temp directories "
sudo rm -rf $PATH_TO_TMP_DIR
sudo rm -rf $PATH_TO_SDROOTFS
sudo rm -rf $PATH_TO_SDBOOT


echo " "
echo "Operation Finished"
echo " "
