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
    rfkill,
    systemd-sysv,
    wpasupplicant
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
  append boot=live components quiet persistence persistence-encryption=luks

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
  append boot=live components quiet persistence persistence-encryption=luks

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

## Installation

**Note:** the approach in this section is intended for minimal usage (even 1GB
memories may be used), but users could use any approach that fits their needs).

```shell-session
# apt install cryptsetup dosfstools fdisk syslinux
```

```shell-session
# fdisk /dev/sdX
```

---

### DOS

```text
p - Asegurarse de que es la unidad
o - Crear tabla de particiones DOS
n - Crear partición de arranque
  p - Usar partición primaria
  1 - Asignar número de partición
  \n - Especificar sector inicial
  +512M - Asignar 512MB
t - Cambiar el tipo de partición
  ef - Seleccionar el tipo "EFI (FAT-12/16/32)"
a - Activar marca de arranque para BIOS
n - Crear partición de persistencia
  p - Usar partición primaria
  2 - Asignar número de partición
  \n - Especificar sector inicial
  \n - Asignar el espacio restante
w - Guardar y salir
```

```shell-session
# dd if=/usr/lib/SYSLINUX/mbr.bin of=/dev/sdX bs=440 count=1
```

### GPT

```text
p - Asegurarse de que es la unidad
g - Crear tabla de particiones GPT
n - Crear partición de arranque
    1 - Asignar número de partición
    \n - Especificar sector inicial
    +512M - Asignar 512MB
t - Cambiar el tipo de partición
    1 - Seleccionar el tipo "EFI System"
x - Entrar en modo experto
    A - Activar marca de arranque para BIOS
    r - Regresar al menú normal
n - Crear partición de persistencia
    2 - Asignar número de partición
    \n - Especificar sector inicial
    \n - Asignar el espacio restante
w - Guardar y salir
```

```shell-session
# dd if=/usr/lib/SYSLINUX/gptmbr.bin of=/dev/sdX bs=440 count=1
```

---

```shell-session
# mkfs.fat -F 32 -n NTOS /dev/sdX1
```

```shell-session
# mount /dev/sdX1 /mnt/
```

```shell-session
# cp -r /tmp/image/* /mnt/
```

```shell-session
# umount /mnt/
```

```shell-session
# syslinux -id syslinux /dev/sdX1
```

```shell-session
# cryptsetup --verify-passphrase luksFormat /dev/sdX2
```

```shell-session
# cryptsetup luksOpen /dev/sdX2 Persistence
```

```shell-session
# mkfs.ext4 -L persistence /dev/mapper/Persistence
```

```shell-session
# mount /dev/mapper/Persistence /mnt/
```

```shell-session
# echo "/ union" > /mnt/persistence.conf 
```

```shell-session
# umount /mnt
```

```shell-session
# cryptsetup luksClose /dev/mapper/Persistence
```

## Acknowledgment

Working on this project I use/used:

* [Debian](https://www.debian.org/)

* [XFCE](https://xfce.org/)

* [st](https://st.suckless.org/)

* [Zsh](http://www.zsh.org/)

* [GNU Screen](https://www.gnu.org/software/screen)

* [Git](https://git-scm.com/)

* [EditorConfig](http://editorconfig.org/)

* [Vim](https://www.vim.org/)

* [GNU make](https://www.gnu.org/software/make/)

* [Chrome](https://www.google.com/chrome/browser/desktop/index.html)

* [Gogs](https://gogs.io/)

* [Github](https://github.com)

```shell-session
$ man live-boot
```

```shell-session
$ man live-config
```

```shell-session
$ man persistence.conf
```

<http://cosmolinux.no-ip.org/raconetlinux2/persistence.html>

<http://docs.kali.org/downloading/kali-linux-live-usb-persistence>

<http://willhaley.com/blog/create-a-custom-debian-live-environment/>

<https://wiki.debian.org/ReduceDebian>

<https://debian-live.alioth.debian.org/live-manual/stable/manual/html/live-manual.en.html>

<http://willhaley.com/blog/install-debian-usb/>

<https://wiki.archlinux.org/index.php/syslinux>

<http://www.syslinux.org/wiki/index.php>

<https://phenobarbital.wordpress.com/2011/05/13/linux-debiancanaima-en-soneview-n110-mini-laptop-classmate/>

<https://phenobarbital.wordpress.com/2011/07/13/debian-se-puede-tener-un-gnome-minimo/>
