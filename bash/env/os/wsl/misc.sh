##############################################################################
# Env overrides I couldn't quite (yet) fit into other categories.
##############################################################################

# Makes sure that the terminal is cleared when pressing Ctrl+l in tmux in WSL.
# Note that I had this problem in both Windows Terminal and Wezterm, so I'm
# assuming Arch is responsible. Regardless, this fixes it.
bind -x $'"\C-l":clear;'

# This var is used by a Linuxbrew package named "shared-mime-info".
# The mimemagic Ruby gem requires it to compile properly.
export FREEDESKTOP_MIME_TYPES_PATH="${BREW_PATH}/share/mime/packages/freedesktop.org.xml"

# Colours my directories blue in WSL. Apparently `ls` does not colour my 
# directories properly there otherwise, despite using --color=tty.
#
# The *.rb part is for Ruby files, which I wanted to be coloured red.
# The `di` is the code for directories, one of several reserved by LS_COLORS:
#
#   di = directory
#   fi = file
#   ln = symbolic link
#   pi = fifo file
#   so = socket file
#   bd = block (buffered) special file
#   cd = character (unbuffered) special file
#   or = symbolic link pointing to a non-existent file (orphan)
#   mi = non-existent file pointed to by a symbolic link (visible when you type ls -l)
#   ex = file which is executable (ie. has 'x' set in permissions).
#
LS_COLORS=$LS_COLORS:"di=0;34:":"*.rb=0;35:"
export LS_COLORS

