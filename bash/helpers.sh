#!/usr/bin/env bash

[[ -n "$_HELPERS_INCLUDED" ]] && return
export _HELPERS_INCLUDED=1

function is_sourced() {
  local script="${BASH_SOURCE[1]}"
  [[ "$script" != "$0" ]]
}

function is_executed() {
  ! is_sourced
}

function block_unless_sourced() {
  if is_sourced; then
    echo "$(cross) This script is meant to be sourced, not executed directly." >&2
    return 1
  fi

  return 0
}

# Lowercase any string
function lowercase () {
  if [ -n "$1" ]; then
    echo "$1" | tr "[:upper:]" "[:lower:]"
  else
    cat - | tr "[:upper:]" "[:lower:]"
  fi
}

# Exports all ENV vars listed in a file. Loads ~/.env by default.
function export_env_vars_from_file() {
  local env_file=${1:-~/.env}
  # shellcheck source=/dev/null
  [[ -f $env_file ]] && source "$env_file"
}

# Find the process ID of a given command. Note that you can use regex as well.
# 
#   pid '/d$/' 
#
# Would find pids of all processes with names ending in 'd'
function pid() { 
  lsof -t -c "$@"
}

# Join an array by a given delimiter string
function join_by {
  local d f 
  d="${1-}" f="${2-}"

  if shift 2; then
    printf "%s" "$f" "${@/#/$d}"
  fi
}

# Examples:
#
#   repeat-do 4 echo lol 
#   repeat-do lowercase "FOO" "BAR" "BAZ"
#
function repeat() {
  local times commands arguments

  case $1 in
    ''|*[0-9]*) 
      times=${1:-1}
      shift
      commands="$@"
      ;;
    *) 
      commands="$1"
      shift
      times=$#
      arguments=("$@")
      ;;
  esac

  if [[ -n $arguments ]]; then
    for i in "${arguments[@]}"; do $commands "$i"; done
  else
    for i in $(seq $times); do $commands; done
  fi
}

# Because we all want to know how many times we actually typed "gti" instead 
# of "git".
function timesused() {
  [[ -f "$HOME/.bash_history" ]] && grep -c "^${1}" "$HOME/.bash_history"
}

# To help us centralize how errors look throughout our scripts.
function error_handler() {
  echo "$(cross) An error occurred. Check the log file for details: $DOTFILES_STATE_PATH/dots.log"

  if is_executed; then
    exit $?
  fi
}

function interrupt_handler() {
  utility bash print-status -i error "Aborted."
  exit 1
}

function check() {
  echo "[$(green ✓)]"
}

function cross() {
  echo "[$(red x)]"
}

function pending() {
  echo "[$(yellow \~)]"
}

function red() {
  colorize 1 "$1"
}

function green() {
  colorize 2 "$1"
}

function yellow() {
  colorize 3 "$1"
}

function colorize() {
  echo "$(tput setaf "$1")$2$(tput sgr0)"
}

# Helps us hard stop our custom executables during fails.
function fail() {
  printf '%s\n' "$1" >&2 # Sends a message to stderr.
  exit "${2-1}" # Returns a code specified by $2 or 1 by default.
}

function succeed() {
  echo "$1" # Sends a message to stderr.
  exit 0
}

function ensure_brew_dependency() {
  for package in "$@"; do
    local name=${package%:*}   # Extract the package name before ":"
    local command=${package#*:} # Extract optional command name after ":"

    [[ -z $command || $command == $package ]] && command=$name

    if [[ ! `command -v $command` ]]; then
      utility bash print-status -n "Installing $package ... "
      output=$(HOMEBREW_COLOR=1 brew install --quiet $name 2>&1 >/dev/null)

      if [[ $? -gt 0 ]]; then
        utility bash print-status -n -i error "Failed to install package '$package': $output"
      else
        utility bash print-status -i ok "Installed $package."
      fi
    fi
  done
}

# Ensure all helper methods so they are available in subshells.
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
export -f repeat
export -f succeed
export -f timesused
export -f yellow
# Source utilities that come with their own helper functions
source bin/utilities/bash/box
