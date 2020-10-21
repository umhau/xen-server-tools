#!/bin/bash

# unfortunately, there's no good way to remove SR disks once they've been
# added. The SR's inside them can be deleted, and the disk can be 'detached',
# but it can't ever be removed. This is a script to remove it. 

set -ev

[ -z $1 ] && echo "provide the exact name of the storage repository (SR) disk to remove, e.g. \"RAID6 7.3T\"" && exit

echo "detaching the SR disk $1"

# get the uuid of the disk given
disk_uuid=`xe sr-list name-label="$1" | grep uuid | cut -b 29-64`

# get the uuid of the PBD
pbd_uuid=`xe pbd-list sr-uuid=$disk_uuid | grep 'uuid ( RO)    ' | cut -b 31-66`

# unplug the PBD
xe pbd-unplug uuid=$pbd_uuid

# unplug the SR disk
xe sr-forget uuid=$disk_uuid
