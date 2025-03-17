# This file will only load on Linux

alias gls='ls' # We already use GNU ls in bash/aliases.sh

# The mimemagic gem requires this file, which is installed via a homebrew pkg
# called shared-mime-info. On Linuxbrew however we need to explicitly set this
# path.
export FREEDESKTOP_MIME_TYPES_PATH="$BREW_PATH/share/mime/packages/freedesktop.org.xml"

setxkbmap -option altwin:ctrl_win # Switch win/command key with ctrl
setxkbmap -option ctrl:nocaps     # Switch capslock with ctrl
