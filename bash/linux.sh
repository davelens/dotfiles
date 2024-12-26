# This file will only load on Linux

# The mimemagic gem requires this file, which is installed via a homebrew pkg
# called shared-mime-info. On Linuxbrew however we need to explicitly set this
# path.
export FREEDESKTOP_MIME_TYPES_PATH="${BREW_PATH}/share/mime/packages/freedesktop.org.xml"

# di = directory
# fi = file
# ln = symbolic link
# pi = fifo file
# so = socket file
# bd = block (buffered) special file
# cd = character (unbuffered) special file
# or = symbolic link pointing to a non-existent file (orphan)
# mi = non-existent file pointed to by a symbolic link (visible when you type ls -l)
# ex = file which is executable (ie. has 'x' set in permissions).
# *.rpm = files with the ending .rpm
LS_COLORS=$LS_COLORS:'di=0;35:'; export LS_COLORS
alias lsa='ls -hal --color=tty'
alias pbcopy='xclip -selection clipboard'

setxkbmap -option altwin:ctrl_win # Switch win/command key with ctrl
setxkbmap -option ctrl:nocaps # Switch capslock with ctrl

# Make sure we can use 256 color in (XFCE)Terminal
if [ -e /usr/share/terminfo/x/xterm-256color ] && [ "$COLORTERM" == "xfce4-terminal" ]; then
  export TERM=xterm-256color
fi
