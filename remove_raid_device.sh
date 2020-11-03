#!/bin/bash

set -e
set -v

# usage: bash remove_raid_device.sh -m /dev/mdX -d "e v f m"

while getopts ":m:d:" opt; do
  case $opt in
    m) raid_device="$OPTARG"
    ;;
    d) drive_list="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG. " >&2
    ;;
  esac
done

[ -z $raid_device ] && echo "Specify RAID device." && cat /proc/mdstat && exit
[ -z $drive_list ] && echo "specify list of drives connected to RAID." && exit

devicelist=$(eval echo  /dev/sd{`echo "$drive_list" | tr ' ' ,`}1)

echo "Drives connected to RAID: $devicelist"
echo -n "Removing RAID device $1. Confirm > "; read

if mount | grep $1 > /dev/null; then umount $1; fi    # unmount drive if mounted

mdadm --stop "$1"                                       # deactivate RAID device

mdadm --remove "$1"                    # remove device - this may sometimes fail

mdadm --zero-superblock $devicelist  # remove superblocks from all related disks

