#!/bin/bash

set -e
set -v

# this is simple: given a hard drive, wipe it, create a clean partition table, 
# and format it with the chosen filesystem type.

# RUN THIS SCRIPT AS ROOT

# USAGE: bash format_block_device.sh -d /dev/xyz -f ext4 -l gpt -a /mnt/newdrive
# d: the device to wipe
# f: the new filesystem type to put on the device
# g: the filesystem table type. gpt recommended, unless compatibility is needed.
# l: partition label. this is used to identify the drive when automounted, so 
#    ensure that it's unique.  It's not as good a system as using the UUID.
# a: the location to automount the new drive

while getopts ":d:f:l:a:" opt; do; case $opt in
    d) device="$OPTARG" ;;
    f) fstype="$OPTARG" ;;
    t) table="$OPTARG" ;;
    l) label="$OPTARG" ;;
    a) automount="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG. " >&2 ;;
esac; done

[ -z "$device" ] && echo "raid level not specified."          && exit
[ -z "$fstype" ] && echo "new filesystem type not specified." && exit
[ -z "$table" ]  && echo "filesystem table type not given."   && exit
[ -z "$label" ]  && echo "partition label not given."         && exit
[ -z "$automount" ] && echo "mount point of new partition not given." && exit

[ mount | grep $device > /dev/null ] && echo "ERROR: $drive is mounted." && exit

[ cat /proc/mdstat | grep $device > /dev/null ] && \
    echo "ERROR: $device is in a RAID device, remove before proceeding." && exit 

[ `whoami` != "root" ] && echo "run this script as root!" && exit

echo "device to wipe: $device"
echo "new filesystem: $fstype"
echo "partition table: $table"
echo "partition label: $label"
echo -n "Confirm > " && read

[ `which parted   2>/dev/null` ] || apt install parted
[ `which mkfs     2>/dev/null` ] || apt install util-linux

[ mount | grep $device > /dev/null ] && umount $device      # unmount if mounted

parted $device mklabel $table && sync               # create new partition table

parted -a optimal $device mkpart primary 0% 100% && sync # new primary partition

partition="$device"1                                # new variable for /dev/xyz1

[ partprobe -d -s $partition > /dev/null ] || echo "partition MISSING" && exit

mkfs.$fstype -L $label $partition       # create the filesystem on the partition

cp /etc/fstab /etc/fstab.$(date +"%FT%H%M%S").bak            # back up the fstab

# fs_uuid=$(lsblk -no UUID $partition)                 # get the filesystem UUID
# using the UUID would be better, but then there's no way to detect duplicates
# echo "UUID="$fs_uuid" $automount $fstype defaults 0 2" >> /etc/fstab

# if the script has already been run, remove the extra fstab entry
[ grep $label /etc/fstab ] && sed "/$label/d" /etc/fstab > /etc/fstab

echo "LABEL=$label $automount $fstype defaults 0 2" >> /etc/fstab    # automount

lsblk -o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT   # view the partition and filesystem

cat /etc/fstab                             # check for superfluous fstab entries
