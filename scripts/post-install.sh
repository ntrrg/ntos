#!/bin/sh
# Copyright (c) 2018 Miguel Angel Rivera Notararigo
# Released under the MIT License

set -e

MODE="${MODE:-TEXT}"

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
  lvm2 \
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
  usbutils \
  wget \
  zsh

if lspci | grep -q "Network controller"; then
  apt-get install -y rfkill wpasupplicant
fi

# ET

wget -cO /tmp/et \
  https://gist.githubusercontent.com/ntrrg/1dbd052b2d8238fa07ea5779baebbedb/raw/371724030a77113a621fbb7f43b5be506f2eb18d/et.sh

chmod +x /tmp/et
cp -f /tmp/et /usr/bin/

# Busybox

wget -cO /tmp/busybox \
  https://busybox.net/downloads/binaries/1.28.1-defconfig-multiarch/busybox-x86_64

chmod +x /tmp/busybox
cp -f /tmp/busybox /bin/

# Docker

wget -cO /tmp/docker-ce.deb \
  https://download.docker.com/linux/debian/dists/buster/pool/stable/amd64/docker-ce_18.03.1~ce-0~debian_amd64.deb

dpkg -i /tmp/docker-ce.deb || apt-get install -fy

# Docker Compose

wget -cO /tmp/docker-compose \
  https://github.com/docker/compose/releases/download/1.22.0/docker-compose-Linux-x86_64

chmod +x /tmp/docker-compose
cp -f /tmp/docker-compose /usr/bin/

wget -cO /tmp/docker-compose_completion-bash \
  https://raw.githubusercontent.com/docker/compose/1.22.0/contrib/completion/bash/docker-compose

cp -f /tmp/docker-compose_completion-bash \
  /etc/bash_completion.d/docker-compose

wget -cO /tmp/docker-compose_completion-zsh \
  https://raw.githubusercontent.com/docker/compose/1.22.0/contrib/completion/zsh/_docker-compose

cp -f /tmp/docker-compose_completion-zsh \
  /usr/share/zsh/vendor-completions/_docker-compose

case "$MODE" in
  "TEXT" )
    apt-get install -y vim
    ;;

  "GUI" )
    apt-get install -y \
      alsa-utils \
      conky \
      cups \
      evince \
      gimp \
      inkscape \
      simple-scan \
      system-config-printer \
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

    wget -cO /tmp/st.tar.gz \
      https://dl.suckless.org/st/st-0.8.1.tar.gz

    tar -xf /tmp/st.tar.gz -C /tmp/
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

    wget -cO /tmp/vim.tar.bz2 http://ftp.vim.org/pub/vim/unix/vim-8.1.tar.bz2
    tar -xf /tmp/vim.tar.bz2 -C /tmp/
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

    wget -cO /tmp/telegram.tar.xz \
      https://updates.tdesktop.com/tlinux/tsetup.1.3.10.tar.xz

    tar -xf /tmp/telegram.tar.xz -C /opt/

    # MEGA

    wget -cO /tmp/megasync.deb \
      https://mega.nz/linux/MEGAsync/Debian_9.0/amd64/megasync-Debian_9.0_amd64.deb

    dpkg -i /tmp/megasync.deb || apt-get install -fy

    # no-ip

    wget -cO /tmp/noip.tar.gz \
      https://www.noip.com/client/linux/noip-duc-linux.tar.gz

    tar -xf /tmp/noip.tar.gz -C /tmp/
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

    # Paper Icon Theme

    wget -cO /tmp/paper-icon-theme.deb \
      'https://snwh.org/paper/download.php?owner=snwh&ppa=ppa&pkg=paper-icon-theme,18.04'

    dpkg -i /tmp/paper-icon-theme.deb || apt-get install -fy
    ;;
esac

apt-get autoremove -y > /dev/null
# shellcheck disable=SC2046
(cd /var/cache/apt && rm -rf $(ls -A))
# shellcheck disable=SC2046
(cd /var/lib/apt/lists && rm -rf $(ls -A))
# shellcheck disable=SC2046
(cd /var/log && rm -rf $(ls -A))
