# Remove the macOS quarantine attribute from downloaded files to bypass
# Gatekeeper warnings like:
# "This app is damaged and can't be opened."
# "This app was downloaded from the Internet. Are you sure you want to open it?"
alias allow='xattr -d com.apple.quarantine'
# Puts rm'ed files into macos's bin instead of permanently deleting them.
alias rm='$(which trash) &>/dev/null && trash'

# Flush the Directory Service cache on macos. Useful for forcing
# hostname/user/groups changes to update.
alias clearcache='sudo dscacheutil -flushcache'

# Disable/Enable ipv6 on the Wi-Fi interface.
# This is useful for when you're on a network that doesn't support ipv6, but
# I also haven't used this in AGES now. Consider removing these.
alias ipv6off='networksetup -setv6off Wi-Fi'
alias ipv6on='networksetup -setv6automatic Wi-Fi'
