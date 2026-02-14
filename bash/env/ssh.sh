###############################################################################
# SSH agent management via keychain (Linux only; macOS handles this natively).
###############################################################################

[[ "$OSTYPE" == darwin* ]] && return

if ! command -v keychain >/dev/null; then
  echo "${CUN}NOTE${CNUN}: Installing \`keychain\` will bootstrap + keep alive your SSH agent across sessions."
  echo "      Right now you still need to manually \`eval \$(ssh-agent); ssh-add\` in each term session."
  return
fi

KEYCHAIN_DIR="$XDG_RUNTIME_DIR/keychain"

if [[ ! -d "$KEYCHAIN_DIR" ]]; then
  mkdir -p "$KEYCHAIN_DIR"
  chmod 700 "$KEYCHAIN_DIR"
fi

eval "$(keychain --eval --quiet --ssh-allow-forwarded --absolute --dir "$KEYCHAIN_DIR" id_rsa)"

unset KEYCHAIN_DIR
