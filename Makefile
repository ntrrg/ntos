include config.mk

.PHONY: all
all: build

.PHONY: build
build: $(rootfs)

.PHONY: clean
clean:
	@rm -rf $(rootfs)

$(rootfs): scripts/rootfs.sh
	ROOTFS="$@" scripts/rootfs.sh || rm -rf $@
