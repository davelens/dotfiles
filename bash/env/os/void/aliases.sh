alias flushram="sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'"
alias mysqldump="mariadb-dump"
# shellcheck disable=SC2154
alias rofi-test='for i in $(seq 8); do for j in $(seq 15); do echo "$i - $j"; rofi-start --launcher type-$i --theme style-$j; done; done'

# Clipboard aliases (pbcopy/pbpaste for macOS muscle memory)
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
  alias pbcopy="wl-copy"
  alias pbpaste="wl-paste"
  alias wssh="waypipe --no-gpu ssh"
elif command -v xclip; then
  alias pbcopy="xclip -selection clipboard"
  alias pbpaste="xclip -selection clipboard -o"
fi
