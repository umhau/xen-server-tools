#!/bin/bash
set -ev

if [ -z $2 ];then echo "arguments: \"human-readable storage repository (SR) disk name\" \"/dev/device\""; exit;fi

disk_name="$1"
device="$2"

# confirm variables
echo "$disk_name"
echo "$device"
read

xe sr-create name-label="$disk_name" shared=false device-config:device="$device" type=lvm content-type=user
