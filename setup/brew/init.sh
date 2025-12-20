#!/usr/bin/env bash
set -e

if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle --file="$DOTFILES_REPO_HOME"/setup/Brewfile.default

if [ "$(os)" == 'macos' ]; then
  brew bundle --file="$DOTFILES_REPO_HOME"/setup/macos/Brewfile
fi
