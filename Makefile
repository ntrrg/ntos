include config.mk

.PHONY: all
all: deps image

.PHONY: ci
ci: lint

.PHONY: clean
clean:
	@rm -f .make/vendor/shellcheck
	@rm -rf "$(rootfs)" "$(image)" /tmp/debian.iso
	@rm -rf dist/*.tar.gz

.PHONY: deps
deps: deps-rootfs deps-image deps-install

.PHONY: dist
dist: $(rootfs) $(image)
	cd $(rootfs) && tar -czf "$$OLDPWD/dist/ntos-rootfs-w34-x64.tar.gz" .
	cd $(image) && tar -czf "$$OLDPWD/dist/ntos-image-w34-x64.tar.gz" .

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

$(image): $(rootfs) scripts/image/create.sh
	@rm -rf "$(image)"
	@$(MAKE) -s rootfs-clean
	ROOTFS="$(rootfs)" IMAGE="$(image)" $(word 2,$^)

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
lint: .make/vendor/shellcheck
	$< -s sh \
		$$(find .make/bin -name "*.sh" -exec echo {} +) \
		$$(find scripts/ -name "*.sh" -exec echo {} +)

.PHONY: lint-md
lint-md:
	@docker run --rm -it -v "$$PWD":/files/ ntrrg/md-linter

.make/vendor/shellcheck:
	@RELEASE=$(shellcheck_release) DEST=$@ .make/bin/install-shellcheck.sh
