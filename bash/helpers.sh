#!/usr/bin/env bash

function block_unless_sourced() {
  if [[ "$1" == "${0}" ]]; then
    echo "$(cross) This script is meant to be sourced, not executed directly." >&2
    return 1
  fi

  return 0
}

# Exports all ENV vars listed in a file. Loads ~/.env by default.
function export-env-vars-from-file() {
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

# Because we all want to know how many times we actually typed "gti" instead 
# of "git".
function timesused() {
  [[ -f "$HOME/.bash_history" ]] && grep -c "^${1}" "$HOME/.bash_history"
}

# Function to display status updates on the same line.
function show_status() {
  local status="$1"
  local message="$2"
  local symbol=""

  case "$status" in
    pending)
      symbol="$(pending)"  # Symbol for pending
      ;;
    ok)
      symbol="$(check)"  # Symbol for success (check mark)
      ;;
    error)
      symbol="$(cross)"  # Symbol for failure (cross)
      ;;
    *)
      symbol="$(cross)"  # Default symbol for unknown status
      ;;
  esac

  clear_line # Clear the line before displaying the status.
  printf "$symbol $message"
}

# Function to clear output starting from the current line upwards
#
# TODO: 
# - [ ] Extract to executable file in bin/utilities. 
# - [ ] Add support for clearing multiple lines
# - [ ] Make '\033[J' optional
#
function clear_line() {
  # 1. Move cursor to the front of the line (\r)
  # 2. Clear everything from the cursor to the end of the line (\033[K)
  # 3. Move cursor back to the front of the line (\r)
  # 4. Clear everything from this line downwards to prevent ghosting (\033[J)
  printf "\r\033[K\r"
  printf '\033[J'
}

function clear_prompt_line() {
  printf "\033[1A" # Move up one line
  clear_line
}

# To help us centralize how errors look throughout our scripts.
function error_handler() {
  local exit_code=$?
  echo "$(cross) An error occurred. Check the log file for details: $DOTFILES_STATE_PATH/dots.log"
  exit $exit_code
}

function interrupt_handler() {
  show_status "canceled" "Aborted."
  echo
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
  package=$1
  command=$2
  [[ -z $2 ]] && command=$package

  if [[ ! `command -v $command` ]]; then
    show_status "pending" "Installing $package ..."
    brew install --quiet $package
    show_status "ok" "Installed $package."
    echo
  fi
}
