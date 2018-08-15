#!/bin/sh

set -e

ROOTFS=${ROOTFS:-/tmp/rootfs}
MIRROR=${MIRROR:-http://deb.debian.org/debian}

on_error() {
  trap - INT EXIT TERM

  if [ -f /tmp/.building-rootfs ]; then
    umount "$ROOTFS/proc" "$ROOTFS/sys" || true
    rm -rf /tmp/.building-rootfs "$ROOTFS"
    return 1
  fi

  return 0
}

trap on_error INT EXIT TERM

CHROOT() {
  DEBIAN_FRONTEND=noninteractive chroot "$ROOTFS" $@
}

echo "" > /tmp/.building-rootfs

if [ ! -d "$ROOTFS" ]; then
  debootstrap --variant=minbase --include="
    btrfs-progs,
    cryptsetup,
    dosfstools,
    linux-image-amd64,
    locales,
    lvm2,
    rfkill,
    systemd-sysv,
    wpasupplicant
  " buster "$ROOTFS" "$MIRROR"
fi

mount -o bind /proc "$ROOTFS/proc"
mount -o bind /sys "$ROOTFS/sys"

cat <<EOF > "$ROOTFS/etc/apt/sources.list"
deb $MIRROR buster main contrib non-free
EOF

CHROOT localedef \
  -ci en_US \
  -f UTF-8 \
  -A /usr/share/locale/locale.alias \
en_US.UTF-8

CHROOT apt-get update
CHROOT apt-get upgrade -qy
CHROOT apt-get autoremove -y

CHROOT apt-get install -qy live-boot live-config

cat <<EOF > "$ROOTFS/etc/cryptsetup-initramfs/conf-hook"
#
# Configuration file for the cryptroot initramfs hook.
#

#
# CRYPTSETUP: [ y | n ]
#
# Add cryptsetup and its dependencies to the initramfs image, regardless
# of _this_ machine configuration.  By default, they're only added when
# a device is detected that needs to be unlocked at initramfs stage
# (such as root or resume devices or ones with explicit 'initramfs' flag
# in /etc/crypttab).
# Note: Honoring this setting will be deprecated in the future.  Please
# uninstall the 'cryptsetup-initramfs' package if you don't want the
# cryptsetup initramfs integration.
#

CRYPTSETUP=y

#
# KEYFILE_PATTERN: ...
#
# The value of this variable is interpreted as a shell pattern.
# Matching key files from the crypttab(5) are included in the initramfs
# image.  The associated devices can then be unlocked without manual
# intervention.  (For instance if /etc/crypttab lists two key files
# /etc/keys/{root,swap}.key, you can set KEYFILE_PATTERN="/etc/keys/*.key"
# to add them to the initrd.)
#
# If KEYFILE_PATTERN if null or unset (default) then no key file is
# copied to the initramfs image.
#
# WARNING: If the initramfs image is to include private key material,
# you'll want to create it with a restrictive umask in order to keep
# non-privileged users at bay.  For instance, set UMASK=0077 in
# /etc/initramfs-tools/initramfs.conf
#

#KEYFILE_PATTERN=
EOF

CHROOT live-update-initramfs -u

CHROOT mv \
  /usr/share/i18n/locales/en_GB \
  /usr/share/i18n/locales/en_US \
  /usr/share/locale/locale.alias \
  /tmp/

CHROOT rm -rf \
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

CHROOT mv /tmp/en_GB /tmp/en_US /usr/share/i18n/locales/
CHROOT mv /tmp/locale.alias /usr/share/locale/

CHROOT sh -c "echo 'root:root' | chpasswd"
rm -f "$ROOTFS/etc/hostname" "$ROOTFS/root/.bash_history"
umount "$ROOTFS/proc" "$ROOTFS/sys"
rm -f /tmp/.building-rootfs
