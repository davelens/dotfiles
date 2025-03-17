###############################################################################
# This script waits for WSL2 to finish its bootstrapping process before
# granting my own user access.
###############################################################################

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
# until the systemd-private-* folders appear, and then I allow my $USER access.

if ! compgen -G "/tmp/systemd-private-*" >/dev/null; then
  echo "Waiting for WSL2 to finish its prep ..."
fi

until compgen -G "/tmp/systemd-private-*" >/dev/null; do
  sleep 1
done

declare -i MY_UID
MY_UID=$(id -u)
# Adding the additional forward slash to mimick the default behaviour.
XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$MY_UID/}
export XDG_RUNTIME_DIR
while findmnt --shadow -n -o SOURCE "$XDG_RUNTIME_DIR" >/dev/null; do
  echo "Unmounting '$XDG_RUNTIME_DIR'" >&2
  sudo umount "$XDG_RUNTIME_DIR"
done
unset MY_UID
