#!/bin/sh

set -e

IMAGE=${IMAGE:-/tmp/image}
ROOTFS=${ROOTFS:-/tmp/rootfs}
ISO_URL=${ISO_URL:-https://cdimage.debian.org/mirror/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso}
HOSTNAME=${HOSTNAME:-NtFlash}
USERNAME=${USERNAME:-ntrrg}
TIMEZONE=${TIMEZONE:-America/Caracas}

on_error() {
  trap - INT EXIT TERM

  if [ -f /tmp/.building-image ]; then
    rm -rf /tmp/.building-image "$IMAGE" "$ROOTFS" /tmp/debian-iso
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
}

echo "" > /tmp/.building-image

mkdir -p "$IMAGE/live" "$IMAGE/EFI/boot/live"
mv "$(find "$ROOTFS/boot" -name "initrd*")" "$IMAGE/EFI/boot/live/initrd.img"
mv "$(find "$ROOTFS/boot" -name "vmlinuz*")" "$IMAGE/EFI/boot/live/vmlinuz"
rm -rf "$ROOTFS/boot"
find "$ROOTFS" -name "initrd*" -delete
find "$ROOTFS" -name "vmlinuz*" -delete
mksquashfs "$ROOTFS" "$IMAGE/live/filesystem.squashfs"

wget -cO /tmp/debian.iso "$ISO_URL"
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

rm -f /tmp/.building-image
