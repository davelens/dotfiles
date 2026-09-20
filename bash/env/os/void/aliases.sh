alias flushram="sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'"
alias mysqldump="mariadb-dump"
alias wget='wget --hsts-file="$XDG_STATE_HOME/wget-hsts"'

# Clipboard aliases (pbcopy/pbpaste for macOS muscle memory)
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
  alias pbcopy="wl-copy"
  alias pbpaste="wl-paste"
  alias wssh="waypipe --no-gpu ssh"
elif command -v xclip; then
  alias pbcopy="xclip -selection clipboard"
  alias pbpaste="xclip -selection clipboard -o"
fi
