#!/bin/sh
# Copyright (c) 2018 Miguel Angel Rivera Notararigo
# Released under the MIT License

scripts/rootfs/run.sh apt-get autoremove -y > /dev/null

scripts/rootfs/run.sh mv \
  /usr/share/i18n/locales/en_GB \
  /usr/share/i18n/locales/en_US \
  /usr/share/locale/locale.alias \
  /tmp/

scripts/rootfs/run.sh rm -rf \
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

scripts/rootfs/run.sh mv /tmp/en_GB /tmp/en_US /usr/share/i18n/locales/
scripts/rootfs/run.sh mv /tmp/locale.alias /usr/share/locale/

rm -f "$ROOTFS/root/.bash_history"
