# This file will only load on WSL.

# Bootstrap an ssh-agent and add your default key to it.
function ssh-agent-bootstrap {
  if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ] || ! pgrep -u "$USER" ssh-agent > /dev/null; then
    export SSH_AUTH_SOCK=/tmp/ssh-agent.socket
    [ -S "$SSH_AUTH_SOCK" ] && rm -f "$SSH_AUTH_SOCK"
    eval "$(ssh-agent -s -a $SSH_AUTH_SOCK)"
    ssh-add
  fi
}

# The mimemagic gem requires this file, which is installed via a homebrew pkg
# called shared-mime-info. On Linuxbrew however we need to explicitly set this
# path.
export FREEDESKTOP_MIME_TYPES_PATH="${BREW_PATH}/share/mime/packages/freedesktop.org.xml"
export INFOPATH="${BREW_PATH}/share/info:" # Fix duplication of info pages.
export WSL2_GUI_APPS_ENABLED="0"

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
# NOTE: On macos this command seems to have an additional column, so we need 
# to shift this by 1.
alias fs="ls -laSh $1 | grep -v ^d | awk '{print \$4 \"\t\" \$8}'"
alias lsa='ls -hal --color=tty'
alias pbcopy="clip.exe"
alias pbpaste="powershell.exe -command 'Get-Clipboard' | head -n -1"

# Make sure an ssh-agent is running with our default key active.
ssh-agent-bootstrap

# Primarily make sure keychain doesn't create files in the home dir, but
# also have it hold our initialized ssh-agent.
if command -v keychain >/dev/null; then
  eval $(keychain --eval --absolute --dir "${XDG_RUNTIME_DIR}/keychain" --quiet)
fi

# After an upgrade to Ubuntu 20.04 LTS, brew no longer gets loaded by default.
#eval $(SHELL=/bin/bash /home/linuxbrew/.linuxbrew/bin/brew shellenv)

# Makes sure that the terminal is cleared when pressing Ctrl+l in tmux in WSL.
bind -x $'"\C-l":clear;'
