#!/usr/bin/env bash

#[[ -n "$_HELPERS_INCLUDED" ]] && return
#export _HELPERS_INCLUDED=1

function block_unless_sourced() {
  if is_sourced; then
    echo "$(cross) This script is meant to be sourced, not executed directly." >&2
    return 1
  fi

  return 0
}

function check() {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(green ✓)$(colorize "$1" "]")"
}

function cross() {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(red x)$(colorize "$1" "]")"
}

function colorize() {
  echo "$(tput setaf "$1")$2$(tput sgr0)"
}

function ensure_brew_dependency() {
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
function error_handler() {
  echo "$(cross) An error occurred. Check the log file for details: $DOTFILES_STATE_PATH/dots.log"

  if ! is_sourced; then
    exit $?
  fi
}

# Exports all ENV vars listed in a file. Loads ~/.env by default.
function export_env_vars_from_file() {
  local env_file=${1:-~/.env}
  # shellcheck source=/dev/null
  [[ -f $env_file ]] && source "$env_file"
}

# Helps us hard stop our custom executables during fails.
function fail() {
  printf '%s\n' "$1" >&2 # Sends a message to stderr.
  exit "${2-1}" # Returns a code specified by $2 or 1 by default.
}

function green() {
  colorize 2 "$1"
}

function interrupt_handler() {
  print_status -i error "Aborted."
  exit 1
}

function is_sourced() {
  local script="${BASH_SOURCE[1]}"
  [[ "$script" != "$0" ]]
}

# Join an array by a given delimiter string
function join_by() {
  local d f 
  d="${1-}" f="${2-}"

  if shift 2; then
    printf "%s" "$f" "${@/#/$d}"
  fi
}

# Lowercase any string
function lowercase() {
  if [ -n "$1" ]; then
    echo "$1" | tr "[:upper:]" "[:lower:]"
  else
    cat - | tr "[:upper:]" "[:lower:]"
  fi
}

function pending() {
  [ -z "$1" ] && set -- 255
  echo "$(colorize "$1" "[")$(yellow \~)$(colorize "$1" "]")"
}

# Find the process ID of a given command. Note that you can use regex as well.
# 
#   pid '/d$/' 
#
# Would find pids of all processes with names ending in 'd'
function pid() { 
  lsof -t -c "$@"
}

function red() {
  colorize 1 "$1"
}

# Examples:
#
#   repeat-do 4 echo lol 
#   repeat-do lowercase "FOO" "BAR" "BAZ"
#
function repeat() {
  local times commands arguments

  # Had to add () as a potential first argument. It was '' before, but that
  # threw function import errors when commands like `mix` ran using bin/sh
  # in subshells. Read the note at the bottom of this file for more info.
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

function succeed() {
  echo "$1" # Sends a message to stderr.
  exit 0
}

# Because we all want to know how many times we actually typed "gti" instead 
# of "git".
function timesused() {
  [[ -f "$HOME/.bash_history" ]] && grep -c "^${1}" "$HOME/.bash_history"
}

function yellow() {
  colorize 3 "$1"
}

###############################################################################
# 
#  DISCLAIMER: Exporting functions in your env is considered harmful. It's what 
#  led to the Shellshock/Bashdoor family of vulnerabilities in bash < 4.3.
#  If you want to find out if your bash is vulnerable, run the following:
# 
#    env x='() { :;}; echo vulnerable' bash -c "echo this is a test"
# 
#  You'll see the word "vulnerable" when you're at risk.
#
#  Running Bash 5+ at the time of writing should be OK. But keep in mind that 
#  exporting functions remains a security risk. Use with caution.
#
#  Sources:
#  https://en.wikipedia.org/wiki/Shellshock_(software_bug)
#  https://unix.stackexchange.com/questions/537516/why-is-sh-not-bash-complaining-about-functions-defined-in-my-bashrc
#
###############################################################################

# Expose all helper methods to subshells.
export -f block_unless_sourced
export -f check
export -f colorize
export -f cross
export -f ensure_brew_dependency
export -f error_handler
export -f export_env_vars_from_file
export -f fail
export -f green
export -f interrupt_handler
export -f is_sourced
export -f join_by
export -f lowercase
export -f pending
export -f pid
export -f red
export -f repeat
export -f succeed
export -f timesused
export -f yellow

# My source utilities come with their own helper functions. This exposes
# them to subshells (ie. other commands) without additional overhead.
source $DOTFILES_PATH/bin/utilities/bash/box
source $DOTFILES_PATH/bin/utilities/bash/cursor
source $DOTFILES_PATH/bin/utilities/bash/prompt-user
source $DOTFILES_PATH/bin/utilities/bash/print-status
source $DOTFILES_PATH/bin/utilities/bash/encrypt
source $DOTFILES_PATH/bin/utilities/bash/decrypt
source $DOTFILES_PATH/bin/utilities/bash/salt
