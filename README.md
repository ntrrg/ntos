## Rootfs

```shell-session
# apt update && apt upgrade
```

```shell-session
# apt install debootstrap
```

```shell-session
# debootstrap \
  --variant=minbase \
  --include="
    btrfs-progs,
    cryptsetup,
    dosfstools,
    linux-image-amd64,
    locales,
    lvm2,
    systemd-sysv
  " \
buster /tmp/rootfs http://deb.debian.org/debian
```

```shell-session
# mount -o bind /proc /tmp/rootfs/proc
```

```shell-session
# mount -o bind /sys /tmp/rootfs/sys
```

```shell-session
# chroot /tmp/rootfs bash
```

---

```shell-session
# passwd
```

```shell-session
# cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian buster main contrib non-free
EOF
```

```shell-session
# localedef \
  -ci en_US \
  -f UTF-8 \
  -A /usr/share/locale/locale.alias \
en_US.UTF-8
```

```shell-session
# apt update && apt upgrade
```

```shell-session
# apt autoremove
```

```shell-session
# DEBIAN_FRONTEND=noninteractive apt install -qy live-boot live-config
```

```shell-session
# echo "CRYPTSETUP=y" >> /etc/cryptsetup-initramfs/conf-hook
```

```shell-session
# live-update-initramfs -u
```

```shell-session
# mv \
  /usr/share/i18n/locales/en_GB \
  /usr/share/i18n/locales/en_US \
  /usr/share/locale/locale.alias \
  /tmp/
```

```shell-session
# rm -rf \
  /usr/share/i18n/locales/??_* \
  /usr/share/i18n/locales/???_* \
  /usr/share/i18n/locales/eo \
  /usr/share/i18n/locales/iso14651_t1_pinyin \
  /usr/share/locale/* \
  /usr/share/man/?? \
  /usr/share/man/??_* \
  /var/cache/apt/* \
  /var/lib/apt/lists/* \
  /var/log/*
```

```shell-session
# mv /tmp/en_* /usr/share/i18n/locales/
```

```shell-session
# mv /tmp/locale.alias /usr/share/locale/
```

```shell-session
# poweroff
```

---

```shell-session
# rm -f /tmp/rootfs/etc/hostname /tmp/rootfs/root/.bash_history
```

```shell-session
# umount /tmp/rootfs/proc /tmp/rootfs/sys
```

## Image

```shell-session
# apt install 7z squashfs-tools syslinux syslinux-efi wget
```

```shell-session
# mkdir -p /tmp/image/live /tmp/image/EFI/boot/live
```

```shell-session
# mv /tmp/rootfs/boot/vmlinuz* /tmp/image/EFI/boot/live/vmlinuz
```

```shell-session
# mv /tmp/rootfs/boot/initrd* /tmp/image/EFI/boot/live/initrd.img
```

```shell-session
# rm -rf /tmp/rootfs/boot /tmp/rootfs/initrd.img* /tmp/rootfs/vmlinuz*
```

```shell-session
# mksquashfs /tmp/rootfs/ /tmp/image/live/filesystem.squashfs
```

```shell-session
# wget -O /tmp/debian.iso https://cdimage.debian.org/mirror/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso
```

```shell-session
# 7z x /tmp/debian.iso -o/tmp/debian-iso
```

```shell-session
# chmod -R +rX /tmp/debian-iso
```

```shell-session
# mv \
  /tmp/debian-iso/.disk \
  "/tmp/debian-iso/[BOOT]" \
  /tmp/debian-iso/dists \
  /tmp/debian-iso/pool \
  /tmp/debian-iso/tools \
/tmp/image/
```

```shell-session
# mkdir -p /tmp/image/EFI/boot/install
```

```shell-session
# mv \
  /tmp/debian-iso/install.amd/initrd.gz \
  /tmp/debian-iso/install.amd/vmlinuz \
/tmp/image/EFI/boot/install/
```

```shell-session
# cp \
  /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi \
/tmp/image/EFI/boot/bootx64.efi
```

