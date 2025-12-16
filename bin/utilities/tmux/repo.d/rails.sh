#!/usr/bin/env bash
# shellcheck disable=SC2154
# Rails framework module for tmux/repo
#
# Variables FRAMEWORK_NAME and FRAMEWORK_PRIORITY are used by the parent script.
# shellcheck disable=SC2034

FRAMEWORK_NAME="Rails"
FRAMEWORK_PRIORITY=10

detect() {
  local path="$1"
  [[ -f "$path/config.ru" ]]
}

db_adapter() {
  local path="$1"
  utility rails db-credentials --app="$path" --key=adapter 2>/dev/null || echo ""
}

db_creds_command() {
  echo "utility rails db-credentials --key=database"
}

repl_command() {
  echo "bin/rails c"
}

server_command() {
  echo "bin/rails s"
}

bootstrap() {
  local path="$1"

  $print_status -i pending "Bootstrapping Rails project..."

  if [[ -x "$(command -v utility)" ]]; then
    utility rails bootstrap "$path" && return 0
  fi

  # Fallback: basic setup
  pushd "$path" >/dev/null || return 1
  [[ -f "Gemfile" ]] && bundle install --quiet
  popd >/dev/null || return 1
}

server_prompt() {
  echo "Start Rails server?"
}
