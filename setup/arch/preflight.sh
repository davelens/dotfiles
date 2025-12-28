#!/usr/bin/env bash
set -e

install_paru() {
  command -v paru &>/dev/null && return
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  (cd /tmp/paru && makepkg -si --noconfirm)
  rm -rf /tmp/paru
}

###############################################################################

main() {
  install_paru
}

main "$@"
