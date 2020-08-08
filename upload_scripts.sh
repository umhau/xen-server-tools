#!/bin/bash
set -ev

hypervisor_host_IP="192.168.1.125"

# get path of containing folder
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# remove prior contents
ssh root@$hypervisor_host_IP "rm -rf /root/xcp-ng_config"

# upload contents
scp -r $DIR root@$hypervisor_host_IP:/root/