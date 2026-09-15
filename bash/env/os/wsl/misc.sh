# Compilation preferences do not require Windows or a graphical session.
if [[ -n ${BREW_PATH:-} ]]; then
  export FREEDESKTOP_MIME_TYPES_PATH="${FREEDESKTOP_MIME_TYPES_PATH-$BREW_PATH/share/mime/packages/freedesktop.org.xml}"
fi
