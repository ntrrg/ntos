week := 46

# Rootfs

rootfs := /tmp/rootfs
mirror := http://deb.debian.org/debian
packages := \
	btrfs-progs, \
	cryptsetup, \
	dosfstools, \
	isc-dhcp-client, \
	linux-image-amd64, \
	locales, \
	lvm2, \
	rfkill, \
	systemd-sysv, \
	wireless-tools, \
	wpasupplicant

# Image

image := /tmp/image
hostname := NtFlash
username := ntrrg
timezone := America/Caracas

# Development

make_bin := /tmp/$(shell basename "$$PWD")-bin
shellcheck_release := 0.4.7
