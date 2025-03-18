#!/bin/bash
set -e

function fail {
  printf "%s\n" "$1" >&2
  exit "${2-1}"
}

[ -z "${BASH_VERSION:-}" ] && fail "Bash is required to interpret this script."

# Either curl or wget will work.
if ! command -v curl >/dev/null; then
  fail "curl is required to download the dotfiles."
fi

DOTFILES_FOLDER="dots"
DOTFILES_STATE_HOME="$XDG_STATE_HOME/$DOTFILES_FOLDER"
readonly DOTFILES_FOLDER DOTFILES_STATE_HOME

[ ! -d "$DOTFILES_STATE_HOME/tmp" ] && mkdir -p "$DOTFILES_STATE_HOME/tmp"

curl -L -o "$DOTFILES_STATE_HOME/tmp/dotfiles.zip" https://github.com/davelens/dotfiles/archive/refs/heads/master.zip
# TODO: Replace with extracting a tarball when we're starting with releases.
unzip -o "$DOTFILES_STATE_HOME/tmp/dotfiles.zip" -d "$DOTFILES_STATE_HOME/tmp"

rm -rf "$DOTFILES_STATE_HOME/tmp/dotfiles-master"
rm -f "$DOTFILES_STATE_HOME/tmp/dotfiles.zip"
