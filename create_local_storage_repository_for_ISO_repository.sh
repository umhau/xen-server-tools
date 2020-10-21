#!/bin/bash
# create local storage repository (SR) for ISOs
# src: https://www.reddit.com/r/homelab/comments/aeloe5/local_repository_creation_on_xcpng/edshbn4/
set -ev

sr_path="/var/opt/xen/ISO_Store"

mkdir -pv $sr_path
xe sr-create name-label=LocalISO type=iso device-config:location=$sr_path device-config:legacy_mode=true content-type=iso
