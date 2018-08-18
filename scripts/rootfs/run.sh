#!/bin/sh

on_error() {
  trap - INT EXIT TERM

  if [ -f /tmp/.ntos-rootfs-run ]; then
    umount "$ROOTFS/proc" "$ROOTFS/sys"
    rm -rf /tmp/.ntos-rootfs-run
    return 1
  fi

  return 0
}

trap on_error INT EXIT TERM

if [ ! -d "$ROOTFS" ]; then
  echo "Can't find the rootfs: $ROOTFS" > /dev/stderr
  exit 1
fi

echo "" > /tmp/.ntos-rootfs-run

mount -o bind /proc "$ROOTFS/proc"
mount -o bind /sys "$ROOTFS/sys"

chroot "$ROOTFS" "$@"

umount "$ROOTFS/proc" "$ROOTFS/sys"

rm -f /tmp/.ntos-rootfs-run
