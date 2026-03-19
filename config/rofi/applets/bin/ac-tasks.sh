#!/usr/bin/env bash

# Rofi applet: fuzzy-find an ActiveCollab task and copy its ID to clipboard.
# Two-step flow: pick a project, then pick a task.
# Reads from the ac-cli JSON cache at $XDG_CACHE_HOME/ac-cli/.

set -e

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_DIR="$XDG_CACHE_HOME/ac-cli"
ROFI="$HOME/.local/bin/rofi-start --dmenu --theme style-5-no-indent -i"

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

tasks_json="$CACHE_DIR/projects/${project_id}.json"

if [[ ! -f "$tasks_json" ]]; then
  notify-send -a "ActiveCollab" -u critical "No task cache for project $selected_project ($tasks_json)"
  exit 1
fi

# Filter active tasks only, format as "id<TAB>#task_number  name"
task_lines=$(jq -r '
  .tasks.tasks[]
  | select(.is_completed == false)
  | "\(.id)\t#\(.task_number)  \(.name)"
' "$tasks_json")

if [[ -z "$task_lines" ]]; then
  notify-send -a "ActiveCollab" "No active tasks in $selected_project"
  exit 0
fi

# Show only the display part (after the tab) in rofi
task_display=$(echo "$task_lines" | cut -f2)

selected_task=$(echo "$task_display" | $ROFI -p "Task") || exit 0

# Extract the id from the matching line
task_id=$(echo "$task_lines" | awk -F'\t' -v disp="$selected_task" '$2 == disp { print $1; exit }')

if [[ -z "$task_id" ]]; then
  notify-send -a "ActiveCollab" -u critical "Could not resolve task selection"
  exit 1
fi

# -- Step 3: Copy to clipboard ----------------------------------------------

echo -n "$task_id" | wl-copy
notify-send -a "ActiveCollab" "Copied task ID $task_id"
