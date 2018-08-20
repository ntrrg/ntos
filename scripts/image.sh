#!/bin/sh
# Copyright (c) 2018 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e

# Customizable variables:
#
# * NO_DEBIAN_INSTALLER
# * ISO_URL

IMAGE=${IMAGE:-/tmp/image}
ROOTFS=${ROOTFS:-/tmp/rootfs}
HOSTNAME=${HOSTNAME:-NtFlash}
USERNAME=${USERNAME:-ntrrg}
TIMEZONE=${TIMEZONE:-America/Caracas}

on_error() {
  trap - INT EXIT TERM

  if [ -f /tmp/.ntos-image-build ]; then
    rm -rf /tmp/.ntos-image-build /tmp/debian-iso "$IMAGE"

    return 1
  fi

  return 0
}

trap on_error INT EXIT TERM

syslinux_config() {
  cat <<EOF
UI menu.c32
prompt 0
timeout 50
menu title NtOS

label start
  menu default
  menu label ^Start
  kernel ${PREFIX}live/vmlinuz
  initrd ${PREFIX}live/initrd.img
  append boot=live components noroot noautologin hostname=$HOSTNAME username=$USERNAME timezone=$TIMEZONE quiet persistence persistence-encryption=luks
EOF

  if [ -z "$NO_DEBIAN_INSTALLER" ]; then
    cat <<EOF

menu begin install
  menu label ^Install Debian Buster
  menu title Install Debian Buster

  label install
    menu label ^Install
    kernel ${PREFIX}install/vmlinuz
    initrd ${PREFIX}install/initrd.gz
    append vga=788 quiet

  label install-expert
    menu label ^Expert install
    kernel ${PREFIX}install/vmlinuz
    initrd ${PREFIX}install/initrd.gz
    append vga=788 priority=low

  label install-auto
    menu label ^Automated install
    kernel ${PREFIX}install/vmlinuz
    initrd ${PREFIX}install/initrd.gz
    append vga=788 priority=critical auto=true quiet

  label back
    menu label ^Go back
    menu exit
menu end
EOF
  fi
}

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

PREFIX="" syslinux_config > "$IMAGE/EFI/boot/syslinux.cfg"

mkdir -p "$IMAGE/syslinux"

cp \
  /usr/lib/syslinux/modules/bios/libutil.c32 \
  /usr/lib/syslinux/modules/bios/menu.c32 \
"$IMAGE/syslinux/"

PREFIX="/EFI/boot/" syslinux_config > "$IMAGE/syslinux/syslinux.cfg"

rm -rf /tmp/.ntos-image-build
