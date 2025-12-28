#!/usr/bin/env bash
set -e

install_paru() {
  command -v paru &>/dev/null && return
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  (cd /tmp/paru && makepkg -si --noconfirm)
  rm -rf /tmp/paru
}

install_flatpak() {
  command -v flatpak &>/dev/null && return
  sudo pacman -S --needed --noconfirm flatpak
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

###############################################################################

main() {
  sudo pacman -Syu
  install_paru
  install_flatpak
}

main "$@"
