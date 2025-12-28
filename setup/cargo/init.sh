#!/usr/bin/env bash
set -e

read_packages() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$' | awk '{print $1}'
}

main() {
  if ! command -v cargo &>/dev/null; then
    echo "Error: cargo is not available. Rust may not be installed correctly."
    exit 1
  fi

  local packages
  mapfile -t packages < <(read_packages "$DOTFILES_REPO_HOME/setup/cargo/packages")

  echo "==> Installing cargo packages..."
  for pkg in "${packages[@]}"; do
    echo "    Installing $pkg..."
    cargo install --locked "$pkg"
  done
  echo "==> Cargo packages installed successfully."
}

main "$@"
