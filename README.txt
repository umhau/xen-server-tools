# xcp-ng-notes

Commands, scripts, and tools that I use to manage my xcp-ng hypervisors.

## RAID

use the raid-autoconf.sh script to create new raid drives. It will handle all
the formatting, etc, so they just have to be present and unmounted. 

To add another drive to the array later, see: 
zackreed.me/adding-an-extra-disk-to-an-mdadm-array/, 
ve3nrt.wordpress.com/2012/07/11/adding-a-drive-to-a-raid-6-array-with-mdadm/

Space, fault tolerance, and performance shown as ratios of single drive 
performance.

RAID      Minimum   Space      Fault      Read      Write performance
level     drives    efficiency tolerance  perf.

RAID 0    2         1          None       n         n
RAID 1    2         1/n        n − 1      n [a]     1 [c]
RAID 4    3         1 − 1/n    1 [b]      n − 1     n − 1 [e]
RAID 5    3         1 − 1/n    1          n [e]     1/4 [e]
RAID 6    4         1 − 2/n    2          n [e]     1/6 [e]

[a]  Theoretical maximum, as low as single-disk performance in practice.
[b]  Just don't lose the pairity disk.
[c]  If disks with different speeds are used in a RAID 1 array, overall write 
     performance is equal to the speed of the slowest disk. 
[e]  That is the worst-case scenario, when the minimum possible data (a single
     logical sector) needs to be written. Best-case scenario, given 
     sufficiently capable hardware and a full sector of data to write: n − 1.

RAID 1 consists of an exact copy (or mirror) of a set of data on two or more 
disks. The array can only be as big as the smallest member disk. This layout 
is useful when read performance or reliability is more important than write 
performance or the resulting data storage capacity. The array will continue 
to operate so long as at least one member drive is operational.

Random read performance of a RAID 1 array may equal up to the sum of each 
member's performance, while the write performance remains at the level of a 
single disk. However, if disks with different speeds are used in a RAID 1 
array, overall write performance is equal to the speed of the slowest disk.

RAID 5 consists of block-level striping with distributed parity. Parity 
information is distributed among the drives. It requires that all drives but 
one be present to operate. Upon failure of a single drive, subsequent reads can
be calculated from the distributed parity such that no data is lost. RAID 5 
requires at least three disks.

RAID 6 is any form of RAID that can continue to execute read and write requests
to all of a RAID array's virtual disks in the presence of any two concurrent 
disk failures. RAID 6 does not have a performance penalty for read operations, 
but it does have a performance penalty on write operations because of the 
overhead associated with parity calculations. RAID 6 can read up to the same 
speed as RAID 5 with the same number of physical drives.

