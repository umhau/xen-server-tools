https://mangolassi.it/topic/17831/attach-drive-to-vm-in-xenserver-not-as-storage-repository/6

Unfortunately the link @dbeato provided is how you add a new disk to xenserver when you want it to be Storage Repository - a place to store VM partitions. So if you have a disk already xenserver will wipe it clean and put LVMs or EXT3 with VDI files on it.

When it's passed through as a block device to a VM it will have whatever filesystem the VM formats it with.

The problem with the info in the link @black3dynamite provided is that it's for xenserver 5.x so it doesn't work straight up with Xenserver 7.x (I'm running 7.4).

What I ended up doing was adding a raid 1 array instead of just a disk. The principle is the same though, just another name on the block device.

The array /dev/md0 is passed through to the VM as a block device.

I did it by adding a rule to /etc/udev/rules.d/65-md-incremental.rules almost at the end.

```bash
KERNEL=="md*", SUBSYSTEM=="block", ACTION=="change", SYMLINK+="xapi/block/%k", \
RUN+="/bin/sh -c '/opt/xensource/libexec/local-device-change %k 2>&1 >/dev/null&'" 
```

This rule will pass all md arrays to the VMs as Removable Storage in Xenserver (so you can attach it to whatever VM you want).

Note that * in KERNEL=="md*" is a wildcard. So this will match the devices /dev/md0, md1 md2 etc. Just replace md* with whatever block device you want to pass through.

The array is 2TB so I don't know if this works with bigger arrays.
After trying some larger drives I can verify that it works fine with larger than 2TB arrays.
Also the disks were empty so I'm not sure if xenserver will wipe the disk when you set this up the first time.
After some experimenting it looks like Xenserver will not touch the drive.

I'll add the complete file for reference.

```bash
KERNEL=="td[a-z]*", GOTO="md_end"
# This file causes block devices with Linux RAID (mdadm) signatures to
# automatically cause mdadm to be run.
# See udev(8) for syntax

# Don't process any events if anaconda is running as anaconda brings up
# raid devices manually
ENV{ANACONDA}=="?*", GOTO="md_end"

# Also don't process disks that are slated to be a multipath device
ENV{DM_MULTIPATH_DEVICE_PATH}=="?*", GOTO="md_end"

# We process add events on block devices (since they are ready as soon as
# they are added to the system), but we must process change events as well
# on any dm devices (like LUKS partitions or LVM logical volumes) and on
# md devices because both of these first get added, then get brought live
# and trigger a change event.  The reason we don't process change events
# on bare hard disks is because if you stop all arrays on a disk, then
# run fdisk on the disk to change the partitions, when fdisk exits it
# triggers a change event, and we want to wait until all the fdisks on
# all member disks are done before we do anything.  Unfortunately, we have
# no way of knowing that, so we just have to let those arrays be brought
# up manually after fdisk has been run on all of the disks.

# First, process all add events (md and dm devices will not really do
# anything here, just regular disks, and this also won't get any imsm
# array members either)
SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_TYPE}=="linux_raid_member", \
        RUN+="/sbin/mdadm -I $env{DEVNAME}"

# Next, check to make sure the BIOS raid stuff wasn't turned off via cmdline
IMPORT{cmdline}="noiswmd"
IMPORT{cmdline}="nodmraid"
ENV{noiswmd}=="?*", GOTO="md_imsm_inc_end"
ENV{nodmraid}=="?*", GOTO="md_imsm_inc_end"
SUBSYSTEM=="block", ACTION=="add", ENV{ID_FS_TYPE}=="isw_raid_member", \
        RUN+="/sbin/mdadm -I $env{DEVNAME}"
LABEL="md_imsm_inc_end"

SUBSYSTEM=="block", ACTION=="remove", ENV{ID_PATH}=="?*", \
        RUN+="/sbin/mdadm -If $name --path $env{ID_PATH}"
SUBSYSTEM=="block", ACTION=="remove", ENV{ID_PATH}!="?*", \
        RUN+="/sbin/mdadm -If $name"

# Next make sure that this isn't a dm device we should skip for some reason
ENV{DM_UDEV_RULES_VSN}!="?*", GOTO="dm_change_end"
ENV{DM_UDEV_DISABLE_OTHER_RULES_FLAG}=="1", GOTO="dm_change_end"
ENV{DM_SUSPENDED}=="1", GOTO="dm_change_end"
KERNEL=="dm-*", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="linux_raid_member", \
        ACTION=="change", RUN+="/sbin/mdadm -I $env{DEVNAME}"
LABEL="dm_change_end"

# Finally catch any nested md raid arrays.  If we brought up an md raid
# array that's part of another md raid array, it won't be ready to be used
# until the change event that occurs when it becomes live
KERNEL=="md*", SUBSYSTEM=="block", ENV{ID_FS_TYPE}=="linux_raid_member", \
        ACTION=="change", RUN+="/sbin/mdadm -I $env{DEVNAME}"

# Added line
# Pass-through of all /dev/md* arrays. 
# Will end up as Removable Storage that can be assigned to a VM.
KERNEL=="md*", SUBSYSTEM=="block", ACTION=="change", SYMLINK+="xapi/block/%k", \
        RUN+="/bin/sh -c '/opt/xensource/libexec/local-device-change %k 2>&1 >/dev/null&'"

LABEL="md_end"
```

