#!/usr/bin/env bash
set -e

echo "==> Configuring GNOME settings..."

# Dark mode for GTK apps
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "GNOME settings configured."
