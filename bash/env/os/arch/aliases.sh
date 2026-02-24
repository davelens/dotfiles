alias gls='ls' # We already use GNU ls in bash/aliases.sh
alias cpuclock='cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq'
alias flushlogs='sudo journalctl --user --rotate && sudo journalctl --user --vacuum-time=1s'
# shellcheck disable=SC2154
alias rofi-test='for i in $(seq 8); do for j in $(seq 15); do echo "$i - $j"; rofi-start --launcher type-$i --theme style-$j; done; done'

# Clipboard aliases (pbcopy/pbpaste for macOS muscle memory)
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
  alias pbcopy="wl-copy"
  alias pbpaste="wl-paste"
else
  alias pbcopy="xclip -selection clipboard"
  alias pbpaste="xclip -selection clipboard -o"
fi
