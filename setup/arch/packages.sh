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

install_paru() {
  command -v paru &>/dev/null && return
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  (cd /tmp/paru && makepkg -si --noconfirm)
  rm -rf /tmp/paru
}

install_pacman_packages() {
  local packages
  mapfile -t packages < <(read_packages "$SCRIPT_DIR/pacman.packages")

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

configure_gnupg() {
  gpg --list-keys >/dev/null 2>&1 # Creates the keyring on first run.
  mkdir -p "$HOME/.local/share/gnupg"
  chmod 700 "$HOME/.local/share/gnupg"
}

configure_packages() {
  configure_gnupg
}

install_pacman_packages
install_paru
install_aur_packages
configure_packages
