alias allow='xattr -d com.apple.quarantine'
alias rm='$(which trash) &>/dev/null && trash' # Puts rm'ed files in the OS trash
alias ss="osascript \"\$DOTFILES_REPO_HOME/config/macos/hide-terminal.scpt\" && utility misc screenshot && killall Terminal"
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

