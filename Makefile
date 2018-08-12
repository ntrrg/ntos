include config.mk

.PHONY: all
all: build

.PHONY: build
build: $(rootfs) $(image)

.PHONY: clean
clean:
	@rm -rf "$(rootfs)" "$(image)" /tmp/debian-iso /tmp/debian.iso

.PHONY: deps
deps: deps-rootfs deps-image

.PHONY: deps-rootfs
deps-rootfs:
	apt-get install -y \
		debootstrap

.PHONY: deps-image
deps-image:
	apt-get install -y \
		7z \
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
	HOSTNAME="$(hostname)" \
	USERNAME="$(username)" \
	TIMEZONE="$(timezone)" \
	$<
