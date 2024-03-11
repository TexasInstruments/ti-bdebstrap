#!/bin/bash
# This startup script expands the rootfs partition to full size of the boot device.

ROOT_PART=`mount | grep "/ " | cut -f1 -d' ' | cut -d'/' -f3`
BOOT_DEV=${ROOT_PART%p*}

if [[ "$BOOT_DEV" != *"mmc"* ]]; then
    # Not booting from EMMC / SD Card. So no need to extend the rootfs.
exit 0
fi

FREE_SPACE=`parted /dev/$BOOT_DEV unit '%' print free | grep 'Free Space' | tail -n1 | awk '{print $3}'`

if [[ ${FREE_SPACE%.*} -gt 0 ]]; then
    echo "$FREE_SPACE of /dev/$BOOT_DEV is free. Extending partition #2"
    echo ",+" | sfdisk -N 2 /dev/$BOOT_DEV --no-reread
    partprobe
    resize2fs /dev/$ROOT_PART
fi

