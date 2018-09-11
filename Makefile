include config.mk

.PHONY: all
all: deps rootfs image

.PHONY: ci
ci: lint

.PHONY: clean
clean:
	@rm -f .make/bin/shellcheck
	@rm -rf "$(rootfs)" "$(image)" /tmp/debian.iso
	@rm -rf dist/*.tar.gz

.PHONY: deps
deps: deps-rootfs deps-image deps-install

.PHONY: dist
dist: $(rootfs) $(image)
	cd $(rootfs) && tar -czf "$$OLDPWD/dist/ntos-rootfs-w37-x64.tar.gz" .
	@rm -rf "$(image)/syslinux/syslinux.cfg" "$(image)/EFI/boot/syslinux.cfg"
	cd $(image) && tar -czf "$$OLDPWD/dist/ntos-image-w37-x64.tar.gz" .
	@$(MAKE) -s image

.PHONY: help
help:
	@cat HELP.txt

# Rootfs

.PHONY: deps-rootfs
deps-rootfs:
	@apt-get install -y debootstrap > /dev/null

.PHONY: login
login: $(rootfs)
	@echo "You are now in the rootfs ($(rootfs)), when you finish type: exit"
	@ROOTFS="$(rootfs)" scripts/rootfs/run.sh bash
	@$(MAKE) -s rootfs-clean

.PHONY: rootfs
rootfs: $(rootfs) rootfs-clean

.PHONY: rootfs-clean
rootfs-clean:
	ROOTFS="$(rootfs)" scripts/rootfs/clean.sh

$(rootfs): scripts/rootfs/create.sh scripts/rootfs/setup.sh
	ROOTFS="$(rootfs)" MIRROR="$(mirror)" PACKAGES="$(packages)" $<
	ROOTFS="$(rootfs)" MIRROR="$(mirror)" $(word 2,$^)
	cp -f scripts/post-install.sh "$(rootfs)/usr/bin/"

# Image

.PHONY: deps-image
deps-image:
	@apt-get install -y p7zip squashfs-tools syslinux syslinux-efi wget > /dev/null

.PHONY: image
image: $(image)
	IMAGE="$(image)" \
	HOSTNAME="$(hostname)" \
	USERNAME="$(username)" \
	TIMEZONE="$(timezone)" \
	scripts/image/menu.sh

$(image): scripts/image/create.sh
	@rm -rf "$(image)"
	ROOTFS="$(rootfs)" IMAGE="$(image)" $<

# Install

.PHONY: deps-install
deps-install:
	@apt-get install -y cryptsetup dosfstools fdisk syslinux > /dev/null

.PHONY: install
install: image
	IMAGE="$(image)" scripts/install.sh

# Development

.PHONY: deps-dev
deps-dev: .make/vendor/shellcheck

.PHONY: lint
lint: .make/bin/shellcheck
	$< -s sh \
		$$(find .make/scripts/ -name "*.sh" -exec echo {} +) \
		$$(find scripts/ -name "*.sh" -exec echo {} +)

.PHONY: lint-md
lint-md:
	@docker run --rm -it -v "$$PWD":/files/ ntrrg/md-linter

.make/bin/shellcheck: .make/scripts/install-shellcheck.sh
	@RELEASE=$(shellcheck_release) DEST=$@ $<
