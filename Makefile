include config.mk

.PHONY: all
all: build

.PHONY: build
build: $(rootfs) $(image)

.PHONY: clean
clean:
	@rm -rf "$(rootfs)" "$(image)" /tmp/debian-iso /tmp/debian.iso

.PHONY: deps
deps:
	apt-get install -y \
		7z \
		debootstrap \
		squashfs-tools \
		syslinux \
		syslinux-efi \
		wget

.PHONY: $(rootfs)
$(rootfs): scripts/rootfs.sh
	ROOTFS="$@" $<

.PHONY: $(image)
$(image): scripts/image.sh
	ROOTFS="$(rootfs)" \
	HOSTNAME="$(image_hostname)" \
	USERNAME="$(image_username)" \
	TIMEZONE="$(image_timezone)" \
	$<
