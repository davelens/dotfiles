#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read_packages() {
  # Strips out any comments and blank lines, returns space-separated list
  grep -v '^\s*#' "$1" | grep -v '^\s*$' | awk '{print $1}' | tr '\n' ' '
}

install_pacman_packages() {
  local packages
  read -ra packages <<< "$(read_packages "$SCRIPT_DIR/pacman.packages")"

  sudo pacman -Syu
  sudo pacman -S --noconfirm --needed "${packages[@]}"
}

install_paru() {
  command -v paru &>/dev/null && return
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  (cd /tmp/paru && makepkg -si --noconfirm)
  rm -rf /tmp/paru
}

install_aur_packages() {
  local packages
  read -ra packages <<< "$(read_packages "$SCRIPT_DIR/paru.packages")"
  paru -S --needed "${packages[@]}"
}

install_pacman_packages
install_paru
install_aur_packages
