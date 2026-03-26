#!/usr/bin/env bash

# Rofi applet: fuzzy-find an ActiveCollab task and perform one of two actions.
# Two-step flow: pick a project, then pick a task.
# Enter opens the task URL; Ctrl+y copies the internal task ID.
# Reads task/project cache from $XDG_CACHE_HOME/ac-cli/ and AC_ACCOUNT_ID from
# env or ac-cli's env file at $XDG_CONFIG_HOME/ac-cli/env.

set -e

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="$XDG_CACHE_HOME/ac-cli"
ROFI="$HOME/.local/bin/rofi-start --dmenu --theme style-5-no-indent -i"
AC_ENV_FILE="$XDG_CONFIG_HOME/ac-cli/env"

get_ac_account_id() {
  if [[ -n "$AC_ACCOUNT_ID" ]]; then
    printf '%s\n' "$AC_ACCOUNT_ID"
    return 0
  fi

  if [[ ! -f "$AC_ENV_FILE" ]]; then
    return 1
  fi

  local line value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"

    [[ -z "$line" || "$line" == \#* ]] && continue
    line="${line#export }"

    if [[ "$line" == AC_ACCOUNT_ID=* ]]; then
      value="${line#AC_ACCOUNT_ID=}"
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"

      [[ -n "$value" ]] && printf '%s\n' "$value"
      return 0
    fi
  done <"$AC_ENV_FILE"

  return 1
}

# -- Step 1: Project selection -----------------------------------------------

projects_json="$CACHE_DIR/projects.json"

if [[ ! -f "$projects_json" ]]; then
  notify-send -a "ActiveCollab" -u critical "No project cache found at $projects_json"
  exit 1
fi

# Build a name→id lookup and a display list sorted alphabetically
project_map=$(jq -r '.[] | "\(.name)\t\(.id)"' "$projects_json" | sort -t$'\t' -k1,1f)
project_names=$(echo "$project_map" | cut -f1)

selected_project=$(echo "$project_names" | $ROFI -p "Project") || exit 0

# Resolve name back to ID
project_id=$(echo "$project_map" | awk -F'\t' -v name="$selected_project" '$1 == name { print $2; exit }')

if [[ -z "$project_id" ]]; then
  notify-send -a "ActiveCollab" -u critical "Could not resolve project: $selected_project"
  exit 1
fi

# -- Step 2: Task selection --------------------------------------------------

tasks_json="$CACHE_DIR/projects/${project_id}/tasks.json"

if [[ ! -f "$tasks_json" ]]; then
  tasks_json="$CACHE_DIR/projects/${project_id}.json"
fi

if [[ ! -f "$tasks_json" ]]; then
  notify-send -a "ActiveCollab" -u critical "No task cache for project $selected_project ($tasks_json)"
  exit 1
fi

# Filter active tasks only, format as "id<TAB>#task_number  name"
task_lines=$(jq -r '
  if (.tasks? | type) == "array" then
    .tasks
  elif type == "array" then
    .
  else
    []
  end
  | .[]
  | select(.is_completed == false)
  | "\(.id)\t#\(.task_number)  \(.name)"
' "$tasks_json")

if [[ -z "$task_lines" ]]; then
  notify-send -a "ActiveCollab" "No active tasks in $selected_project"
  exit 0
fi

# Show only the display part (after the tab) in rofi
task_display=$(echo "$task_lines" | cut -f2)

set +e
selected_task=$(echo "$task_display" | $ROFI -p "Task" -window-title "ActiveCollab Tasks" -mesg "Enter: open task   Ctrl+y: copy task ID" -kb-custom-1 "Control+y")
rofi_status=$?
set -e

case "$rofi_status" in
0 | 10) ;;
1)
  exit 0
  ;;
*)
  notify-send -a "ActiveCollab" -u critical "Task selection failed (rofi exit: $rofi_status)"
  exit 1
  ;;
esac

# Extract the id from the matching line
task_id=$(echo "$task_lines" | awk -F'\t' -v disp="$selected_task" '$2 == disp { print $1; exit }')

if [[ -z "$task_id" ]]; then
  notify-send -a "ActiveCollab" -u critical "Could not resolve task selection"
  exit 1
fi

# -- Step 3: Action -----------------------------------------------------------

if [[ "$rofi_status" -eq 10 ]]; then
  echo -n "$task_id" | wl-copy
  notify-send -a "ActiveCollab" "Copied task ID $task_id"
  exit 0
fi

if ! account_id="$(get_ac_account_id)"; then
  account_id=""
fi

if [[ -z "$account_id" ]]; then
  notify-send -a "ActiveCollab" -u critical "Missing AC_ACCOUNT_ID (env or $AC_ENV_FILE)"
  exit 1
fi

if ! command -v xdg-open >/dev/null 2>&1; then
  notify-send -a "ActiveCollab" -u critical "xdg-open is not available"
  exit 1
fi

task_url="https://next-app.activecollab.com/${account_id}/projects/${project_id}/tasks/${task_id}"
if ! xdg-open "$task_url" >/dev/null 2>&1; then
  notify-send -a "ActiveCollab" -u critical "Failed to open task URL"
  exit 1
fi
