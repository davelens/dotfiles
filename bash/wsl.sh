# This file will only load on WSL.

#
# So on WSL it seems that there's some tomfoolery going on as it starts up
# our shell. Some history ...
#
# As we boot, the shell becomes accessible to us, but any tmux session, SSH 
# agents we start,... seems to die after about 10 seconds. I"ve had that ever
# since I started using WSL2, but didn't think much of it. I could restart
# tmux/ssh-agent after that and everything seemed to persist just fine.
#
# There was another issue with momentarily-appearing clipboard popups causing
# me to lose focus for about a millisecond. Very annoying as you can imagine.
# It seemed to have been triggered the moment I started running tmux. I 
# couldn't dig up the problem exactly, but I disabled WSLg after digging up a
# [GH issue](https://github.com/microsoft/wslg/issues/443) describing not quite
# the same, but very similar issue:
#
# In %USERPROFILE%/.wslconfig:
#
#   [wsl2]
#   guiApplications=false
#
# The good news is, that seemed to have solved my clipboard popups.
# The bad news is, I seem to have broken clipboard support between windows/wsl2.
#
# Even more bad news;when I rebooted WSL2, I started getting permissions errors 
# on /run/user/1000 not allowing me to create dirs or files. That particular
# issue seems to be related to
# [this GH issue](https://github.com/microsoft/WSL/issues/9689).
#
# So I tried to use the workaround suggested there. At that point, I noticed 
# /tmp/ contains about 400+ folders until a certain point, when
# it seems to get emptied, and a couple of systemd-private-* folders appear.
# I'm not sure what causes it but as far as I understand it, it seems to be 
# related to WSL using user 1000 to bootstrap itself.
#
# So I changed my user ID from 1000 to 1337. As root:
#
#   usermod -u 1337 $USER
#   chown -R davelens /run/user
#
# That seems to have fixed the permissions errors. I don't really care if this
# isn't proper practice, I just want this to work so I can do some coding.
#
# So as a final step, to prevent any kind of errors on startup, I just wait
# until the systemd-private-* folders appear, and then I allow myself access.
#
if ! compgen -G "/tmp/systemd-private-*" > /dev/null; then
  echo "Waiting for WSL2 to finish its prep ..."
fi

until compgen -G "/tmp/systemd-private-*" > /dev/null; do
  sleep 1
done
clear # So the message doesn't linger.

declare -i MyUID=$(id -u)
# Adding the additional forward slash to mimick the default behaviour.
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$MyUID/}
export XDG_RUNTIME_DIR
while findmnt --shadow -n -o SOURCE "$XDG_RUNTIME_DIR" >/dev/null; do
	echo "Unmounting '$XDG_RUNTIME_DIR'" >&2
	sudo umount "$XDG_RUNTIME_DIR"
done

# Bootstrap an ssh-agent and add your default key to it.
function ssh-agent-bootstrap {
  if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ] || ! pgrep -u "$USER" ssh-agent > /dev/null; then
    export DOTFILES_SSH_AUTH_SOCK="${DOTFILES_TMP_HOME}/ssh-agent.socket"
    export SSH_AUTH_SOCK="$DOTFILES_SSH_AUTH_SOCK"
    [ -S "$SSH_AUTH_SOCK" ] && rm -f "$SSH_AUTH_SOCK"
    eval "$(ssh-agent -s -a $SSH_AUTH_SOCK)"
    echo $SSH_AGENT_PID >> "${XDG_RUNTIME_DIR}/ssh-agent.pid"
  fi
}

# The mimemagic gem requires this file, which is installed via a homebrew pkg
# called shared-mime-info. On Linuxbrew however we need to explicitly set this
# path.
export FREEDESKTOP_MIME_TYPES_PATH="${BREW_PATH}/share/mime/packages/freedesktop.org.xml"
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

notes() {
  local mountpoint="${HOME}/Network/alexandria"

  if ! mount -l | grep Network/alexandria > /dev/null; then
    sudo mount -t drvfs '\\alexandria\storage\projects\notes' "$mountpoint"
  fi

  bash -c "utility tmux quickstart \"$@\" -- \"$mountpoint\" --"
}

# Make sure an ssh-agent is running with our default key active.
ssh-agent-bootstrap

# Primarily make sure keychain doesn't create files in the home dir, but
# also have it hold our initialized ssh-agent.
keychain --inherit any --agents ssh id_rsa --absolute --dir "${XDG_RUNTIME_DIR}keychain" --quiet

# After an upgrade to Ubuntu 20.04 LTS, brew no longer gets loaded by default.
#eval $(SHELL=/bin/bash /home/linuxbrew/.linuxbrew/bin/brew shellenv)

# Makes sure that the terminal is cleared when pressing Ctrl+l in tmux in WSL.
bind -x $'"\C-l":clear;'
