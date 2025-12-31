#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read_packages() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$' | awk '{print $1}'
}

echo "==> Installing GNOME packages..."
mapfile -t packages < <(read_packages "$SCRIPT_DIR/packages")
sudo pacman -S --noconfirm --needed "${packages[@]}"

echo "==> Configuring GNOME settings..."
"$SCRIPT_DIR/settings.sh"

echo "GNOME installation complete."
