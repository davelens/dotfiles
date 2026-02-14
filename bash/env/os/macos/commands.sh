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

# I prefer GNU coreutils over the BSD ones on macos, so I'm trying this out
# to keep my scripts consistent between macos/arch.
cp() { gcp "$@"; }
ls() { gls "$@"; }
sed() { gsed "$@"; }
export -f cp ls sed
