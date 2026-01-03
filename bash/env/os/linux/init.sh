# This file will only load on Linux

alias gls='ls' # We already use GNU ls in bash/aliases.sh

# Clipboard aliases (pbcopy/pbpaste for macOS muscle memory)
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
  alias pbcopy="wl-copy"
  alias pbpaste="wl-paste"
else
  alias pbcopy="xclip -selection clipboard"
  alias pbpaste="xclip -selection clipboard -o"
fi

if [ -n "$BREW_PATH" ]; then
  # The mimemagic gem requires this file, which is installed via a homebrew pkg
  # called shared-mime-info. On Linuxbrew however we need to explicitly set this
  # path.
  export FREEDESKTOP_MIME_TYPES_PATH="$BREW_PATH/share/mime/packages/freedesktop.org.xml"
fi

# No setxkbmap on Wayland.
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
  export WLR_RENDERER_ALLOW_SOFTWARE=1
  export WLR_RENDERER=pixman
  export WLR_NO_HARDWARE_CURSORS=1
elif [ "$XDG_SESSION_TYPE" == "x11" ]; then
  if command -v setxkbmap >/dev/null; then
    setxkbmap -option altwin:ctrl_win # Switch win/command key with ctrl
    setxkbmap -option ctrl:nocaps     # Switch capslock with ctrl
  else
    echo NOTE: setxkbmap is not available, so I could not remap ctrl to capslock.
  fi
fi
