#!/usr/bin/env bash

# Rofi applet: take a screenshot (area/window/desktop/delayed) or start a
# screen recording. Screenshots land in $PICTURES/screenshots and on the
# clipboard.

# Sway's exec environment has neither $XDG_BIN_HOME nor $DOTFILES_REPO_HOME,
# so resolve both from this script's real location.
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
DOTFILES_REPO_HOME="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../.." && pwd)"
export DOTFILES_REPO_HOME

rofi_cmd() {
  "$XDG_BIN_HOME/rofi-start" --dmenu --theme applet \
    -theme-str 'listview {lines: 5;}' \
    -p "Screenshot"
}

pipe_options_to_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | rofi_cmd
}

send_notification_and_open_preview() {
  notify-send -a "General" -i edit-copy "Screenshot" "Copied to clipboard"
  sushi "$dir"/"$file"
}

screenshot_to_clipboard() {
  tee "$file" | wl-copy -t image/png
}

countdown() {
  local title="${2:-Screenshot}"
  local notification_id=""
  for sec in $(seq "$1" -1 1); do
    if [[ -z "$notification_id" ]]; then
      notification_id=$(notify-send -p -t 1000 -a "General" -i image-x-generic "$title" "Recording in ${sec}s")
    else
      notify-send -r "$notification_id" -t 1000 -a "General" -i image-x-generic "$title" "Recording in ${sec}s"
    fi
    sleep 1
  done
  "$XDG_BIN_HOME/dshell" notifications dismiss "$notification_id"
}

record_screen_delay() {
  countdown "${1:-5}" "Screen Recording"
  "$DOTFILES_REPO_HOME/bin/utilities/misc/screencast" &
}

take_screenshot_full() {
  cd "$dir" && sleep 0.5 && grim - | screenshot_to_clipboard
  send_notification_and_open_preview
}

take_screenshot_delay() {
  countdown "${1:-5}"
  sleep 1 && cd "$dir" && grim - | screenshot_to_clipboard
  send_notification_and_open_preview
}

take_screenshot_window() {
  cd "$dir" && grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | screenshot_to_clipboard
  send_notification_and_open_preview
}

take_screenshot_area() {
  "$DOTFILES_REPO_HOME/bin/utilities/misc/screenshot" &
}

main() {
  geometry=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.current_mode.width)x\(.current_mode.height)"')
  dir="$(xdg-user-dir PICTURES)/screenshots"
  file="$(date +%Y-%m-%d-%H-%M-%S)_${geometry}.png"

  option_1="󰹑 Screenshot Area"
  option_2="󰘔 Screenshot Window"
  option_3="󰍹 Screenshot Desktop"
  option_4="󰚭 Screenshot in 5s"
  option_5="󰕧 Record screen in 5s"

  [ ! -d "$dir" ] && mkdir -p "$dir"

  case $(pipe_options_to_rofi) in
  "$option_1") take_screenshot_area ;;
  "$option_2") take_screenshot_window ;;
  "$option_3") take_screenshot_full ;;
  "$option_4") take_screenshot_delay 5 ;;
  "$option_5") record_screen_delay 5 ;;
  esac
}

main "$@"
