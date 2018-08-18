#!/bin/sh

set -e

# Customizable variables:
#
# * DEV
# * IPN
# * NO_PERSISTENCE
# * PPN

IMAGE=${IMAGE:-/tmp/image}

on_error() {
  trap - INT EXIT TERM

  if [ -f /tmp/.ntos-install ]; then
    umount /mnt/ || true
    rm -f /tmp/.ntos-install
    return 1
  fi

  return 0
}

trap on_error INT EXIT TERM

echo "" > /tmp/.ntos-install

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

IPN="${IPN:-0}"

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
# shellcheck disable=SC2046
(cd "$IMAGE" && cp -rf $(ls -A) /mnt/)
umount /mnt
syslinux -id syslinux "$IP"

if [ -z "$NO_PERSISTENCE" ]; then
  PPN="${PPN:-0}"

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
  echo "/ union" > /mnt/persistence.conf 
  umount /mnt
  cryptsetup luksClose /dev/mapper/Persistence
fi

rm -f /tmp/.ntos-install
