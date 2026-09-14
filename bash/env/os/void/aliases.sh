alias flushram="sudo sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches'"
alias mysqldump="mariadb-dump"
# shellcheck disable=SC2154
dots_selected sway && alias rofi-test='for i in $(seq 8); do for j in $(seq 15); do echo "$i - $j"; rofi-start --launcher type-$i --theme style-$j; done; done'

# Clipboard aliases apply only to a selected, local Sway session.
if dots_selected sway && [[ -n ${SWAYSOCK:-} && -n ${WAYLAND_DISPLAY:-} &&
  -z ${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-} ]]; then
  alias pbcopy >/dev/null 2>&1 || declare -F pbcopy >/dev/null || alias pbcopy='wl-copy'
  alias pbpaste >/dev/null 2>&1 || declare -F pbpaste >/dev/null || alias pbpaste='wl-paste'
  alias wssh >/dev/null 2>&1 || declare -F wssh >/dev/null || alias wssh='waypipe --no-gpu ssh'
fi
