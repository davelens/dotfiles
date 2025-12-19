#!/usr/bin/env bash
set -e

# This is supposed to run after the remote install, which already installs brew.
# It installs packages from Brewfiles, then sets up mise, rust, and cargo packages.

install_brewfiles() {
  local brewfile_default="$DOTFILES_REPO_HOME/setup/Brewfile.default"
  local brewfile_macos="$DOTFILES_REPO_HOME/setup/macos/Brewfile"

  echo "==> Installing packages from Brewfile.default..."
  brew bundle --file="$brewfile_default"

  echo "==> Installing packages from macos/Brewfile..."
  brew bundle --file="$brewfile_macos"

  echo "==> Brewfile installation complete."
}

install_mise() {
  if ! command_exists mise; then
    fail "mise was not installed by Homebrew. Please check the Brewfile."
  fi

  echo "==> Activating mise..."
  eval "$(mise activate bash)"
}

install_rust() {
  echo "==> Installing Rust via mise..."
  mise use --global rust@latest

  # Source the cargo environment if it exists
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
  fi

  if ! command_exists rustc; then
    fail "Rust installation failed."
  fi

  echo "==> Rust installed successfully."
}

install_cargo_packages() {
  if ! command_exists cargo; then
    fail "cargo is not available. Rust may not be installed correctly."
  fi

  echo "==> Installing lolcat via cargo..."
  cargo install lolcat

  if ! command_exists lolcat; then
    echo "==> Note: lolcat installed. You may need to add ~/.cargo/bin to your PATH."
  else
    echo "==> lolcat installed successfully."
  fi
}

main() {
  if ! command_exists brew; then
    fail "Homebrew is not installed. Run the remote installer first."
  fi

  if [ -z "$DOTFILES_REPO_HOME" ]; then
    fail "DOTFILES_REPO_HOME is not set. Source your shell configuration first."
  fi

  install_brewfiles
  install_mise
  install_rust
  install_cargo_packages

  echo
  echo "==> macOS supplemental installation complete!"
}

main "$@"
