#!/bin/sh

set -e

ROOTFS=${ROOTFS:-rootfs}

if [ ! -d "$ROOTFS" ]; then
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
  " buster "$ROOTFS" http://deb.debian.org/debian
fi

mount -o bind /proc "$ROOTFS/proc"

chroot "$ROOTFS" localedef \
  -ci en_US \
  -f UTF-8 \
  -A /usr/share/locale/locale.alias \
en_US.UTF-8

cat <<EOF > "$ROOTFS/etc/apt/sources.list"
deb http://deb.debian.org/debian buster main contrib non-free
EOF

chroot "$ROOTFS" apt-get update
DEBIAN_FRONTEND=noninteractive chroot "$ROOTFS" apt-get upgrade -qy

echo "CRYPTSETUP=y" >> "$ROOTFS/etc/cryptsetup-initramfs/conf-hook"
chroot "$ROOTFS" update-initramfs -u

chroot "$ROOTFS" mv \
  /usr/share/i18n/locales/en_GB \
  /usr/share/i18n/locales/en_US \
  /usr/share/locale/locale.alias \
  /tmp/

chroot "$ROOTFS" rm -rf \
  /usr/share/i18n/locales/??_* \
  /usr/share/i18n/locales/???_* \
  /usr/share/i18n/locales/eo \
  /usr/share/i18n/locales/iso14651_t1_pinyin \
  /usr/share/locale/* \
  /usr/share/man/?? \
  /usr/share/man/??_* \
  /var/cache/apt/* \
  /var/lib/apt/lists/* \
  /var/log/*

chroot "$ROOTFS" mv /tmp/en_GB /tmp/en_US /usr/share/i18n/locales/
chroot "$ROOTFS" mv /tmp/locale.alias /usr/share/locale/

chroot "$ROOTFS" echo "root:root" | chpasswd
rm -f "$ROOTFS/root/.bash_history"
umount "$ROOTFS/proc"
