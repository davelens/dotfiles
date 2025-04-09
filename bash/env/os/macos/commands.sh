# toggles a boolean setting in the com.apple environment
toggle_default() {
  local environment="$1"
  local setting="$2"
  local value new

  value="$(defaults read "com.apple.$environment" "$setting")"
  [ "$value" -eq 0 ] && new="TRUE" || new="FALSE"

  defaults write "com.apple.$environment" "$setting" -bool $new
  killall Finder

  echo "$setting is now $new."
}

# Use quicklook in debug mode to quickly display file info.
quicklook() {
  qlmanage -p "$1" >&/dev/null
}
