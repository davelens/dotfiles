#!/usr/bin/env bash
set -e

echo "==> Configuring GNOME settings..."

# Dark mode for GTK apps
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Disable default keybindings that conflict with custom workflows
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"
gsettings set org.gnome.desktop.wm.keybindings close "[]"

# Custom keybindings
CUSTOM_KEYBINDINGS_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['${CUSTOM_KEYBINDINGS_PATH}/custom0/']"

# Albert launcher: Super+Space
dconf write "${CUSTOM_KEYBINDINGS_PATH}/custom0/name" "'Open Albert'"
dconf write "${CUSTOM_KEYBINDINGS_PATH}/custom0/command" "'albert toggle'"
dconf write "${CUSTOM_KEYBINDINGS_PATH}/custom0/binding" "'<Super>space'"

echo "GNOME settings configured."
