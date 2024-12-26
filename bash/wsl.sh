# This file will only load on WSL.

[[ -f ${DOTFILES_PATH}/bash/helpers.sh ]] && source ${DOTFILES_PATH}/bash/helpers.sh

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
alias pbcopy="clip.exe"
alias pbpaste="powershell.exe -command 'Get-Clipboard' | head -n -1"

# Make sure an ssh-agent is running with our default key active.
ssh-agent-bootstrap

# After an upgrade to Ubuntu 20.04 LTS, brew no longer gets loaded by default.
#eval $(SHELL=/bin/bash /home/linuxbrew/.linuxbrew/bin/brew shellenv)