```shell-session
# cp \
  /usr/lib/syslinux/modules/efi64/ldlinux.e64 \
  /usr/lib/syslinux/modules/efi64/libutil.c32 \
  /usr/lib/syslinux/modules/efi64/menu.c32 \
/tmp/image/EFI/boot/
```

```shell-session
# cat <<EOF > /tmp/image/EFI/boot/syslinux.cfg
UI menu.c32
prompt 0
timeout 50
menu title NtOS

label start
  menu default
  menu label ^Start
  kernel live/vmlinuz
  initrd live/initrd.img
  append boot=live components noroot noautologin hostname=NtFlash username=ntrrg timezone=America/Caracas quiet persistence persistence-encryption=luks

menu begin install
  menu label ^Install Debian Buster
  menu title Install Debian Buster

  label install
    menu label ^Install
    kernel install/vmlinuz
    initrd install/initrd.gz
    append vga=788 quiet

  label install-expert
    menu label ^Expert install
    kernel install/vmlinuz
    initrd install/initrd.gz
    append vga=788 priority=low

  label install-auto
    menu label ^Automated install
    kernel install/vmlinuz
    initrd install/initrd.gz
    append vga=788 priority=critical auto=true quiet

  label back
    menu label ^Go back
    menu exit
menu end
EOF
```

### BIOS support

```shell-session
# mkdir -p /tmp/image/syslinux
```

```shell-session
# cp \
  /usr/lib/syslinux/modules/bios/libutil.c32 \
  /usr/lib/syslinux/modules/bios/menu.c32 \
/tmp/image/syslinux/
```

```shell-session
# cat <<EOF > /tmp/image/syslinux/syslinux.cfg
UI menu.c32
prompt 0
timeout 50
menu title NtOS

label start
  menu default
  menu label ^Start
  kernel /EFI/boot/live/vmlinuz
  initrd /EFI/boot/live/initrd.img
  append boot=live components noroot noautologin hostname=NtFlash username=ntrrg timezone=America/Caracas quiet persistence persistence-encryption=luks

menu begin install
  menu label ^Install Debian Buster
  menu title Install Debian Buster

  label install
    menu label ^Install
    kernel /EFI/boot/install/vmlinuz
    initrd /EFI/boot/install/initrd.gz
    append vga=788 quiet

  label install-expert
    menu label ^Expert install
    kernel /EFI/boot/install/vmlinuz
    initrd /EFI/boot/install/initrd.gz
    append vga=788 priority=low

  label install-auto
    menu label ^Automated install
    kernel /EFI/boot/install/vmlinuz
    initrd /EFI/boot/install/initrd.gz
    append vga=788 priority=critical auto=true quiet

  label back
    menu label ^Go back
    menu exit
menu end
EOF
```

## USB Bootable

```shell-session
# apt install \
  btrfs-tools \
  cryptsetup \
  debootstrap \
  dosfstools \
  lvm2 \
  syslinux \
  syslinux-efi
```

```shell-session
$ mkdir ntos
$ cd ntos
$ lsblk
# dd if=/dev/zero of=<unidad> bs=1048576 count=1
# fdisk <unidad>
```

```text
p - Asegurarse de que es la unidad
o - Crear tabla de particiones DOS
n - Crear partición de almacenamiento compatible
  p - Usar partición primaria
  1 - Asignar número de partición
  \n - Especificar sector inicial
  +4G - Asignar 4GB
t - Cambiar el tipo de partición
  c - Seleccionar el tipo "W95 FAT32 (LBA)"
n - Crear partición de arranque
  p - Usar partición primaria
  2 - Asignar número de partición
  \n - Especificar sector inicial
  +2G - Asignar 2GB
t - Cambiar el tipo de partición
  2 - Seleccionar la segunda partición
  ef - Seleccionar el tipo "EFI (FAT-12/16/32)"
a - Activar marca de arranque
  2 - Seleccionar la segunda partición
n - Crear partición de persistencia
  p - Usar partición primaria
  3 - Asignar número de partición
  \n - Especificar sector inicial
  +15G - Asignar 15GB
n - Crear partición para datos
  p - Usar partición primaria
  4 - Asignar número de partición
  \n - Especificar sector inicial
  \n - Asignar el espacio restante
w - Guardar y salir
```

