#!/usr/bin/env bash
# shellcheck disable=SC2154
# Elixir (non-Phoenix) framework module for tmux/repo
#
# Variables FRAMEWORK_NAME and FRAMEWORK_PRIORITY are used by the parent script.
# shellcheck disable=SC2034

FRAMEWORK_NAME="Elixir"
FRAMEWORK_PRIORITY=30

detect() {
  local path="$1"
  [[ -f "$path/mix.exs" ]]
}

db_adapter() {
  echo ""
}

db_creds_command() {
  echo ""
}

repl_command() {
  echo "iex -S mix"
}

server_command() {
  echo ""
}

bootstrap() {
  local path="$1"

  $print_status -i pending "Bootstrapping Elixir project..."

  pushd "$path" >/dev/null || return 1
  mix local.hex --force >/dev/null 2>&1
  mix deps.get >/dev/null 2>&1
  popd >/dev/null || return 1

  $print_status -i ok "Elixir project bootstrapped"
}

server_prompt() {
  echo ""
}
