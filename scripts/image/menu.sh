#!/bin/sh
# Copyright (c) 2018 Miguel Angel Rivera Notararigo
# Released under the MIT License

# shellcheck disable=SC2039

# Customizable variables:
#
# * NO_DEBIAN_INSTALLER

syslinux_config() {
  cat <<EOF
UI menu.c32
prompt 0
timeout 50
menu title NtOS

label start
  menu default
  menu label ^Start
  kernel ${PREFIX}live/vmlinuz
  initrd ${PREFIX}live/initrd.img
  append boot=live components noroot noautologin hostname=$HOSTNAME username=$USERNAME timezone=$TIMEZONE quiet persistence persistence-encryption=luks
EOF

  if [ -z "$NO_DEBIAN_INSTALLER" ]; then
    cat <<EOF

menu begin install
  menu label ^Install Debian Buster
  menu title Install Debian Buster

  label install
    menu label ^Install
    kernel ${PREFIX}install/vmlinuz
    initrd ${PREFIX}install/initrd.gz
    append vga=788 quiet

  label install-expert
    menu label ^Expert install
    kernel ${PREFIX}install/vmlinuz
    initrd ${PREFIX}install/initrd.gz
    append vga=788 priority=low

  label install-auto
    menu label ^Automated install
    kernel ${PREFIX}install/vmlinuz
    initrd ${PREFIX}install/initrd.gz
    append vga=788 priority=critical auto=true quiet

  label back
    menu label ^Go back
    menu exit
menu end
EOF
  fi
}

PREFIX="" syslinux_config > "$IMAGE/EFI/boot/syslinux.cfg"
PREFIX="/EFI/boot/" syslinux_config > "$IMAGE/syslinux/syslinux.cfg"
