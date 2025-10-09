#!/usr/bin/env bash
# shellcheck disable=SC2120,SC2317 # Unreachable commands are fiiine
set -e

cleanup() {
  for helper in $(helpers); do
    file="$DOTFILES_STATE_HOME/tmp/${helper##*/}"
    [ -f "$file" ] && rm -rf "$file"
  done

  rm -f "$DOTFILES_STATE_HOME/tmp/dotfiles.zip"
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

save_cursor() {
  IFS=';' read -r CURSOR_POS <<<"$(get_cursor_pos)"
  if [ "$CURSOR_POS" == "$(tput lines);1" ]; then
    CURSOR_POS="1;1"
  fi
  export CURSOR_POS
}

restore_cursor() { printf "\033[%sH" "$CURSOR_POS"; }
clear_down() { printf "\033[0J"; }
reset_prompt() { restore_cursor && clear_down; }
wind_down() { cleanup && reset_prompt; }
fail() {
  echo -e "\n$1" >&2
  exit "${2-1}"
}
interrupt_handler() { wind_down && fail "Aborted."; }
green() { echo "$BGG$FGK$1$CNONE"; }
blue() { echo "$BGB$FGK$1$CNONE"; }

helpers() {
  local prefix helpers=()
  prefix="https://raw.githubusercontent.com/davelens/dotfiles/refs/heads/master"
  helpers+=("$prefix/bash/env/xdg.sh")
  helpers+=("$prefix/bash/colors.sh")
  echo "${helpers[@]}"
}

prepare() {
  echo
  echo "Hi! My name's Dave. Looks like you're about to install my dotfiles."
  echo
  echo "The remote install script needs a couple of files from my repo to proceed."
  echo "If you're like me though, you'd want to review them first. They're quite safe:"
  echo

  for helper in $(helpers); do
    echo "  - $helper"
  done

  echo
  echo "Feel free to review the files first."
  echo
  echo "Press N to abort the script."
  prompt="Press Y to proceed. "

  read -n1 -r -p "$prompt" input
  case $input in
  [Yy]) ;;
  [Nn]) interrupt_handler ;;
  *)
    reset_prompt
    prepare && return
    ;;
  esac

  local temp_dir
  temp_dir="$HOME"/.local/state/dots/tmp
  [ ! -d "$temp_dir" ] && mkdir -p "$temp_dir"

  for helper in $(helpers); do
    filename="${helper##*/}"
    local_file="$temp_dir/$filename"
    curl -so "$local_file" "$helper"

    # shellcheck disable=SC2076
    if [[ ! $filename =~ ".sh" ]]; then
      declare "$filename=$local_file"
      chmod +x "$local_file"
    fi

    source "$local_file"
  done

  unset temp_dir
}

ask_for_repo_home() {
  local repo_home
  repo_home="$HOME/Repositories/davelens/dotfiles"

  echo
  echo "By default I keep my dotfiles in $(blue "${repo_home/$HOME/\~}")."

  if [ -n "$(ls -A "$repo_home")" ]; then
    echo "It looks like that directory's not empty though. 🤔"
  fi

  echo
  echo -e "Specify where you want to store the dotfiles: \n"

  if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    read -r -e -p "$HOME/" DOTFILES_REPO_HOME
    DOTFILES_REPO_HOME="${repo_home/\~/$HOME}"
  else
    read -r -e -i "$repo_home" -p "" DOTFILES_REPO_HOME
  fi

  if [ -n "$(ls -A "$DOTFILES_REPO_HOME/")" ]; then
    reset_prompt
    # ask_for_repo_home
    return
  fi

  DOTFILES_REPO_HOME="${DOTFILES_REPO_HOME:-$repo_home}"
  DOTFILES_REPO_HOME="${DOTFILES_REPO_HOME%/}"

  if [ -f "$DOTFILES_REPO_HOME" ]; then
    echo "The path you provided is a file. Please provide a directory."
    ask_for_repo_home && return
  fi

  [ ! -d "$DOTFILES_REPO_HOME" ] && mkdir -p "$DOTFILES_REPO_HOME"
  echo
}

repo_home() {
  echo "~${DOTFILES_REPO_HOME/$HOME/}"
}

download_dotfiles() {
  if [ -d "$DOTFILES_REPO_HOME/.git" ]; then

    check_repo=$(git config --get remote.origin.url 2>/dev/null |
      sed -E 's#(git@|https://)github.com[:/](.+)(\.git)?#\2#')

    if [ "$check_repo" == "davelens/dotfiles" ]; then
      echo "Looks like you already have my dotfiles there!"

      if command -v git >/dev/null; then
        echo -e "I'll just update them for you, and move on.\n"
        git -C "$DOTFILES_REPO_HOME" pull
        printf ""
      fi

      return
    fi

  else

    local dotfiles_zip extraction_dir
    dotfiles_zip="$DOTFILES_STATE_HOME/tmp/dotfiles.zip"
    extraction_dir="$(dirname "$dotfiles_zip")"

    echo "Alright, I'll download the dotfiles into $(blue "$(repo_home)")."
    echo

    if command -v git >/dev/null; then
      git clone git@github.com:davelens/dotfiles.git "$DOTFILES_REPO_HOME"
    else
      # TODO: Replace with extracting a tarball when we're starting with releases.
      curl -L -o "$dotfiles_zip" https://github.com/davelens/dotfiles/archive/refs/heads/master.zip
      unzip -o "$dotfiles_zip" -d "$extraction_dir"
      shopt -s dotglob
      mv "$extraction_dir"/dotfiles-master/* "$DOTFILES_REPO_HOME/"
      shopt -u dotglob
    fi

  fi
}

install_dotfiles() {
  # TODO: Change the `dots` command to git init DOTFILES_REPO_HOME, if necessary.

  prompt="Do you want to proceed with installing the dotfiles? "
  read -n1 -r -p "$prompt" input

  case $input in
  [Yy])
    echo
    "$DOTFILES_REPO_HOME/setup/install"
    ;;
  [Nn]) interrupt_handler ;;
  *)
    reset_prompt
    install_dotfiles && return
    ;;
  esac
  return
}

main() {
  local prompt input
  local CURSOR_POS
  CURSOR_POS="1;1"

  save_cursor
  prepare
  reset_prompt
  green "✓ Prerequisites met"
  save_cursor

  ask_for_repo_home
  reset_prompt
  green "✓ Primed $(repo_home)"
  save_cursor

  download_dotfiles
  reset_prompt
  green "✓ Dotfiles downloaded into $(repo_home)"
  save_cursor

  install_dotfiles

  cleanup && exit
  wind_down
}

###############################################################################
trap 'interrupt_handler' SIGINT

[ -z "${BASH_VERSION:-}" ] && fail "Bash is required to run this script."

if ! command -v curl >/dev/null; then
  fail "curl is required to download the dotfiles."
fi

main "$@"
