# This file will only load on macos.
# As this grows I might need to split it up into multiple files.

alias allow='xattr -d com.apple.quarantine'
alias rm='$(which trash) &>/dev/null && trash' # Puts rm'ed files in the OS trash
alias ss="osascript \"\$DOTFILES_PATH/config/macos/hide-terminal.scpt\" && utility misc screenshot && killall Terminal"
alias toggle_desktop='toggle_default finder CreateDesktop'
alias toggle_hidden_files='toggle_default finder AppleShowAllFiles'

# Flush the Directory Service cache on macos. Useful for forcing
# hostname/user/groups changes to update.
alias clearcache='sudo dscacheutil -flushcache'

# Disable/Enable ipv6 on the Wi-Fi interface.
# This is useful for when you're on a network that doesn't support ipv6, but
# I also haven't used this in AGES now. Consider removing these.
alias ipv6off='networksetup -setv6off Wi-Fi'
alias ipv6on='networksetup -setv6automatic Wi-Fi'

# Download the iTerm2 shell integration file and place it in the completions dir.
if [ ! -f "$DOTFILES_PATH/bash/env/autocompletions/iterm2_shell_integration.bash" ]; then
  curl -L https://iterm2.com/shell_integration/bash \
    -o "$DOTFILES_PATH/bash/env/autocompletions/iterm2_shell_integration.bash"
fi

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
