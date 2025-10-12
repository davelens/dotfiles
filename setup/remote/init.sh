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

macos() {
  [ "$(uname)" == "Darwin" ] && return 0
  return 1
}

macos_needs_newer_bash() {
  macos &&
    [ -n "$BASH_VERSION" ] &&
    [ "${BASH_VERSINFO[0]}" -lt 4 ] &&
    return 0

  return 1
}

get_cursor_pos() {
  # When piped from curl, stdin is not a terminal, so we need to use /dev/tty
  if [ ! -t 0 ]; then
    # If stdin is not a terminal, we can't reliably get cursor position
    echo "1;1"
    return
  fi

  # Save current terminal settings
  local old_stty
  old_stty=$(stty -g)

  # Set terminal to raw mode, disable echo
  stty raw -echo

  # Request cursor position report
  printf "\033[6n" >/dev/tty

  # Read the response: it should look like ESC [ row ; col R
  local response
  IFS='R' read -d R -r response </dev/tty

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
  underline "INSTALLING https://github.com/$REPO_URI"
  echo
  echo "Steps:"
  echo "1. Clone the dotfiles repository somewhere on your system. You choose where."
  echo "2. Symlink the necessary files and folders to their relevant paths."
  echo -n "3. Configure $(black git) and $(black gh) "

  if macos; then
    echo -en "using data from my Bitwarden vault.\n"
  else
    echo -en "by asking for the required data.\n"
  fi

  if macos_needs_newer_bash; then
    echo
    echo -n "! ${FGY}This is a macos machine so it also installs $(black brew) "
    echo -e -n "${FGY}and the latest version of Bash.$CNONE\n"
  fi

  echo
  echo "You can stop the installation at any time by pressing $(black Ctrl+c)."
  echo "You might need to run the uninstall script if you do."
  echo
  echo "You can review what the remote install does on GitHub:"
  echo
  echo "  $(black https://github.com/davelens/dotfiles/tree/master/setup/remote)"
  echo

  read -n 1 -r -p "Do you want to continue? [y/n]: " yn </dev/tty
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
  REMOTE_FILES+=("setup/remote/preflight.sh")
  REMOTE_FILES+=("setup/remote/ask_for_repo_namespace.sh")
  REMOTE_FILES+=("setup/remote/download_dotfiles.sh")
  REMOTE_FILES+=("setup/remote/install_dotfiles.sh")
  REMOTE_FILES+=("setup/remote/configure_env.sh")

  for file in "${REMOTE_FILES[@]}"; do load_remote_file "$file"; done

  # cp setup/remote/preflight.sh "$INSTALLER_TMP_HOME"/
  # cp setup/remote/ask_for_repo_namespace.sh "$INSTALLER_TMP_HOME"/
  # cp setup/remote/download_dotfiles.sh "$INSTALLER_TMP_HOME"/
  # cp setup/remote/install_dotfiles.sh "$INSTALLER_TMP_HOME"/
  # cp setup/remote/configure_env.sh "$INSTALLER_TMP_HOME"/
  # source "$INSTALLER_TMP_HOME"/preflight.sh
  # source "$INSTALLER_TMP_HOME"/ask_for_repo_namespace.sh
  # source "$INSTALLER_TMP_HOME"/download_dotfiles.sh
  # source "$INSTALLER_TMP_HOME"/install_dotfiles.sh
  # source "$INSTALLER_TMP_HOME"/configure_env.sh

  cleanup
}

###############################################################################

trap 'interrupt_handler' SIGINT

[ -z "${BASH_VERSION:-}" ] && fail "Bash is required to run this script."

if ! command -v curl >/dev/null; then
  fail "curl is required to download the dotfiles."
fi

main "$@"
