###############################################################################
# Env overrides I couldn't quite (yet) fit into other categories.
###############################################################################

if [ -n "$BREW_PATH" ]; then
  # The mimemagic gem requires this file, which is installed via a homebrew pkg
  # called shared-mime-info. On Linuxbrew however we need to explicitly set this
  # path.
  export FREEDESKTOP_MIME_TYPES_PATH="${FREEDESKTOP_MIME_TYPES_PATH-$BREW_PATH/share/mime/packages/freedesktop.org.xml}"
fi
