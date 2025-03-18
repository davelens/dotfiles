#!/usr/bin/env bash
# shellcheck disable=SC2317 # Unreachable commands are fiiine

set -e

function fail {
  printf "%s\n" "$1" >&2
  exit "${2-1}"
}

function cleanup {
  rm "$DOTFILES_STATE_HOME/tmp/colors.sh" >/dev/null
  rm -rf "$DOTFILES_STATE_HOME/tmp/dotfiles-master" >/dev/null
  rm -f "$DOTFILES_STATE_HOME/tmp/dotfiles.zip" >/dev/null
}

function interrupt_handler {
  cleanup
  fail "Aborted."
}

trap 'clear && interrupt_handler' SIGINT

[ -z "${BASH_VERSION:-}" ] && fail "Bash is required to run this script."

# Either curl or wget will work.
if ! command -v curl >/dev/null; then
  fail "curl is required to download the dotfiles."
fi

DOTFILES_FOLDER="dots"
DOTFILES_STATE_HOME="$XDG_STATE_HOME/$DOTFILES_FOLDER"
DOTFILES_CONFIG_HOME="$XDG_CONFIG_HOME/$DOTFILES_FOLDER"
readonly DOTFILES_FOLDER DOTFILES_STATE_HOME DOTFILES_CONFIG_HOME

[ ! -d "$DOTFILES_STATE_HOME/tmp" ] && mkdir -p "$DOTFILES_STATE_HOME/tmp"
[ ! -d "$DOTFILES_CONFIG_HOME" ] && mkdir -p "$DOTFILES_CONFIG_HOME"

colors="$DOTFILES_STATE_HOME/tmp/colors.sh"
curl -o "$colors" https://raw.githubusercontent.com/davelens/dotfiles/refs/heads/master/bash/colors.sh
source "$colors"

clear
echo "Hi! My name's Dave. Looks like you're about to install my dotfiles."
echo "By default I keep them in $BGB$FGK${DOTFILES_CONFIG_HOME/$HOME/\~}$CNONE, but you might not."
echo
prompt="Where would you like to install them from? "
read -r -p "$prompt" input

cleanup
fail "$input"

if [ -z "$input" ]; then
  fail "No input provided. Exiting."
fi

curl -L -o "$DOTFILES_CONFIG_HOME/" https://github.com/davelens/dotfiles/archive/refs/heads/master.zip
# TODO: Replace with extracting a tarball when we're starting with releases.
unzip -o "$DOTFILES_STATE_HOME/tmp/dotfiles.zip" -d "$DOTFILES_STATE_HOME/tmp"

"$DOTFILES_STATE_HOME/tmp/dotfiles-master/setup/install"

cleanup
