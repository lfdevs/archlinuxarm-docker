#!/bin/bash

set -euo pipefail

# Fixed TZ to ensure consistency
export TZ=UTC

declare -r WRAPPER="fakechroot -- fakeroot"

declare -r GROUP="$1"
declare -r BUILDDIR="$2"
declare -r OUTPUTDIR="$3"
declare -r DRZEE_KEY_FINGERPRINT="9B2C213B21883BB65CE2FB900CF25682E6BA0751"

case "$GROUP" in
    base | base-devel) ;;
    *)
        echo "Unsupported AArch64 image group: $GROUP" >&2
        exit 2
        ;;
esac

mkdir -vp "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks"
find /usr/share/libalpm/hooks -exec ln -sf /dev/null "$BUILDDIR/alpm-hooks"{} \;

mkdir -vp "$BUILDDIR/var/lib/pacman/" "$OUTPUTDIR"
install -Dm644 "pacman.conf.d/aarch64.conf" "$BUILDDIR/etc/pacman.conf"
cat pacman-conf.d-noextract.conf >> "$BUILDDIR/etc/pacman.conf"

sed 's/Include = /&rootfs/g' < "$BUILDDIR/etc/pacman.conf" > pacman.conf

if grep -q '#DisableSandboxFilesystem' "$BUILDDIR/etc/pacman.conf"; then
sed -i '/#DisableSandboxFilesystem/{c\
# No kernel landlock in containerd\
DisableSandboxFilesystem
}' "$BUILDDIR/etc/pacman.conf"
else
sed -i '/#DisableSandbox/{c\
# No kernel landlock in containerd\
DisableSandbox
}' "$BUILDDIR/etc/pacman.conf"
fi

cp --recursive --preserve=timestamps rootfs/* "$BUILDDIR/"
ln -fs /usr/lib/os-release "$BUILDDIR/etc/os-release"

# Seed a target keyring before the first transaction so pacman can verify
# packages from drzee.net while building the rootfs.
install -d -m 700 "$BUILDDIR/etc/pacman.d/gnupg"
$WRAPPER -- pacman-key --gpgdir "$BUILDDIR/etc/pacman.d/gnupg" --init
$WRAPPER -- pacman-key --gpgdir "$BUILDDIR/etc/pacman.d/gnupg" --add keys/drzee.gpg
$WRAPPER -- pacman-key --gpgdir "$BUILDDIR/etc/pacman.d/gnupg" --lsign-key "$DRZEE_KEY_FINGERPRINT"

packages=(base)
if [[ "$GROUP" == "base-devel" ]]; then
    packages+=(base-devel)
fi

$WRAPPER -- \
    pacman -Sy -r "$BUILDDIR" \
        --disable-sandbox \
        --disable-download-timeout \
        --noconfirm --dbpath "$BUILDDIR/var/lib/pacman" \
        --config pacman.conf \
        --noscriptlet \
        --hookdir "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks/" \
        "${packages[@]}"

$WRAPPER -- chroot "$BUILDDIR" update-ca-trust
install -Dm644 keys/drzee.gpg "$BUILDDIR/usr/share/pacman/keyrings/drzee.gpg"
install -Dm644 keys/drzee-trusted "$BUILDDIR/usr/share/pacman/keyrings/drzee-trusted"
$WRAPPER -- chroot "$BUILDDIR" pacman-key --init
$WRAPPER -- chroot "$BUILDDIR" pacman-key --populate archlinux drzee

# add system users
$WRAPPER -- chroot "$BUILDDIR" /usr/bin/systemd-sysusers --root "/"

# remove passwordless login for root (see CVE-2019-5021 for reference)
sed -i -e 's/^root::/root:!:/' "$BUILDDIR/etc/shadow"

# fakeroot to map the gid/uid of the builder process to root
# fixes #22
fakeroot -- \
    tar \
        --numeric-owner \
        --xattrs \
        --acls \
        --exclude-from=exclude \
        -C "$BUILDDIR" \
        -c . \
        -f "$OUTPUTDIR/$GROUP.tar"

cd "$OUTPUTDIR"
zstd --long -T0 -8 "$GROUP.tar"
sha256sum "$GROUP.tar.zst" > "$GROUP.tar.zst.SHA256"
