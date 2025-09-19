#!/usr/bin/env bash
# shellcheck disable=SC2120 # Unreachable commands are fiiine
set -e

export REPO_URI="davelens/dotfiles"

fail() {
  printf %s "$CNONE"
  cleanup
  echo -e "\n$1" >&2
  exit "${2-1}"
}

macos_needs_newer_bash() {
  if [ "$(uname)" = "Darwin" ]; then
    [ -n "$BASH_VERSION" ] && [ "${BASH_VERSINFO[0]}" -lt 4 ] && return 1
  fi

  return 0
}

get_cursor_pos() {
  # Save current terminal settings
  local old_stty
  old_stty=$(stty -g)

  # Set terminal to raw mode, disable echo
  stty raw -echo

  # Request cursor position report
  printf "\033[6n" >/dev/tty

  # Read the response: it should look like ESC [ row ; col R
  local response
  IFS='R' read -d R -r response

  # Restore terminal settings
  stty "$old_stty"

  # Strip the escape sequence prefix and split row and col
  local row col
  response=${response#*[}
  row=${response%;*}
  col=${response#*;}

  echo "$row;$col"
}

interrupt_handler() {
  cleanup
  reset_prompt
  fail "Aborted."
}

load_remote_file() {
  local filename="${1##*/}"
  local local_file="$INSTALLER_TMP_HOME/$filename"
  curl -so "$local_file" \
    https://raw.githubusercontent.com/davelens/dotfiles/refs/heads/master/"$1"
  source "$local_file"
}

restore_cursor() {
  printf "\033[%sH" "$CURSOR_POS"
}

save_cursor() {
  IFS=';' read -r CURSOR_POS <<<"$(get_cursor_pos)"
  if [ "$CURSOR_POS" == "$(tput lines);1" ]; then
    CURSOR_POS="1;1"
  fi
  export CURSOR_POS
}

###############################################################################

black() { echo "$BGK$FGW$1$CNONE"; }
blue() { echo "$BGB$FGK$1$CNONE"; }
cleanup() { rm -rf "$INSTALLER_TMP_HOME"; }
clear_down() { printf "\033[0J"; }
fgreen() { echo "$FGG$1$CNONE"; }
fred() { echo "$FGR$1$CNONE"; }
fyellow() { echo "$FGY$1$CNONE"; }
green() { echo "$BGG$FGK$1$CNONE"; }
repo_home() { echo "~${DOTFILES_REPO_HOME/$HOME/}"; }
reset_prompt() { restore_cursor && clear_down; }
underline() { echo "$CUN$1$CNONE"; }

###############################################################################

preface() {
  reset_prompt
  save_cursor

  echo
  echo "Hi! My name's Dave. Looks like you're about to install my dotfiles."
  echo
  echo "This script will do the following:"
  echo "1. Clone the dotfiles repository somewhere on your system. You choose where."
  echo "2. Symlink the necessary files to their required locations."
  echo "3. Ask you for some personal data, such as your GitHub username and e-mail address."
  echo "4. Use said data to configure some tooling, like $(black git) and $(black gh)."

  if macos_needs_newer_bash; then
    echo
    echo -n "! ${FGY}On macos it also installs $(black brew) "
    echo -e -n "${FGY}and the latest version of Bash.$CNONE\n"
  fi

  echo
  echo "You can stop the installation at any time by pressing $(black Ctrl+c),"
  echo "but depending on where you opt out you might need to run the uninstall script."
  echo
  echo "You can review what the remote install does on GitHub:"
  echo
  echo "  $(black https://github.com/davelens/dotfiles/tree/master/setup/remote)"
  echo

  read -n 1 -r -p "Do you want to continue? [y/n]: " yn
  case $yn in
  [Yy]*) return ;;
  [Nn]*) interrupt_handler ;;
  *) preface ;;
  esac
}

main() {
  preface

  INSTALLER_TMP_HOME="$HOME/.local/state/dots/tmp/remote_install"
  mkdir -p "$INSTALLER_TMP_HOME"

  REMOTE_FILES=()
  REMOTE_FILES+=("bash/env/xdg.sh")
  REMOTE_FILES+=("bash/colors.sh")
  cp setup/remote/preflight.sh "$INSTALLER_TMP_HOME"/
  cp setup/remote/ask_for_repo_namespace.sh "$INSTALLER_TMP_HOME"/
  cp setup/remote/download_dotfiles.sh "$INSTALLER_TMP_HOME"/
  cp setup/remote/install_dotfiles.sh "$INSTALLER_TMP_HOME"/
  cp setup/remote/configure_env.sh "$INSTALLER_TMP_HOME"/
  # REMOTE_FILES+=("setup/remote/ask_for_repo_namespace.sh")
  # REMOTE_FILES+=("setup/remote/download_dotfiles.sh")
  # REMOTE_FILES+=("setup/remote/install_dotfiles.sh")
  # REMOTE_FILES+=("setup/remote/configure_env.sh")

  for file in "${REMOTE_FILES[@]}"; do load_remote_file "$file"; done
  source "$INSTALLER_TMP_HOME"/preflight.sh
  source "$INSTALLER_TMP_HOME"/ask_for_repo_namespace.sh
  source "$INSTALLER_TMP_HOME"/download_dotfiles.sh
  source "$INSTALLER_TMP_HOME"/install_dotfiles.sh
  source "$INSTALLER_TMP_HOME"/configure_env.sh
  cleanup
}

###############################################################################

trap 'interrupt_handler' SIGINT

[ -z "${BASH_VERSION:-}" ] && fail "Bash is required to run this script."

if ! command -v curl >/dev/null; then
  fail "curl is required to download the dotfiles."
fi

main "$@"
