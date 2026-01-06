#!/usr/bin/env bash
# shellcheck disable=SC2154
# Phoenix framework module for tmux/repo
#
# Variables FRAMEWORK_NAME and FRAMEWORK_PRIORITY are used by the parent script.
# shellcheck disable=SC2034

FRAMEWORK_NAME="Phoenix"
FRAMEWORK_PRIORITY=20

detect() {
  local path="$1"
  [[ -f "$path/mix.exs" ]] && grep -q "{:phoenix" "$path/mix.exs" 2>/dev/null
}

db_adapter() {
  local path="$1"
  local mix_file="$path/mix.exs"

  [[ -f "$mix_file" ]] || return 0

  if grep -q "postgrex" "$mix_file" 2>/dev/null; then
    echo "postgresql"
  elif grep -q "myxql\|mariaex" "$mix_file" 2>/dev/null; then
    echo "mysql"
  fi
}

db_connection_url() {
  echo "utility phoenix db-connection-url"
}

repl_command() {
  echo "iex -S mix"
}

server_command() {
  echo "mix phx.server"
}

bootstrap() {
  local path="$1"

  $print_status -i pending "Bootstrapping Phoenix project..."

  pushd "$path" >/dev/null || return 1
  mix local.hex --force >/dev/null 2>&1
  mix deps.get >/dev/null 2>&1
  mix deps.compile >/dev/null 2>&1

  # Install npm dependencies if assets/package.json exists
  if [[ -f "assets/package.json" ]]; then
    $print_status -i pending "Installing npm dependencies..."
    npm install --prefix assets >/dev/null 2>&1
  fi

  # Set up database if ecto is present
  if grep -q "{:ecto" mix.exs 2>/dev/null; then
    mix ecto.setup 2>/dev/null || mix ecto.create 2>/dev/null || true
  fi

  popd >/dev/null || return 1
  $print_status -i ok "Phoenix project bootstrapped"
}

server_prompt() {
  echo "Start Phoenix server?"
}
