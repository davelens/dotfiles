#!/usr/bin/env bash
# Default fallback module for tmux/repo
# Used when no specific framework is detected.
#
# Variables FRAMEWORK_NAME and FRAMEWORK_PRIORITY are used by the parent script.
# shellcheck disable=SC2034

FRAMEWORK_NAME="Default"
FRAMEWORK_PRIORITY=999

detect() {
  # Always matches as fallback
  return 0
}

db_adapter() {
  echo ""
}

db_connection_url() {
  echo ""
}

repl_command() {
  echo ""
}

server_command() {
  echo ""
}

bootstrap() {
  # Nothing to bootstrap for generic projects
  return 0
}

server_prompt() {
  echo ""
}

# Override: use minimal windows (editor + cli) instead of standard 4-window setup
use_minimal_windows() {
  return 0
}
