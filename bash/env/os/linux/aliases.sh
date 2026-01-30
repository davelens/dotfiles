alias gls='ls' # We already use GNU ls in bash/aliases.sh
alias cpuclock='cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq'

# Clipboard aliases (pbcopy/pbpaste for macOS muscle memory)
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
  alias pbcopy="wl-copy"
  alias pbpaste="wl-paste"
else
  alias pbcopy="xclip -selection clipboard"
  alias pbpaste="xclip -selection clipboard -o"
fi
