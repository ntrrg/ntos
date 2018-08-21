include config.mk

.PHONY: all
all: deps rootfs image

.PHONY: help
help:
	@cat HELP.txt

.PHONY: clean
clean:
	@rm -f .make/vendor/shellcheck
	@rm -rf "$(rootfs)" "$(image)" /tmp/debian.iso

.PHONY: lint
lint: .make/vendor/shellcheck
	$< -s sh \
		$$(find .make/bin -name "*.sh" -exec echo {} +) \
		$$(find scripts/ -name "*.sh" -exec echo {} +)

.PHONY: ci
ci: lint

.PHONY: deps-rootfs
deps-rootfs:
	@apt-get install -y debootstrap > /dev/null

.PHONY: deps-image
deps-image:
	@apt-get install -y p7zip squashfs-tools syslinux syslinux-efi wget > /dev/null

.PHONY: deps-install
deps-install:
	@apt-get install -y cryptsetup dosfstools fdisk syslinux > /dev/null

.PHONY: deps
deps: deps-rootfs deps-image deps-install

.make/vendor/shellcheck:
	@RELEASE=$(shellcheck_release) DEST=$@ .make/bin/install-shellcheck.sh

.PHONY: deps-dev
deps-dev: .make/vendor/shellcheck

$(rootfs): scripts/rootfs/create.sh
	ROOTFS="$(rootfs)" MIRROR="$(mirror)" PACKAGES="$(packages)" $<

.PHONY: rootfs-setup
rootfs-setup: $(rootfs)
	ROOTFS="$(rootfs)" MIRROR="$(mirror)" scripts/rootfs/setup.sh

.PHONY: rootfs-clean
rootfs-clean: $(rootfs)
	ROOTFS="$(rootfs)" scripts/rootfs/clean.sh

.PHONY: rootfs
rootfs: $(rootfs) rootfs-setup rootfs-clean
	@cp -f scripts/post-install.sh "$(rootfs)/usr/bin/"

.PHONY: login
login: $(rootfs)
	@echo "You are now in the rootfs ($(rootfs)), when you finish type: exit"
	@ROOTFS="$(rootfs)" scripts/rootfs/run.sh bash

$(image): scripts/image/create.sh $(rootfs)
	ROOTFS="$(rootfs)" IMAGE="$(image)" $<

.PHONY: image
image: $(image)
	IMAGE="$(image)" \
	HOSTNAME="$(hostname)" \
	USERNAME="$(username)" \
	TIMEZONE="$(timezone)" \
	scripts/image/menu.sh

.PHONY: install
install: $(image)
	IMAGE="$(image)" scripts/install.sh

.PHONY: dist
dist: $(rootfs)
	cd $(rootfs) && tar -czf "$$OLDPWD/dist/ntos-rootfs-w34-x64.tar.gz" .
