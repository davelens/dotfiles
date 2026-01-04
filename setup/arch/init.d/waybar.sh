#!/usr/bin/env bash

sudo pacman -S --needed --noconfirm waybar

# Set up systemd service
ln -sf "$DOTFILES_REPO_HOME/config/arch/systemd/waybar.service" \
  "$XDG_CONFIG_HOME/systemd/user/"

# Install MechaBar - a mecha-themed, modular Waybar configuration
# https://github.com/Sejjy/MechaBar
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"

if [[ -d "$WAYBAR_CONFIG_DIR" ]]; then
  mv "$WAYBAR_CONFIG_DIR" "$WAYBAR_CONFIG_DIR.bak"
fi

# Using fix/v0.14.0 branch to work around wildcard includes issue
# https://github.com/Alexays/Waybar/issues/4354
git clone -b fix/v0.14.0 https://github.com/sejjy/mechabar.git "$WAYBAR_CONFIG_DIR"

# Run MechaBar's install script (makes scripts executable, installs dependencies)
"$WAYBAR_CONFIG_DIR/install.sh"

# Enable and start the service
systemctl --user daemon-reload
systemctl --user enable --now waybar
