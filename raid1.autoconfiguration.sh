#!/bin/bash

clear && set -ev

# this script creates a new RAID1 device from scratch, given the drive letters 
# of the HDDs you want to use.  Theoretically, RAID1 can have new drives added
# to it without too much difficulty.

# TODO: looks like it would be very easy to make this generic, for provisioning
# any RAID level.

raid_device="md1"
filesystemtype="ext4"
raid_level="1"

# USEAGE: ./script.sh a b d f g
# where letters correspond to /dev/sd[a]. 

if [ $# -eq 0 ]; then echo "No arguments provided" && exit 1; fi

drive_list=( "$@" )
drive_count=${#drive_list[@]}

echo "confirm: using drives ${drive_list[@]} for new software RAID 1 array."
echo -ne "\t ALL DATA ON ALL LISTED DRIVES WILL BE LOST! > "; read

[ `which parted   2>/dev/null` ] || yum install parted
[ `which mdadm    2>/dev/null` ] || yum install mdadm
[ `which xfsprogs 2>/dev/null` ] || yum install xfsprogs

sync && sync && sync                                # folklore, but doesn't hurt

# partition the drives
for drive in ${drive_list[@]}; do 
    echo -e "\tCreating partition on /dev/sd$drive"
    sudo parted /dev/sd$drive mklabel gpt
    sync
    sudo parted -a optimal /dev/sd$drive mkpart primary 0% 100%
    sync
    sudo parted /dev/sd$drive set 1 raid on
    sync
done

# verify drive formatting
for drive in ${drive_list[@]}
do
    sudo parted /dev/sd$drive print
done

echo "Drive count: $drive_count"
echo "Multi device name: $raid_device"

devicelist=$(eval echo  /dev/sd{`echo "$@" | tr ' ' ,`}1)
echo "Drives: $devicelist"

sudo mdadm  --create \
            --verbose /dev/$raid_device \
            --level=$raid_level \
            --raid-devices=$drive_count $devicelist

# backup the raid multi device so it's persistent on reboot
mkdir -p /etc/mdadm
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf

# ensure the device is assembled on boot
# sudo update-initramfs -u                         # not available on the system
sudo update-grub                # WATCH OUT! could mess up a separate boot drive

sudo mkfs.ext4 -F /dev/$raid_device                      # Create the filesystem

sudo mkdir -p /mnt/$raid_device
sudo mount /dev/$raid_device /mnt/$raid_device

# add new mount to fstab
echo "/dev/$raid_device /mnt/$raid_device ext4 defaults,nofail 0 0" | sudo tee -a /etc/fstab

# verify
df -h -t ext4
lsblk
cat /proc/mdstat
sudo mdadm --detail /dev/$raid_device

