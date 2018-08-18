#!/bin/sh

set -e

IMAGE=${IMAGE:-/tmp/image}

on_error() {
  trap - INT EXIT TERM

  if [ -f /tmp/.installing-image ]; then
    if [ -f /tmp/.image-partition-mounted ]; then
      rm -f /tmp/.image-partition-mounted
      umount /mnt/
    fi

    if [ -f /tmp/.persistence-partition-mounted ]; then
      rm -f /tmp/.persistence-partition-mounted
      umount /mnt/
    fi

    rm -f /tmp/.installing-image
    return 1
  fi

  return 0
}

trap on_error INT EXIT TERM

echo "" > /tmp/.install-image

while [ ! -b "$DEV" ]; do
  lsblk
  printf "Pick a device (i.e. /dev/sdX): "
  read -r DEV
done

fdisk "$DEV"

DLT=$(fdisk -l "$DEV" | grep "^Disklabel" | sed "s/.*: *//")

if [ "$DLT" = "dos" ]; then
  SYSLINUX_BIN="/usr/lib/SYSLINUX/mbr.bin"
else
  SYSLINUX_BIN="/usr/lib/SYSLINUX/gptmbr.bin"
fi

dd if="$SYSLINUX_BIN" of="$DEV" bs=440 count=1

IPN=0

while [ ! -b "$DEV$IPN" ]; do
  echo ""
  printf "Image partition number: "
  read -r IPN

  if [ -z "$IPN" ]; then
    IPN=0
  fi
done

IP="$DEV$IPN"

mkfs.fat -F 32 -n NTOS "$IP"
mount "$IP" /mnt
echo "" > /tmp/.image-partition-mounted
# shellcheck disable=SC2046
(cd "$IMAGE" && cp -rf $(ls -A) /mnt/)
umount /mnt
rm -f /tmp/.image-partition-mounted
syslinux -id syslinux "$IP"

PPN=0

while [ ! -b "$DEV$PPN" ]; do
  echo ""
  printf "Persistence partition number: "
  read -r PPN

  if [ -z "$PPN" ]; then
    PPN=0
  fi
done

PP="$DEV$PPN"

cryptsetup --verify-passphrase luksFormat "$PP"
cryptsetup luksOpen "$PP" Persistence
mkfs.ext4 -L persistence /dev/mapper/Persistence
mount /dev/mapper/Persistence /mnt/
echo "" > /tmp/.persistence-partition-mounted
echo "/ union" > /mnt/persistence.conf 
umount /mnt
rm -f /tmp/.persistence-partition-mounted
cryptsetup luksClose /dev/mapper/Persistence

rm -f /tmp/.installing-image
