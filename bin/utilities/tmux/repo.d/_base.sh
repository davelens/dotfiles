#!/usr/bin/env bash
# shellcheck disable=SC2154
#
# Base interface for framework-specific tmux session setup.
#
# Each framework module must implement:
#   FRAMEWORK_PRIORITY  - Integer for detection order (lower = higher priority)
#   detect()            - Returns 0 if project matches this framework
#   db_adapter()        - Returns the database adapter name (or empty)
#   bootstrap()         - Sets up a freshly cloned project
#   repl_command()      - Command to start the REPL (or empty)
#   server_command()    - Command to start the server (or empty)
#   db_creds_command()  - Command to get database name (or empty)

###############################################################################
# Shared window setup
###############################################################################

# Creates the base editor window
setup_editor_window() {
  local session="$1"
  local path="$2"

  tmux new-session -s "$session" -n editor -c "$path" -d
  tmux send-keys -t "$session:editor" "clear && $EDITOR" C-m
}

# Creates a CLI window for general shell use
setup_cli_window() {
  local session="$1"
  local path="$2"

  tmux new-window -n cli -c "$path" -t "$session"
  tmux send-keys -t "$session:cli" "clear" C-m
}

# Creates database client window based on adapter
setup_db_window() {
  local session="$1"
  local path="$2"
  local adapter="$3"
  local db_creds_cmd="$4"

  tmux new-window -n db -c "$path" -t "$session"

  # Give window time to initialize
  sleep 0.3

  local database="\$($db_creds_cmd)"
  case "$adapter" in
  mysql | mysql2)
    tmux send-keys -t "$session:db" "clear && mycli $database -h localhost" C-m
    ;;
  postgresql | postgres)
    tmux send-keys -t "$session:db" "clear && pgcli $database" C-m
    ;;
  *)
    tmux send-keys -t "$session:db" "clear" C-m
    ;;
  esac
}

# Creates REPL window with provided command
setup_repl_window() {
  local session="$1"
  local path="$2"
  local repl_cmd="$3"

  tmux new-window -n repl -c "$path" -t "$session"

  sleep 0.3

  if [[ -n "$repl_cmd" ]]; then
    tmux send-keys -t "$session:repl" "clear && $repl_cmd" C-m
  else
    tmux send-keys -t "$session:repl" "clear" C-m
  fi
}

# Creates server window with provided command
setup_server_window() {
  local session="$1"
  local path="$2"
  local server_cmd="$3"
  local start_server="$4"

  tmux new-window -n server -c "$path" -t "$session"

  sleep 0.3

  if [[ -n "$server_cmd" ]]; then
    if [[ "$start_server" =~ [Yy] ]]; then
      tmux send-keys -t "$session:server" "clear && $server_cmd" C-m
    else
      tmux send-keys -t "$session:server" "clear && $server_cmd"
    fi
  else
    tmux send-keys -t "$session:server" "clear" C-m
  fi
}

# Full 4-window setup: editor, db, repl, server
setup_standard_windows() {
  local session="$1"
  local path="$2"
  local start_server="$3"
  local adapter db_creds_cmd repl_cmd server_cmd

  adapter=$(db_adapter "$path")
  db_creds_cmd=$(db_creds_command)
  repl_cmd=$(repl_command)
  server_cmd=$(server_command)

  setup_editor_window "$session" "$path"
  setup_db_window "$session" "$path" "$adapter" "$db_creds_cmd"
  setup_repl_window "$session" "$path" "$repl_cmd"
  setup_server_window "$session" "$path" "$server_cmd" "$start_server"
}

# Minimal 2-window setup: editor, cli
setup_minimal_windows() {
  local session="$1"
  local path="$2"

  setup_editor_window "$session" "$path"
  setup_cli_window "$session" "$path"
}

###############################################################################
# Database helpers
###############################################################################

# Ensure the appropriate database server is running
ensure_db_running() {
  local adapter="$1"

  case "$adapter" in
  mysql | mysql2)
    if [[ -z $(pgrep -x mysqld) ]]; then
      local answer
      answer=$($prompt_user -yn "[$me] Start local MySQL server?")
      echo
      [[ "$answer" =~ [Yy] ]] && mysql.server start >/dev/null 2>&1
    fi
    ;;
  postgresql | postgres)
    if ! pg_isready -q 2>/dev/null; then
      local answer
      answer=$($prompt_user -yn "[$me] Start local PostgreSQL server?")
      echo
      [[ "$answer" =~ [Yy] ]] && utility postgresql start >/dev/null
    fi
    ;;
  esac
}
