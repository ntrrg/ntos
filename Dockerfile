FROM debian:buster AS src
RUN \
  apt-get update && \
  apt-get install -y \
    btrfs-progs \
    cryptsetup \
    dosfstools \
    linux-image-amd64 \
    live-boot \
    live-config \
    locales \
    lvm2 \
    && \
  echo "CRYPTSETUP=y" >> /etc/cryptsetup-initramfs/conf-hook && \
  live-update-initramfs -u && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf /var/cache/apt/* /var/lib/apt/lists/* && \
  localedef -ci en_US -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
  echo 'LANG="en_US.utf8"' >> /etc/profile

FROM debian:buster AS build
RUN \
  apt-get update && \
  apt-get install -y \
    btrfs-tools \
    cryptsetup \
    dosfstools \
    lvm2 \
    syslinux \
    syslinux-efi
COPY --from=src / /src/
COPY dist/ image/ setup.sh config.sh /
RUN \
  sh setup.sh /image/ && \
  \
  cp /src/boot/vmlinuz* /image/live/vmlinuz && \
  cp /src/boot/initrd* /image/live/initrd.img && \
  cp /src/boot/vmlinuz* /image/EFI/boot/vmlinuz && \
  cp /src/boot/initrd* /image/EFI/boot/initrd.img && \
  mksquashfs /src/ /image/live/filesystem.squashfs && \
  \
  cd /usr/lib/syslinux/modules/bios/ && \
  cp libutil.c32 menu.c32 /image/syslinux/ && \
  cd /usr/lib/syslinux/modules/bios/ && \
  cp hdt.c32 libcom32.c32 libgpl.c32 libmenu.c32 /image/syslinux/ && \
  cd /usr/lib/SYSLINUX.EFI/efi64/ && \
  cp syslinux.efi /image/EFI/boot/bootx64.efi && \
  cd /usr/lib/syslinux/modules/efi64/ && \
  cp ldlinux.e64 libutil.c32 menu.c32 /image/EFI/boot/ && \
  cp hdt.c32 libcom32.c32 libgpl.c32 libmenu.c32 /image/EFI/boot/ && \
  \
  cp /usr/lib/SYSLINUX/gptmbr.bin /dist/
