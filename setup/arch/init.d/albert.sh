#!/usr/bin/env bash
set -e

ln -sf $DOTFILES_REPO_HOME/config/arch/systemd/albert.service \
  $XDG_CONFIG_HOME/systemd/user/

paru -S --needed --noconfirm albert-bin
systemctl --user daemon-reload
systemctl --user restart albert

echo -e "Albert is ready!\n"
