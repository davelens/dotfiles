#!/usr/bin/env bash
set -e

MISE_BIN="$HOME/.local/bin/mise"

if [ -x "$MISE_BIN" ]; then
  echo "Mise is already installed."
else
  curl https://mise.run | sh
fi

eval "$("$MISE_BIN" activate bash)"
"$MISE_BIN" upgrade
