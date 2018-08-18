include config.mk

.PHONY: all
all: rootfs image

.PHONY: clean
clean:
	@rm -f .make/vendor/shellcheck
	@rm -rf "$(rootfs)" "$(image)" /tmp/debian.iso

.PHONY: lint
lint: .make/vendor/shellcheck
	$< -s sh $$(find . -name "*.sh" -exec echo {} +)

.PHONY: ci
ci: lint

.PHONY: deps-rootfs
deps-rootfs:
	apt-get install -y debootstrap

.PHONY: deps-image
deps-image:
	apt-get install -y p7zip squashfs-tools syslinux syslinux-efi wget

.PHONY: deps-install
deps-install:
	apt-get install -y cryptsetup dosfstools fdisk syslinux

.PHONY: deps
deps: deps-rootfs deps-image deps-install

.make/vendor/shellcheck:
	@RELEASE=$(shellcheck_release) DEST=$@ .make/bin/install-shellcheck.sh

.PHONY: deps-dev
deps-dev: .make/vendor/shellcheck

$(rootfs): scripts/rootfs/create.sh
	ROOTFS="$(rootfs)" MIRROR="$(mirror)" PACKAGES="$(packages)" $<

.PHONY: rootfs-setup
rootfs-setup: scripts/rootfs/setup.sh
	ROOTFS="$(rootfs)" MIRROR="$(mirror)" $<

.PHONY: rootfs-clean
rootfs-clean: scripts/rootfs/clean.sh
	ROOTFS="$(rootfs)" $<

.PHONY: rootfs
rootfs: $(rootfs) rootfs-setup rootfs-clean
	#ROOTFS="$(rootfs)" scripts/rootfs.sh

.PHONY: login
login: scripts/rootfs/run.sh
	@ROOTFS="$(rootfs)" $< bash

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
