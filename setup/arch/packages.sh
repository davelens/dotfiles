#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read_packages() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$' | awk '{print $1}'
}

aur_package_exists() {
  paru -Sia "$1" &>/dev/null
}

# Priority: -bin > regular > skip -git
resolve_aur_package() {
  local pkg="$1"

  # Already has suffix, use as-is
  [[ "$pkg" == *-bin || "$pkg" == *-git ]] && echo "$pkg" && return

  if aur_package_exists "${pkg}-bin"; then
    echo "${pkg}-bin"
  elif aur_package_exists "$pkg"; then
    echo "$pkg"
  else
    echo "Warning: Package '$pkg' not found in AUR, skipping" >&2
  fi
}

install_pacman_packages() {
  local file="$1"
  local packages
  mapfile -t packages < <(read_packages "$file")

  sudo pacman -Syu --noconfirm
  sudo pacman -S --noconfirm --needed "${packages[@]}"
}

install_aur_packages() {
  local packages resolved=()
  mapfile -t packages < <(read_packages "$SCRIPT_DIR/paru.packages")

  for pkg in "${packages[@]}"; do
    result=$(resolve_aur_package "$pkg")
    [[ -n "$result" ]] && resolved+=("$result")
  done

  [[ ${#resolved[@]} -gt 0 ]] && paru -S --noconfirm --skipreview --needed --provides=no "${resolved[@]}"
}

install_flatpak_packages() {
  local packages
  mapfile -t packages < <(read_packages "$SCRIPT_DIR/flatpak.packages")

  for pkg in "${packages[@]}"; do
    flatpak --user install -y --noninteractive flathub "$pkg"
  done
}

configure_gnupg() {
  gpg --list-keys >/dev/null 2>&1 # Creates the keyring on first run.
  mkdir -p "$HOME/.local/share/gnupg"
  chmod 700 "$HOME/.local/share/gnupg"
}

configure_packages() {
  # TODO:
  .
}

install_pacman_packages "$SCRIPT_DIR/pacman.packages"
install_aur_packages
install_flatpak_packages
configure_packages
