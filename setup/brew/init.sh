#!/usr/bin/env bash
set -e

usage() {
  echo "Usage: utility brew $(basename "$0") [options]"
  echo
  echo "Installs Homebrew and optionally processes Brewfile bundles."
  echo
  echo "Options:"
  echo "  -h, --help          Show this help message and exit."
  echo "  --skip-bundles      Only install Homebrew, skip bundle installation."
}

skip_bundles=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    usage
    exit 0
    ;;
  --skip-bundles)
    skip_bundles=true
    shift
    ;;
  *)
    shift
    ;;
  esac
done

if command_exists brew; then
  echo "Homebrew is already installed."
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ "$skip_bundles" == true ]]; then
  exit 0
fi

# shellcheck disable=SC2154
answer=$($prompt_user --yesno "Install brew bundles?")
if [[ "$answer" == "y" ]]; then
  brew bundle --file="$DOTFILES_REPO_HOME"/setup/brew/Brewfile.default

  if [[ "$(os)" == "macos" ]]; then
    brew bundle --file="$DOTFILES_REPO_HOME"/setup/macos/Brewfile
  fi
fi
