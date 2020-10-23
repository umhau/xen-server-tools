#!/bin/bash

clear && set -ev

# this script creates a new RAID device from scratch, given the drive letters 
# of the HDDs you want to use and the raid level. 

# raid level options: 0, 1, 5, 6 
# multidevice: the /dev/[xxx] name of the raid device comprising all the drives
# filesystem type: choose from ext2, ext3, or ext4
# drive list: just the letters of each /dev/sd[X] drive
# bash raid-autoconf.sh -r 5 -m md1 -e ext4 -d "a b d g"

# there is a confirmation sequence before anything is written.

while getopts ":r:d:m:e:" opt; do
  case $opt in
    r) raid_level="$OPTARG"
    ;;
    m) raid_multi_device="$OPTARG"
    ;;
    e) filesystemtype="$OPTARG"
    ;;
    d) drive_list="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG. " >&2
    ;;
  esac
done

[ -z "$raid_level" ] && echo "raid level not specified." && exit
[ -z "$raid_multi_device" ] && echo "multidevice not specified." && exit
[ -z "$filesystemtype" ] && echo "filesystem type not specified." && exit
[ -z "$drive_list" ] && echo "drive list not specified." && exit

printf "Using RAID %s\n" "$raid_level"
printf "Using /dev/sd[X] drive letters: %s\n" "$drive_list"
printf "Multidevice specified:  /dev/%s\n" "$raid_multi_device"
printf "Filesystem chosen: %s\n" "$filesystemtype"

drive_count=${#drive_list[@]}

echo "confirm: using drives ${drive_list[@]} for new software RAID 1 array."
echo -ne "\t ALL DATA ON ALL LISTED DRIVES WILL BE LOST! > "; read

[ `which parted   2>/dev/null` ] || yum install parted
[ `which mdadm    2>/dev/null` ] || yum install mdadm
[ `which xfsprogs 2>/dev/null` ] || yum install xfsprogs

for drive in ${drive_list[@]}
do
    if mount | grep /dev/sd$drive > /dev/null
    then 
      echo "ERROR: /dev/sd$drive is mounted."
      exit
    fi
done

sync && sync && sync                                # folklore, but doesn't hurt

for drive in ${drive_list[@]}; do                         # partition the drives
    echo -e "\tCreating partition on /dev/sd$drive"
    sudo parted /dev/sd$drive mklabel gpt                                && sync
    sudo parted -a optimal /dev/sd$drive mkpart primary 0% 100%          && sync
    sudo parted /dev/sd$drive set 1 raid on                              && sync
done

# verify drive formatting
for drive in ${drive_list[@]}; do sudo parted /dev/sd$drive print; done

echo "Drive count: $drive_count"
echo "Multi device name: $raid_multi_device"

devicelist=$(eval echo  /dev/sd{`echo "$@" | tr ' ' ,`}1)
echo "Drives: $devicelist"

sudo mdadm  --create \
            --verbose /dev/$raid_multi_device \
            --level=$raid_level \
            --raid-devices=$drive_count $devicelist

# backup the raid multi device so it's persistent on reboot
mkdir -p /etc/mdadm
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf

# ensure the device is assembled on boot
# sudo update-initramfs -u                         # not available on the system
sudo update-grub                # WATCH OUT! could mess up a separate boot drive

sudo mkfs.ext4 -F /dev/$raid_multi_device                # Create the filesystem

sudo mkdir -p /mnt/$raid_multi_device
sudo mount /dev/$raid_multi_device /mnt/$raid_multi_device

# add new mount to fstab
echo "/dev/$raid_multi_device /mnt/$raid_multi_device ext4 defaults,nofail,discard 0 0" | sudo tee -a /etc/fstab

# verify
df -h -t ext4
lsblk
cat /proc/mdstat
sudo mdadm --detail /dev/$raid_multi_device

echo "check the progress of the drive mirroring process with the command: \"cat"
echo " /proc/mdstat\""
