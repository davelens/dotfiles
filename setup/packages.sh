#!/usr/bin/env bash
set -e

brew bundle --file="$DOTFILES_REPO_HOME"/setup/Brewfile.default

if [ "$(os)" == 'macos' ]; then
  brew bundle --file="$DOTFILES_REPO_HOME"/setup/macos/Brewfile
fi
