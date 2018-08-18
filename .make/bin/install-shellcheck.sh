#!/bin/sh

PACKAGE="shellcheck-v$RELEASE.linux.x86_64.tar.xz"

cd /tmp || exit 1

wget -c "https://shellcheck.storage.googleapis.com/$PACKAGE"
tar -xJf "$PACKAGE"

cd "$OLDPWD" || exit 1

cp -f "/tmp/shellcheck-v$RELEASE/shellcheck" "$DEST"
chmod +x "$DEST"
