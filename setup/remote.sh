#!/bin/bash
# shellcheck disable=SC2317 # Unreachable commands are fiiine
set -e

function cleanup {
  for helper in $(helpers); do
    file="$DOTFILES_STATE_HOME/tmp/${helper##*/}"
    [ -f "$file" ] && rm -rf "$file"
  done

  rm -rf "$DOTFILES_STATE_HOME/tmp/dotfiles-master"
  rm -f "$DOTFILES_STATE_HOME/tmp/dotfiles.zip"
}

function save_cursor { printf "\033[s"; }
function restore_cursor { printf "\033[u"; }
function clear_down { printf "\033[0J"; }
function reset_prompt { restore_cursor && clear_down; }
function wind_down { cleanup && reset_prompt; }
function fail { echo -e "\n$1" >&2; exit "${2-1}"; }
function interrupt_handler { wind_down && fail "Aborted."; }
# function print_status { $print_status -hl "$BOX_HIGHLIGHT" "$@"; _box_border_right; }

function helpers {
  local prefix helpers=()
  prefix="https://raw.githubusercontent.com/davelens/dotfiles/refs/heads/master"
  helpers+=("$prefix/bash/colors.sh")
  helpers+=("$prefix/bin/utilities/bash/box")
  echo "${helpers[@]}"
}

function prepare {
  [ ! -d "$DOTFILES_STATE_HOME/tmp" ] && mkdir -p "$DOTFILES_STATE_HOME/tmp"
  [ ! -d "$DOTFILES_CONFIG_HOME" ] && mkdir -p "$DOTFILES_CONFIG_HOME"

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
  [Yy]) reset_prompt ;;
  [Nn]) interrupt_handler ;;
  *)
    reset_prompt
    prepare && return
    ;;
  esac

  for helper in $(helpers); do
    filename="${helper##*/}"
    local_file="$DOTFILES_STATE_HOME/tmp/$filename"
    curl -so "$local_file" "$helper"

    # shellcheck disable=SC2076
    if [[ ! $filename =~ ".sh" ]]; then 
      declare "$filename=$local_file"
      chmod +x "$local_file"
    else
      source "$local_file"
    fi
  done
}

function ask_for_repo_home {
  _box_top
  _box_print "By default I keep them in $BGB$FGK${DOTFILES_CONFIG_HOME/$HOME/\~}$CNONE."
  _box_print
  _box_print "If that's OK, you can press Enter."
  local input prompt
  prompt="If you want another location, please tell me where: "
  read -r -p "$prompt" input
  echo "$input"
}

function main {
  save_cursor

  local prompt input
  local DOTFILES_FOLDER DOTFILES_STATE_HOME DOTFILES_CONFIG_HOME
  DOTFILES_FOLDER="dots"
  DOTFILES_STATE_HOME="$XDG_STATE_HOME/$DOTFILES_FOLDER"
  DOTFILES_CONFIG_HOME="$XDG_CONFIG_HOME/$DOTFILES_FOLDER"

  prepare
  exit
  # interrupt_handler # TODO: Pick it up from here.
  #############################################################################

  DOTFILES_REPO_HOME=$(ask_for_repo_home)
  echo "$DOTFILES_REPO_HOME"

  curl -L -o "$DOTFILES_CONFIG_HOME/" https://github.com/davelens/dotfiles/archive/refs/heads/master.zip
  # TODO: Replace with extracting a tarball when we're starting with releases.
  unzip -o "$DOTFILES_STATE_HOME/tmp/dotfiles.zip" -d "$DOTFILES_STATE_HOME/tmp"
  # "$DOTFILES_STATE_HOME/tmp/dotfiles-master/setup/install"
  wind_down
}

###############################################################################
trap 'interrupt_handler' SIGINT

[ -z "${BASH_VERSION:-}" ] && fail "Bash is required to run this script."

if ! command -v curl >/dev/null; then
  fail "curl is required to download the dotfiles."
fi

main "$@"
