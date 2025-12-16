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

# I prefer GNU coreutils over the BSD ones on macos, so I'm trying this out
# to keep my scripts consistent between macos/linux.
alias cp='gcp'
alias ls='gls'
alias sed='gsed'
