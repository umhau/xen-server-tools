#!/bin/bash

set -ev

iso="$1"
repository_uuid="2006096b-52b5-0dc5-fc1c-e9be67168ab3"
hypervisor_host_IP="192.168.1.125"
repository_filepath="/var/opt/xen/ISO_Store"

# upload ISO to repository
scp $iso root@$hypervisor_host_IP:$repository_filepath

# update repository
ssh root@$hypervisor_host_IP "xe sr-scan uuid=$repository_uuid"

