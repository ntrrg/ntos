#!/bin/sh
# Copyright (c) 2018 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e

MODE="${MODE:-TEXT}"
WEEK="${WEEK:-43}"
MIRROR="${MIRROR:-https://github.com/ntrrg/ntos/releases/download/w$WEEK}"

apt-get update
apt-get upgrade -y

apt-get install -y \
  apt-transport-https \
  btrfs-progs \
  cryptsetup \
  dosfstools \
  elinks \
  git \
  htop \
  iftop \
  isc-dhcp-client \
  jq \
  lbzip2 \
  lvm2 \
  mosh \
  netselect \
  ntfs-3g \
  p7zip-full \
  p7zip-rar \
  pciutils \
  pv \
  rsync \
  screen \
  siege \
  ssh \
  sshfs \
  transmission-cli \
  usbutils \
  vbetool \
  wget \
  zsh

if lspci | grep -q "Network controller"; then
  apt-get install -y rfkill wireless-tools wpasupplicant
fi

wget -cO /tmp/ntos-packages-common.tar.gz \
  "$MIRROR/ntos-packages-common-w$WEEK-x64.tar.gz"

tar -xf /tmp/ntos-packages-common.tar.gz -C /tmp/

# ET

cp -f /tmp/ntos-packages-common/et.sh /usr/bin/et
chmod +x /usr/bin/et

# Busybox

cp -f /tmp/ntos-packages-common/busybox-1.28.1-x86_64 /bin/busybox
chmod +x /bin/busybox

# Docker

dpkg -i /tmp/ntos-packages-common/docker-ce_18.06.1_ce_3-0_debian_amd64.deb ||
  apt-get install -fy

# Docker Compose

cp -f /tmp/ntos-packages-common/docker-compose-1.22.0-Linux-x86_64 \
  /usr/bin/docker-compose

chmod +x /usr/bin/docker-compose

cp -f /tmp/ntos-packages-common/docker-compose-1.22.0-completion-bash \
  /etc/bash_completion.d/docker-compose

cp -f /tmp/ntos-packages-common/docker-compose-1.22.0-completion-zsh \
  /usr/share/zsh/vendor-completions/_docker-compose

# no-ip

tar -xf /tmp/ntos-packages-common/noip-duc-2.1.9-linux.tar.gz -C /tmp/
cp /tmp/noip-2.1.9-1/binaries/noip2-x86_64 /usr/local/bin/noip2
rm -rf /tmp/noip-2.1.9-1

cat <<EOF > /etc/init.d/noip2
#!/bin/sh
### BEGIN INIT INFO
# Provides: noip2
# Required-Start: \$local_fs \$remote_fs \$network \$syslog \$named
# Required-Stop: \$local_fs \$remote_fs \$network \$syslog \$named
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: NoIP dynamic client
### END INIT INFO

DAEMON=/usr/local/bin/noip2
NAME=noip2

test -x \$DAEMON || exit 0

case "\$1" in
start)
echo -n "Starting dynamic address update: "
start-stop-daemon --start --exec \$DAEMON
echo "noip2."
;;

stop)
echo -n "Shutting down dynamic address update:"
start-stop-daemon --stop --oknodo --retry 30 --exec \$DAEMON
echo "noip2."
;;

restart)
echo -n "Restarting dynamic address update: "
start-stop-daemon --stop --oknodo --retry 30 --exec \$DAEMON
start-stop-daemon --start --exec \$DAEMON
echo "noip2."
;;

*)
echo "Usage: \$0 {start|stop|restart}"
exit 1
esac
exit 0
EOF

chmod +x /etc/init.d/noip2

