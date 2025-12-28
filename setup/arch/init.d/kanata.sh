#!/usr/bin/env bash
set -e

ln -sf $DOTFILES_REPO_HOME/config/arch/systemd/kanata.service \
  $XDG_CONFIG_HOME/systemd/user/

paru -S --needed --noconfirm kanata-bin
systemctl --user daemon-reload
systemctl --user restart kanata

# When you press capslock while Kanata is starting, you might end up with an
# active capslock and no conventional way to turn it off.
echo
echo "Kanata is booting; DO NOT PRESS CAPSLOCK"
sleep 2
printf "\033[2A\033[0J"
echo -e "Kanata is ready!\n"
