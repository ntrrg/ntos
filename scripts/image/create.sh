#!/bin/sh
# Copyright (c) 2018 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e

# Customizable variables:
#
# * NO_DEBIAN_INSTALLER
# * ISO_URL

if [ -d "$IMAGE" ]; then
  touch "$IMAGE"
  exit
fi

on_error() {
  trap - INT EXIT TERM

  if [ -f /tmp/.ntos-image-build ]; then
    rm -rf /tmp/.ntos-image-build /tmp/debian-iso "$IMAGE"

    return 1
  fi

  return 0
}

trap on_error INT EXIT TERM

echo "" > /tmp/.ntos-image-build

mkdir -p "$IMAGE/live" "$IMAGE/EFI/boot/live"
cp "$(find "$ROOTFS/boot" -name "initrd*")" "$IMAGE/EFI/boot/live/initrd.img"
cp "$(find "$ROOTFS/boot" -name "vmlinuz*")" "$IMAGE/EFI/boot/live/vmlinuz"
mksquashfs "$ROOTFS" "$IMAGE/live/filesystem.squashfs"

if [ -z "$NO_DEBIAN_INSTALLER" ]; then
  if [ ! -f /tmp/debian.iso ]; then
    ISO_URL=${ISO_URL:-https://cdimage.debian.org/mirror/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso}

    wget -O /tmp/debian.iso "$ISO_URL"
  fi

  7z x /tmp/debian.iso -o/tmp/debian-iso
  chmod -R +rX /tmp/debian-iso

  mv \
    /tmp/debian-iso/.disk \
    "/tmp/debian-iso/[BOOT]" \
    /tmp/debian-iso/dists \
    /tmp/debian-iso/pool \
    /tmp/debian-iso/tools \
  "$IMAGE/"

  mkdir -p "$IMAGE/EFI/boot/install"

  mv \
    /tmp/debian-iso/install.amd/initrd.gz \
    /tmp/debian-iso/install.amd/vmlinuz \
  "$IMAGE/EFI/boot/install/"

  rm -rf /tmp/debian-iso
fi

cp \
  /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi \
"$IMAGE/EFI/boot/bootx64.efi"

cp \
  /usr/lib/syslinux/modules/efi64/ldlinux.e64 \
  /usr/lib/syslinux/modules/efi64/libutil.c32 \
  /usr/lib/syslinux/modules/efi64/menu.c32 \
"$IMAGE/EFI/boot/"

mkdir -p "$IMAGE/syslinux"

cp \
  /usr/lib/syslinux/modules/bios/libutil.c32 \
  /usr/lib/syslinux/modules/bios/menu.c32 \
"$IMAGE/syslinux/"

rm -rf /tmp/.ntos-image-build
