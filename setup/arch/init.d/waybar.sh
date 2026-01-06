#!/usr/bin/env bash

sudo pacman -S --needed --noconfirm waybar

# TODO: Add Mechabar as git submodule instead? https://github.com/Sejjy/MechaBar

# Set up systemd service
ln -sf "$DOTFILES_REPO_HOME/config/arch/systemd/waybar.service" \
  "$XDG_CONFIG_HOME/systemd/user/"

# Run MechaBar's install script (makes scripts executable, installs dependencies)
"$XDG_CONFIG_HOME/waybar/install.sh"

# Enable and start the service
systemctl --user daemon-reload
systemctl --user enable --now waybar
