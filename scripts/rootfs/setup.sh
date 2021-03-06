#!/bin/sh
# Copyright (c) 2018 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e

cat <<EOF > "$ROOTFS/etc/apt/sources.list"
deb $MIRROR buster main contrib non-free
EOF

scripts/rootfs/run.sh localedef \
  -ci en_US \
  -f UTF-8 \
  -A /usr/share/locale/locale.alias \
en_US.UTF-8

scripts/rootfs/run.sh apt-get update > /dev/null
DEBIAN_FRONTEND="noninteractive" \
  scripts/rootfs/run.sh apt-get upgrade -qy > /dev/null

DEBIAN_FRONTEND="noninteractive" scripts/rootfs/run.sh \
  apt-get install -qy live-boot live-config > /dev/null

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

scripts/rootfs/run.sh live-update-initramfs -u > /dev/null

scripts/rootfs/run.sh sh -c "echo 'root:root' | chpasswd"
rm -f "$ROOTFS/etc/hostname"
