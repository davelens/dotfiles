# This script is loaded once through BASH_ENV.
# Function checks are there to ensure they only get declared once.

if declare -F "fn_exists" > /dev/null; then
  return 0
fi

function fn_exists { 
  declare -F "$1" > /dev/null
}

function block_unless_sourced {
  if is_sourced; then
    echo "$(cross) This script is meant to be sourced, not executed directly." >&2
    return 1
  fi

  return 0
}

function check {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(green ✓)$(colorize "$1" "]")"
}

function cross {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(red x)$(colorize "$1" "]")"
}

function colorize {
  echo "$(tput setaf "$1")$2$(tput sgr0)"
}

function ensure_brew_dependency {
  for package in "$@"; do
    local name=${package%:*}   # Extract the package name before ":"
    local command=${package#*:} # Extract optional command name after ":"

    [[ -z $command || $command == "$package" ]] && command=$name

    if [[ ! $(command -v "$command") ]]; then
      print_status -n "Installing $package ... "
      output=$(HOMEBREW_COLOR=1 brew install --quiet "$name" 2>&1 >/dev/null)

      if [[ $? -gt 0 ]]; then
        print_status -n -i error "Failed to install package '$package': $output"
      else
        print_status -i ok "Installed $package."
      fi
    fi
  done
}

# To help us centralize how errors look throughout our scripts.
function error_handler {
  echo "$(cross) An error occurred. Check the log file for details: $DOTFILES_STATE_PATH/dots.log"

  if ! is_sourced; then
    exit $?
  fi
}

# Exports all ENV vars listed in a file.
# Loads ${DOTFILES_CONFIG_PATH}/env by default.
function export_env_vars_from_file {
  local env_file=${1:-"${DOTFILES_CONFIG_PATH}/env"}
  [ -f $env_file ] && source "$env_file"
}

# Helps us hard stop our custom executables during fails.
function fail {
  printf '%s\n' "$1" >&2 # Sends a message to stderr.
  exit "${2-1}" # Returns a code specified by $2 or 1 by default.
}

function green {
  colorize 2 "$1"
}

function interrupt_handler {
  print_status -i error "Aborted."
  exit 1
}

function is_sourced {
  local script="${BASH_SOURCE[1]}"
  [[ "$script" != "" && "$script" != "$0" ]]
}

# Join an array by a given delimiter string
function join_by() {
  local d f 
  d="${1-}" f="${2-}"

  if shift 2; then
    printf "%s" "$f" "${@/#/$d}"
  fi
}

function pending {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(yellow \~)$(colorize "$1" "]")"
}

# Find the process ID of a given command. Note that you can use regex as well.
# 
#   pid '/d$/' 
#
# Would find pids of all processes with names ending in 'd'
function pid { 
  lsof -t -c "$@"
}

function red {
  colorize 1 "$1"
}

# Examples:
#
#   repeat-do 4 echo lol 
#
function repeat {
  local times commands arguments

  case $1 in
    *[0-9]*) 
      times=${1:-1}
      shift
      commands="$*"
      ;;
    *) 
      commands="$1"
      shift
      times=$#
      arguments=("$@")
      ;;
  esac

  if [ -n "${arguments[*]}" ]; then
    for i in "${arguments[@]}"; do $commands "$i"; done
  else
    for i in $(seq "${times:-1}"); do $commands; done
  fi
}

function succeed {
  echo "$1" # Sends a message to stderr.
  exit 0
}

# Because we all want to know how many times we actually typed "gti" instead 
# of "git".
function timesused {
  [ -f "$HISTFILE" ] && grep -c "^${1}" "$HISTFILE"
}

function yellow {
  colorize 3 "$1"
}

# This is an easy way to expose my bash scripting utilities without having to
# prefix the full utility command.
export cursor="utility bash cursor"
export prompt_user="utility bash prompt_user"
export print_status="utility bash print_status"
export encrypt="utility bash encrypt"
export decrypt="utility bash decrypt"
export salt="utility bash salt"
