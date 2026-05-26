#!/usr/bin/env bash
# Unzstd DKMS kernel modules and update initramfs

set -e

KERNEL=${1:-$(uname -r)}
DKMS_PATH="/usr/lib/modules/$KERNEL/updates/dkms"

echo "Kernel: $KERNEL"

if ! compgen -G "$DKMS_PATH/*.ko.zst" > /dev/null 2>&1; then
    echo "No compressed modules found in $DKMS_PATH — nothing to do."
    exit 0
fi

echo "Decompressing modules in $DKMS_PATH..."
cd "$DKMS_PATH"
sudo unzstd --rm *.ko.zst

echo "Updating module dependencies..."
sudo depmod -a "$KERNEL"

echo "Rebuilding initramfs..."
sudo update-initramfs -u -k "$KERNEL"

echo "Done."
