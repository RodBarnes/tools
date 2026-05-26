#!/usr/bin/env bash
# Automatic postinst hook: decompress DKMS kernel modules if compressed
# Place in /etc/kernel/postinst.d/ (no .sh extension, executable)
# See: https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2154307

VERSION="20260526"

KERNEL=$1

if [ -z "$KERNEL" ]; then
    echo "zz-dkms-unzstd: ERROR — no kernel version passed as \$1. Exiting."
    exit 1
fi

DKMS_PATH="/usr/lib/modules/$KERNEL/updates/dkms"

if ! compgen -G "$DKMS_PATH/*.ko.zst" > /dev/null 2>&1; then
    exit 0
fi

echo "zz-dkms-unzstd: NOTICE — Bug #2154307 still active. DKMS modules for $KERNEL are compressed. Applying workaround."
echo "zz-dkms-unzstd: Decompressing modules in $DKMS_PATH..."
cd "$DKMS_PATH"
unzstd --rm *.ko.zst

echo "zz-dkms-unzstd: Updating module dependencies..."
depmod -a "$KERNEL"

echo "zz-dkms-unzstd: Rebuilding initramfs..."
update-initramfs -u -k "$KERNEL"

echo "zz-dkms-unzstd: Done."
