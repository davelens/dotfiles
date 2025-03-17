#!/bin/bash
set -e

function fail {
  printf "%s\n" "$1" >&2
  exit "${2-1}"
}

[ -z "${BASH_VERSION:-}" ] && fail "Bash is required to interpret this script."

# Either curl or wget will work.
if ! command -v curl >/dev/null && ! command -v wget >/dev/null; then
  fail "Either curl or wget is required to download the dotfiles."
fi

DOTFILES_REPO_HOME="$(dirname "$(dirname "$(realpath "$0")")")"
readonly DOTFILES_REPO_HOME
dotbot_path="$DOTFILES_REPO_HOME/dotbot"
readonly dotbot_path

# Trying to adhere to the XDG Base Directory Specification.
source "$DOTFILES_REPO_HOME/bash/env/xdg.sh"

# Get dotbot installed
git -C "$dotbot_path" submodule sync --quiet --recursive
git -C "$dotbot_path" submodule update --init --recursive

# Activate dotbot with the install configuration
"$dotbot_path/bin/dotbot" -d "$DOTFILES_REPO_HOME" -c "$DOTFILES_REPO_HOME/setup/install.conf.yaml" "$@"

if [ ! -f "$DOTFILES_CONFIG_HOME/env" ]; then
  "$DOTFILES_REPO_HOME/setup/env_wizard" || touch "$DOTFILES_CONFIG_HOME/env"
fi

# Create an executable that allows us to update our dotfiles, among other
# things.
dots_path="$XDG_BIN_HOME/dots"

if [ ! -f "$dots_path" ]; then
  ln -s "$DOTFILES_REPO_HOME/setup/dots" "$dots_path"
  chmod +x "$dots_path"
  $dots_path
  echo
  echo "$(check) dots command installed!"
  echo "Please source $BASHRC or restart your shell to apply changes."
  echo
fi
