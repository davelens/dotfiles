#!/usr/bin/env bash
set -e

ln -sf $DOTFILES_REPO_HOME/config/arch/systemd/albert.service \
  $XDG_CONFIG_HOME/systemd/user/

# --mflags --skipinteg: Skip integrity check (upstream checksum sometimes outdated)
paru -S --needed --noconfirm --mflags --skipinteg albert-bin
systemctl --user daemon-reload
systemctl --user restart albert

echo -e "Albert is ready!\n"