```shell-session
mkfs.fat -F 32 -n NTRRG /dev/sdX1

mkfs.fat -F 32 -n NTFLASH-OS /dev/sdX2
mount /dev/sdX2 /mnt/
cp -r /tmp/image/* /mnt/
umount /mnt/
syslinux -id syslinux /dev/sdX2
dd if=/usr/lib/SYSLINUX/mbr.bin of=/dev/sdX bs=440 count=1

cryptsetup --verify-passphrase luksFormat /dev/sdX3
cryptsetup luksOpen /dev/sdX3 Persistence
mkfs.ext4 -L persistence /dev/mapper/Persistence
mount /dev/mapper/Persistence /mnt/
echo "/etc union
/home union
/opt union
/root union
/usr union
/var union" > /mnt/persistence.conf
umount /mnt
cryptsetup luksClose /dev/mapper/Persistence

vgcreate NtFlash /dev/sdX4
lvcreate -L 80G -n Data NtFlash
mkfs.btrfs -L NtFlash /dev/NtFlash/Data
vgchange -a n NtFlash
```

```text
p - Asegurarse de que es la unidad
g - Crear tabla de particiones GPT
n - Crear partición ESP
    1 - Asignar número de partición
    \n - Especificar sector inicial
    +2G - Asignar 2GB
t - Cambiar el tipo de partición
    1 - Seleccionar el tipo "EFI System"
x - Entrar en modo experto
    A - Activar flag de boot para soporte a MBR
    r - Regresar al menú normal
n - Crear partición para LVM
    2 - Asignar número de partición
    \n - Especificar sector inicial
    \n - Asignar el espacio restante
t - Cambiar el tipo de partición
    2 - Seleccionar la segunda partición
    31 - Seleccionar el tipo "Linux LVM"
w - Guardar y salir
```

```shell-session
mkfs.fat -F 32 -n NTFLASH /dev/sdX1
mount /dev/sdX1 /mnt/
cp -r /tmp/image/* /mnt/
umount /mnt/
syslinux -id syslinux /dev/sdX1
dd if=/usr/lib/SYSLINUX/gptmbr.bin of=/dev/sdX bs=440 count=1

vgcreate NtDisk <segunda partición>
lvcreate --size <tamaño> --name NtOS NtDisk

cryptsetup --verify-passphrase luksFormat /dev/NtDisk/NtOS
cryptsetup luksOpen /dev/NtDisk/NtOS NtOS

mkfs.ext4 -L NtOS-Persistence /dev/mapper/NtOS
mount /dev/mapper/NtOS /mnt/
echo "/etc union
/home union
/opt union
/root union
/usr union
/var union" | tee /mnt/persistence.conf

umount /mnt
cryptsetup luksClose /dev/mapper/NtOS
vgchange -a n NtDisk
```

man live-boot
man live-config
man persistence.conf

http://cosmolinux.no-ip.org/raconetlinux2/persistence.html
http://docs.kali.org/downloading/kali-linux-live-usb-persistence
http://willhaley.com/blog/create-a-custom-debian-live-environment/
https://wiki.debian.org/ReduceDebian
https://debian-live.alioth.debian.org/live-manual/stable/manual/html/live-manual.en.html
http://willhaley.com/blog/install-debian-usb/
https://wiki.archlinux.org/index.php/syslinux
http://www.syslinux.org/wiki/index.php

https://phenobarbital.wordpress.com/2011/05/13/linux-debiancanaima-en-soneview-n110-mini-laptop-classmate/
https://phenobarbital.wordpress.com/2011/07/13/debian-se-puede-tener-un-gnome-minimo/
