#!/usr/bin/env bash
set -e

# This is supposed to run after the remote install, which already installs brew.
# It installs packages from Brewfiles, then sets up mise and cargo packages.

install_brewfiles() {
  local brewfile_default="$DOTFILES_REPO_HOME/setup/brew/Brewfile.default"
  local brewfile_macos="$DOTFILES_REPO_HOME/setup/macos/Brewfile"

  echo "==> Installing packages from Brewfile.default..."
  brew bundle --file="$brewfile_default"

  echo "==> Installing packages from macos/Brewfile..."
  brew bundle --file="$brewfile_macos"

  echo "==> Brewfile installation complete."
}

main() {
  if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew is not installed. Run the remote installer first."
    exit 1
  fi

  if [ -z "$DOTFILES_REPO_HOME" ]; then
    echo "Error: DOTFILES_REPO_HOME is not set. Source your shell configuration first."
    exit 1
  fi

  install_brewfiles
  "$DOTFILES_REPO_HOME/setup/mise/init.sh"
  "$DOTFILES_REPO_HOME/setup/cargo/init.sh"

  echo
  echo "==> macOS supplemental installation complete!"
}

main "$@"
