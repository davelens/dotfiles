#!/usr/bin/env bash
set -e

# Enable lingering so user services start at boot (before login)
sudo loginctl enable-linger $USER

# Create uinput group if it doesn't exist
if ! getent group uinput >/dev/null; then
  sudo groupadd uinput
fi

# Ensure user is in input and uinput groups for device access
sudo usermod -aG input,uinput $USER

# Create udev rule for uinput device permissions
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' |
  sudo tee /etc/udev/rules.d/99-input.rules >/dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger

ln -sf $DOTFILES_REPO_HOME/config/arch/systemd/kanata.service \
  $XDG_CONFIG_HOME/systemd/user/

paru -S --needed --noconfirm kanata-bin
systemctl --user daemon-reload
systemctl --user enable kanata
systemctl --user restart kanata

# When you press capslock while Kanata is starting, you might end up with an
# active capslock and no conventional way to turn it off.
echo
echo "Kanata is booting; DO NOT PRESS CAPSLOCK"
sleep 2
printf "\033[2A\033[0J"
echo -e "Kanata is ready!\n"
