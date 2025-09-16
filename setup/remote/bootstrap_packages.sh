download_and_compile_dialog() {
  save_cursor
  compile_message="⏲ Compiling packages"
  tarball="$INSTALLER_TMP_HOME"/dialog.tar.gz
  progress "$compile_message" 1

  curl -so "$tarball" \
    https://invisible-island.net/datafiles/release/dialog.tar.gz
  reset_prompt && progress "$compile_message" 4

  tar -C "$INSTALLER_TMP_HOME" -xvzf "$tarball" >/dev/null
  dir=$(tar -tzf "$tarball" | head -1 | cut -f1 -d"/")
  reset_prompt && progress "$compile_message" 8

  cd "$INSTALLER_TMP_HOME/$dir" && ./configure --prefix="$HOME/.local" >/dev/null
  reset_prompt && progress "$compile_message" 13

  make >/dev/null
  reset_prompt && progress "$compile_message" 18

  make install >/dev/null
  reset_prompt && progress "$compile_message" 20

  unset compile_message
}

if ! command -v dialog >/dev/null; then
  download_and_compile_dialog
fi

reset_prompt

dialog --clear --yes-label "OK" --no-label "Abort" --yesno \
  "Hi! My name's Dave. Looks like you're about to install my dotfiles." 8 72
