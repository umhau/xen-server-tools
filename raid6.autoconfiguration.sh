#!/bin/bash
clear
set -ev

# this script creates a new RAID6 device from scratch, given the drive letters 
# of the HDDs you want to use.  Theoretically, RAID6 can have new drives added
# to it without too much difficulty.

# According to the Storage Networking Industry Association (SNIA), the 
# definition of RAID 6 is: "Any form of RAID that can continue to execute read 
# and write requests to all of a RAID array's virtual disks in the presence of
# any two concurrent disk failures."

# RAID 6 does not have a performance penalty for read operations, but it does 
# have a performance penalty on write operations because of the overhead 
# associated with parity calculations. RAID 6 can read up to the same speed as 
# RAID 5 with the same number of physical drives.[

multi_device_name="md0"

# USEAGE: ./script.sh a b d f g
# where letters correspond to /dev/sd[a]. 
if [ $# -eq 0 ]; then echo "No arguments provided" && exit 1; fi

# check given list of drives
drive_list=( "$@" )
drive_count=${#drive_list[@]}
if [ $(($drive_count % 2)) == 1 ]; then echo "Odd number of drives given" && exit 1; fi

echo "confirm: using drives ${drive_list[@]} for new software RAID array. ALL DATA WILL BE LOST."
echo -ne " > "; read

# install dependencies
yum install parted mdadm xfsprogs

sync

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
for drive in ${drive_list[@]}; do 
    sudo parted /dev/sd$drive print
done

# create multi device
function join_by { local IFS="$1"; shift; echo "$*"; }
comma_separated_drive_list=`join_by , "${drive_list[@]}"`
echo "Drive letters: $comma_separated_drive_list"
echo "Drive count: $drive_count"
echo "Multi device name: $multi_device_name"

# sudo mdadm \
#     --create \
#     --verbose /dev/$multi_device_name \
#     --level=6 \
#     --raid-devices=$drive_count /dev/sd{$comma_separated_drive_list}1

sudo mdadm  --create  --verbose /dev/md0 --level=6 --raid-devices=6 /dev/sd{b,c,d,e,f,g}1

# backup multi device so it's persistent on reboot
mkdir -p /etc/mdadm
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf

# ensure the device is assembled on boot
# sudo update-initramfs -u # not available on the system
sudo update-grub # WATCH OUT! the R510 has a separate boot drive that was hard to get working

# Create the filesystem
sudo mkfs.ext4 -F /dev/$multi_device_name

sudo mkdir -p /mnt/$multi_device_name
sudo mount /dev/$multi_device_name /mnt/$multi_device_name

# add new mount to fstab
echo "/dev/$multi_device_name /mnt/$multi_device_name ext4 defaults,nofail 0 0" | sudo tee -a /etc/fstab

# verify
df -h -t ext4
lsblk
cat /proc/mdstat
sudo mdadm --detail /dev/$multi_device_name

