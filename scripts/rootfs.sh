#!/bin/sh

set -e

ROOTFS=${ROOTFS:-rootfs}

if [ ! -d rootfs ]; then
  debootstrap --variant=minbase --include="
    btrfs-progs,
    cryptsetup,
    dosfstools,
    linux-image-amd64,
    live-boot,
    live-config,
    locales,
    lvm2,
    systemd-sysv
  " buster "$ROOTFS"/ http://deb.debian.org/debian
fi

chroot "$ROOTFS" localedef \
  -ci en_US \
  -f UTF-8 \
  -A /usr/share/locale/locale.alias \
en_US.UTF-8

cat <<EOF > "$ROOTFS"/etc/apt/sources.list
deb http://deb.debian.org/debian buster main contrib non-free
EOF

chroot "$ROOTFS" apt-get update
DEBIAN_FRONTEND=noninteractive chroot "$ROOTFS" apt-get upgrade -qy

echo "CRYPTSETUP=y" >> "$ROOTFS"/etc/cryptsetup-initramfs/conf-hook

mount -o bind /proc "$ROOTFS/proc"
chroot "$ROOTFS" update-initramfs -u
umount "$ROOTFS/proc"

mv \
  "$ROOTFS"/usr/share/i18n/locales/en_US \
  "$ROOTFS"/usr/share/i18n/locales/en_GB \
  "$ROOTFS"/usr/share/locale/locale.alias \
  "$ROOTFS"/tmp/

rm -rf \
  "$ROOTFS"/root/.bash_history \
  "$ROOTFS"/usr/share/i18n/locales/??_* \
  "$ROOTFS"/usr/share/i18n/locales/???_* \
  "$ROOTFS"/usr/share/i18n/locales/eo \
  "$ROOTFS"/usr/share/i18n/locales/iso14651_t1_pinyin \
  "$ROOTFS"/usr/share/locale/* \
  "$ROOTFS"/usr/share/man/?? \
  "$ROOTFS"/usr/share/man/??_* \
  "$ROOTFS"/var/cache/apt/* \
  "$ROOTFS"/var/lib/apt/lists/* \
  "$ROOTFS"/var/log/*

mv "$ROOTFS"/tmp/en_* "$ROOTFS"/usr/share/i18n/locales/
mv "$ROOTFS"/tmp/locale.alias "$ROOTFS"/usr/share/locale/

chroot "$ROOTFS" echo "root:root" | chpasswd
