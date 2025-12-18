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

resolve_aur_package() {
  local pkg="$1"

  # If package already has a suffix, use as-is
  if [[ "$pkg" == *-bin || "$pkg" == *-git ]]; then
    echo "$pkg"
    return
  fi

  # Priority: -bin > regular > skip -git
  if paru -Si "${pkg}-bin" &>/dev/null; then
    echo "${pkg}-bin"
  elif paru -Si "$pkg" &>/dev/null; then
    echo "$pkg"
  else
    echo "Warning: Package '$pkg' not found in AUR, skipping" >&2
  fi
}

install_aur_packages() {
  local input_packages resolved_packages=()
  read -ra input_packages <<< "$(read_packages "$SCRIPT_DIR/paru.packages")"

  for pkg in "${input_packages[@]}"; do
    resolved=$(resolve_aur_package "$pkg")
    [[ -n "$resolved" ]] && resolved_packages+=("$resolved")
  done

  if [[ ${#resolved_packages[@]} -gt 0 ]]; then
    paru -S --noconfirm --skipreview --needed "${resolved_packages[@]}"
  fi
}

install_pacman_packages
install_paru
install_aur_packages
