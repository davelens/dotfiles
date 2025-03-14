##############################################################################
# Env overrides I couldn't quite (yet) fit into other categories.
##############################################################################

alias gls='ls' # We already use GNU ls in bash/aliases.sh

# This var is used by a Linuxbrew package named "shared-mime-info".
# The mimemagic Ruby gem requires it to compile properly.
export FREEDESKTOP_MIME_TYPES_PATH="${BREW_PATH}/share/mime/packages/freedesktop.org.xml"

# Makes sure that the terminal is cleared when pressing Ctrl+l in tmux in WSL.
# Note that I had this problem in both Windows Terminal and Wezterm, so I'm
# assuming Arch is responsible. Regardless, this fixes it.
bind -x $'"\C-l":clear;'