case "$MODE" in
  "TEXT" )
    wget -cO /tmp/ntos-packages-gui.tar.gz \
      "$MIRROR/ntos-packages-text-w$WEEK-x64.tar.gz"

    tar -xf /tmp/ntos-packages-text.tar.gz -C /tmp/

    # Vim

    apt-get install -y \
      gcc \
      libncurses-dev \
      make

    tar -xf /tmp/ntos-packages-common/vim-8.1.tar.bz2 -C /tmp/
    (cd /tmp/vim81 && ./configure && make && make install)
    rm -rf /tmp/vim81

    # MEGAcmd

    dpkg -i /tmp/ntos-packages-text/megacmd_1.0.0+4.1_amd64.deb ||
      apt-get install -fy || true
    ;;

  "GUI" )
    wget -cO /tmp/ntos-packages-gui.tar.gz \
      "$MIRROR/ntos-packages-gui-w$WEEK-x64.tar.gz"

    tar -xf /tmp/ntos-packages-gui.tar.gz -C /tmp/

    apt-get install -y \
      alsa-utils \
      conky \
      cups \
      evince \
      gimp \
      inkscape \
      simple-scan \
      system-config-printer \
      transmission \
      vlc \
      wicd \
      xfce4 \
      xfce4-goodies

    # ST

    apt-get install -y \
      gcc \
      libx11-dev \
      libxft-dev \
      libxext-dev \
      make

    tar -xf /tmp/ntos-packages-gui/st-0.8.1.tar.gz -C /tmp/
    (cd /tmp/st-0.8.1 && make clean install)
    rm -rf /tmp/st-0.8.1

    cat <<EOF > /usr/share/applications/simple-terminal.desktop
[Desktop Entry]
Name=st
GenericName=Terminal
Comment=Simple terminal emulator for the X window system
Exec=st
Terminal=false
Type=Application
Encoding=UTF-8
Icon=terminal
Categories=System;TerminalEmulator;
Keywords=shell;prompt;command;commandline;cmd;
EOF

    # Vim

    apt-get install -y \
      gcc \
      libncurses-dev \
      libx11-dev \
      libxpm-dev \
      libxt-dev \
      libxtst-dev \
      make

    tar -xf /tmp/ntos-packages-common/vim-8.1.tar.bz2 -C /tmp/
    (cd /tmp/vim81 && ./configure --with-features=huge && make && make install)
    rm -rf /tmp/vim81

    cat <<EOF > /usr/share/applications/vim.desktop
[Desktop Entry]
Name=Vim
GenericName=Text Editor
Comment=Edit text files
Exec=st vim %F
Terminal=false
Type=Application
Encoding=UTF-8
MimeType=text/plain;
Icon=gvim
Categories=Utility;TextEditor;Development;
Keywords=Text;editor;
EOF

    # Telegram

    tar -xf /tmp/ntos-packages-gui/tsetup.1.4.3.tar.xz -C /opt/
    ln -sf /opt/Telegram/Telegram /usr/bin/telegram

    # MEGA

    dpkg -i /tmp/ntos-packages-gui/megasync_3.7.1+3.1_amd64.deb ||
      apt-get install -fy

    # Chrome

    dpkg -i /tmp/ntos-packages-gui/google-chrome-stable_70.0.3538.67-1_amd64.deb ||
      apt-get install -fy

    # Paper Theme

    dpkg -i /tmp/ntos-packages-gui/paper-icon-theme_1.5.721-201808151353~daily~ubuntu18.04.1_all.deb ||
      apt-get install -fy

    tar -xf /tmp/ntos-packages-gui/paper-gtk-theme.tar.gz -C /tmp/
    (cd /tmp/paper-gtk-theme-master && ./install-gtk-theme.sh)
    rm -rf /tmp/paper-gtk-theme-master
    ;;
esac

apt-get autoremove -y > /dev/null
# shellcheck disable=SC2046
(cd /var/cache/apt && rm -rf $(ls -A))
# shellcheck disable=SC2046
(cd /var/lib/apt/lists && rm -rf $(ls -A))
# shellcheck disable=SC2046
(cd /var/log && rm -rf $(ls -A))

rm -rf /tmp/ntos-packages-common /tmp/ntos-packages-gui
