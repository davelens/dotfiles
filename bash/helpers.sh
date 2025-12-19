# This script is loaded once through BASH_ENV.
#
# Only declare functions once.
if declare -F "command_exists" >/dev/null; then
  return 0
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

block_unless_sourced() {
  if is_sourced; then
    echo "$(cross) This script is meant to be sourced, not executed directly." >&2
    return 1
  fi

  return 0
}

check() {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(green ✓)$(colorize "$1" "]")"
}

cross() {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(red x)$(colorize "$1" "]")"
}

colorize() {
  if [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
    echo "$(tput setaf "$1")$2$(tput sgr0)"
  else
    echo "$2"
  fi
}

ensure_brew_dependency() {
  for package in "$@"; do
    local name=${package%:*}    # Extract the package name before ":"
    local command=${package#*:} # Extract optional command name after ":"

    [[ -z $command || $command == "$package" ]] && command=$name

    if [[ ! $(command -v "$command") ]]; then
      $print_status -n "Installing $package ... "
      output=$(HOMEBREW_COLOR=1 brew install --quiet "$name" 2>&1 >/dev/null)

      if test $? -gt 0; then
        $print_status -n -i error "Failed to install package '$package': $output"
      else
        $print_status -i ok "Installed $package."
      fi
    fi
  done
}

# To help us centralize how errors look throughout our scripts.
error_handler() {
  echo "$(cross) An error occurred. Check the log file for details: $DOTFILES_STATE_HOME/dots.log"

  if ! is_sourced; then
    exit $?
  fi
}

# Exports all ENV vars listed in a file.
# Loads $DOTFILES_CONFIG_HOME/env by default.
source_env() {
  local env_file

  if [ -z "$1" ]; then
    [ -f "$PWD/.env" ] && env_file="$PWD/.env"
  fi

  [ ! -f "$env_file" ] && env_file="$DOTFILES_CONFIG_HOME/env"
  echo source "$env_file"
}

# Helps us hard stop our custom executables during fails.
fail() {
  printf "%s\n" "$1" >&2 # Sends a message to stderr.
  exit "${2-1}"          # Returns a code specified by $2 or 1 by default.
}

green() {
  colorize 2 "$1"
}

interrupt_handler() {
  $print_status -i error "Aborted."
  exit 1
}

is_sourced() {
  local script="${BASH_SOURCE[1]}"
  [[ "$script" != "" && "$script" != "$0" ]]
}

# Join an array by a given delimiter string
join_by() {
  local d f
  d="${1-}" f="${2-}"

  if shift 2; then
    printf "%s" "$f" "${@/#/$d}"
  fi
}

pending() {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(yellow \~)$(colorize "$1" "]")"
}

# Find the process ID of a given command. Note that you can use regex as well.
#
#   pid '/d$/'
#
# Would find pids of all processes with names ending in 'd'
pid() {
  lsof -t -c "$@"
}

red() {
  colorize 1 "$1"
}

# Examples:
#
#   repeat-do 4 echo lol
#
repeat() {
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

succeed() {
  echo "$1" # Sends a message to stderr.
  exit 0
}

# Because we all want to know how many times we actually typed "gti" instead
# of "git".
timesused() {
  [ -f "$HISTFILE" ] && grep -c "^$1" "$HISTFILE"
}

yellow() {
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
