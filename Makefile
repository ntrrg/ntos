include config.mk

.PHONY: all
all: deps rootfs image

.PHONY: clean
clean:
	@rm -rf "$(rootfs)" "$(image)" /tmp/debian.iso
	@rm -rf dist

.PHONY: deps
deps: deps-rootfs deps-image deps-install

.PHONY: dist
dist: dist/ntos-rootfs-w$(week)-x64.tar.gz dist/ntos-image-w$(week)-x64.tar.gz

.PHONY: help
help:
	@cat HELP.txt

# Rootfs

.PHONY: deps-rootfs
deps-rootfs:
	apt-get install -y debootstrap

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

dist/ntos-rootfs-w$(week)-x64.tar.gz: $(rootfs)
	@mkdir -p $$(dirname $@)
	cd $< && tar -czf "$$OLDPWD/$@" .

# Image

.PHONY: deps-image
deps-image:
	apt-get install -y p7zip squashfs-tools syslinux syslinux-efi wget

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

dist/ntos-image-w$(week)-x64.tar.gz: $(image)
	@mkdir -p $$(dirname $@)
	@rm -rf "$(image)/syslinux/syslinux.cfg" "$(image)/EFI/boot/syslinux.cfg"
	cd $< && tar -czf "$$OLDPWD/$@" .
	@$(MAKE) -s image

# Install

.PHONY: deps-install
deps-install:
	apt-get install -y cryptsetup dosfstools fdisk syslinux

.PHONY: install
install: image
	IMAGE="$(image)" scripts/install.sh

# Development

.PHONY: ci
ci: lint

.PHONY: clean-dev
clean-dev: clean
	@rm -rf $(make_bin)

.PHONY: deps-dev
deps-dev: $(make_bin)/shellcheck

.PHONY: lint
lint: $(make_bin)/shellcheck
	$< -s sh \
		$$(find .make/scripts/ -name "*.sh" -exec echo {} +) \
		$$(find scripts/ -name "*.sh" -exec echo {} +)

.PHONY: lint-md
lint-md:
	@docker run --rm -it -v "$$PWD":/files/ ntrrg/md-linter

$(make_bin)/shellcheck: .make/scripts/install-shellcheck.sh
	@mkdir -p $$(dirname $@)
	@RELEASE=$(shellcheck_release) DEST=$@ $<
