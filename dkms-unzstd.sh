#!/usr/bin/env bash
# Unzstd DKMS kernel modules and update initramfs
#
# Decompresses both the installed modules and DKMS's own built copies.  If only the
# installed copies are decompressed, `dkms status` reports "Diff between built and
# installed module", which makes /etc/kernel/prerm.d/dkms skip cleanup when the
# kernel is later removed (leaving an orphaned /var/lib/dkms entry behind).

VERSION="20261009"

set -e
shopt -s nullglob

KERNEL=${1:-$(uname -r)}
DKMS_PATH="/usr/lib/modules/$KERNEL/updates/dkms"

echo "Kernel: $KERNEL"

installed=( "$DKMS_PATH"/*.ko.zst )
built=( /var/lib/dkms/*/kernel-"$KERNEL"-*/module/*.ko.zst )

if (( ${#installed[@]} == 0 && ${#built[@]} == 0 )); then
    echo "No compressed modules found — nothing to do."
    exit 0
fi

if (( ${#built[@]} > 0 )); then
    echo "Decompressing DKMS built modules..."
    sudo unzstd --rm "${built[@]}"
fi

if (( ${#installed[@]} > 0 )); then
    echo "Decompressing modules in $DKMS_PATH..."
    sudo unzstd --rm "${installed[@]}"

    echo "Updating module dependencies..."
    sudo depmod -a "$KERNEL"

    echo "Rebuilding initramfs..."
    sudo update-initramfs -u -k "$KERNEL"
fi

echo "Done."
