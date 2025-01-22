#!/usr/bin/env bash

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

# Function to display status updates
show_status() {
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
      symbol="[?]"  # Default symbol for unknown status
      ;;
  esac

  printf "\r\033[K\r%s %s" "$symbol" "$message"
}

# To help us centralize how errors look throughout our scripts.
error_handler() {
  local exit_code=$?
  echo "$(error) An error occurred. Check the log file for details: $LOG_FILE"
  exit $exit_code
}

interrupt_handler() {
  echo "$(error) Aborted."
  exit 1
}

check() {
  echo "[$(green ✓)]"
}

cross() {
  echo "[$(red x)]"
}

pending() {
  echo "[$(yellow \~)]"
}

red() {
  colorize 1 "$1"
}

green() {
  colorize 2 "$1"
}

yellow() {
  colorize 3 "$1"
}

colorize() {
  echo "$(tput setaf "$1")$2$(tput sgr0)"
}

# Helps us hard stop our custom executables during fails.
fail() {
  printf '%s\n' "$1" >&2 # Sends a message to stderr.
  exit "${2-1}" # Returns a code specified by $2 or 1 by default.
}

succeed() {
  echo "$1" # Sends a message to stderr.
  exit 0
}

