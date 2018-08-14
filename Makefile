include config.mk

.PHONY: all
all: build

.PHONY: build
build: rootfs image

.PHONY: clean
clean:
	@rm -rf "$(rootfs)" "$(image)" /tmp/debian-iso /tmp/debian.iso

.PHONY: deps
deps: deps-rootfs deps-image deps-install

.PHONY: deps-image
deps-image:
	apt-get install -y p7zip squashfs-tools syslinux syslinux-efi wget

.PHONY: deps-install
deps-install:
	apt-get install -y cryptsetup dosfstools fdisk syslinux

.PHONY: deps-rootfs
deps-rootfs:
	apt-get install -y debootstrap

.PHONY: image
image:
	IMAGE="$(image)" \
	ROOTFS="$(rootfs)" \
	HOSTNAME="$(hostname)" \
	USERNAME="$(username)" \
	TIMEZONE="$(timezone)" \
	scripts/image.sh

.PHONY: install
install:
	IMAGE="$(image)" scripts/install.sh

.PHONY: rootfs
rootfs:
	ROOTFS="$(rootfs)" scripts/rootfs.sh
