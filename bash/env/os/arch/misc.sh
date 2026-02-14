###############################################################################
# Env overrides I couldn't quite (yet) fit into other categories.
###############################################################################

if [ -n "$BREW_PATH" ]; then
  # The mimemagic gem requires this file, which is installed via a homebrew pkg
  # called shared-mime-info. On Linuxbrew however we need to explicitly set this
  # path.
  export FREEDESKTOP_MIME_TYPES_PATH="$BREW_PATH/share/mime/packages/freedesktop.org.xml"
fi

# No setxkbmap on Wayland.
if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
  # Accelerated rendering is not available on a VM (or WSL2), so explicitly
  # allow software rendering.
  export WLR_RENDERER_ALLOW_SOFTWARE=1
  export WLR_RENDERER=pixman
  export WLR_NO_HARDWARE_CURSORS=1
elif [ "$XDG_SESSION_TYPE" == "x11" ]; then
  if command -v setxkbmap >/dev/null; then
    setxkbmap -option altwin:ctrl_win # Switch win/command key with ctrl
    setxkbmap -option ctrl:nocaps     # Switch capslock with ctrl
  else
    echo "${CUN}NOTE${CNUN}: setxkbmap is not available, so I could not remap ctrl to capslock."
  fi
fi
