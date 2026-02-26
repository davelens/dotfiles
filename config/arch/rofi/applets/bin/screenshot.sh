#!/usr/bin/env bash

# shellcheck disable=SC1091
source "$HOME/.config/rofi/applets/shared/theme.bash"

rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu \
    -p "Screenshot" \
    -msg "$msg" \
    -markup-rows \
    -theme "$theme"
}

pipe_options_to_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
}

send_notification_and_open_preview() {
  notify_cmd_shot="notify-send"

  $notify_cmd_shot -i edit-copy "Screenshot" "Copied to clipboard"

  if [[ -e "$dir/$file" ]]; then
    $notify_cmd_shot -i document-save "Screenshot saved" "$file"
  else
    $notify_cmd_shot -i user-trash "Screenshot deleted"
  fi

  sushi "$dir"/"$file"
}

screenshot_to_clipboard() {
  tee "$file" | wl-copy -t image/png
}

countdown() {
  for sec in $(seq "$1" -1 1); do
    notify-send -t 1000 -i image-x-generic "Screenshot" "Taking in ${sec}s"
    sleep 1
  done
}

record_screen_delay() {
  countdown "${1:-5}"
  local real_script repo_root
  real_script="$(readlink -f "${BASH_SOURCE[0]}")"
  repo_root="$(cd "$(dirname "$real_script")/../../../../.." && pwd)"
  export DOTFILES_REPO_HOME="$repo_root"
  export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
  "$repo_root/bin/utilities/misc/screencast" &
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
  local real_script repo_root
  real_script="$(readlink -f "${BASH_SOURCE[0]}")"
  repo_root="$(cd "$(dirname "$real_script")/../../../../.." && pwd)"
  export DOTFILES_REPO_HOME="$repo_root"
  export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
  "$repo_root/bin/utilities/misc/screenshot" &
}

main() {
  # type/style are defined in the shared theme.bash file.
  # shellcheck disable=SC2154
  theme="$type/$style"
  msg="DIR: $(xdg-user-dir PICTURES)/Screenshots"
  layout=$(cat "$theme" | grep 'USE_ICON' | cut -d'=' -f2)
  geometry=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | "\(.current_mode.width)x\(.current_mode.height)"')
  dir="$(xdg-user-dir PICTURES)/screenshots"
  file="$(date +%Y-%m-%d-%H-%M-%S)_${geometry}.png"

  if [[ "$theme" == *'type-1'* ]]; then
    list_col='1'
    list_row='6'
    win_width='400px'
  elif [[ "$theme" == *'type-3'* ]]; then
    list_col='1'
    list_row='6'
    win_width='120px'
  elif [[ "$theme" == *'type-5'* ]]; then
    list_col='1'
    list_row='6'
    win_width='520px'
  elif [[ ("$theme" == *'type-2'*) || ("$theme" == *'type-4'*) ]]; then
    list_col='6'
    list_row='1'
    win_width='670px'
  fi

  if [ "$layout" == 'NO' ]; then
    option_1=" Capture Desktop"
    option_2=" Capture Area"
    option_3=" Capture Window"
    option_4=" Capture in 5s"
    option_5=" Capture in 10s"
    option_6="󰕧 Record screen in 5s"
  else
    option_1=""
    option_2=""
    option_3=""
    option_4=""
    option_5=""
    option_6="󰕧"
  fi

  [ ! -d "$dir" ] && mkdir -p "$dir"

  case $(pipe_options_to_rofi) in
  "$option_1") take_screenshot_full ;;
  "$option_2") take_screenshot_area ;;
  "$option_3") take_screenshot_window ;;
  "$option_4") take_screenshot_delay 5 ;;
  "$option_5") take_screenshot_delay 10 ;;
  "$option_6") record_screen_delay 5 ;;
  esac
}

main "$@"
