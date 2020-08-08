

## create local SR for ISOs

    mkdir -p /var/opt/xen/ISO_Store
    xe sr-create name-label=LocalISO type=iso device-config:location=/var/opt/xen/ISO_Store device-config:legacy_mode=true content-type=iso

src: https://www.reddit.com/r/homelab/comments/aeloe5/local_repository_creation_on_xcpng/edshbn4/
