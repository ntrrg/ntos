#!/bin/sh

set -e

if [ -d "$ROOTFS" ]; then
  touch "$ROOTFS"
  exit
fi

on_error() {
  trap - INT EXIT TERM

  if [ -f /tmp/.ntos-rootfs-create ]; then
    rm -rf /tmp/.ntos-rootfs-create "$ROOTFS"
    return 1
  fi

  return 0
}

trap on_error INT EXIT TERM

echo "" > /tmp/.ntos-rootfs-create

debootstrap \
  --variant=minbase \
  --include="$PACKAGES" \
buster "$ROOTFS" "$MIRROR"

rm -f /tmp/.ntos-rootfs-create
