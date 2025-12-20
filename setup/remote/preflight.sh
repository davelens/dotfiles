setup/brew/init.sh --skip-bundles >/dev/null

if macos_needs_newer_bash; then
  brew install bash
fi

if ! command -v jq >/dev/null; then
  if [ -f /etc/arch-release ]; then
    sudo pacman -S --noconfirm jq
  elif [ "$(uname)" = "Darwin" ]; then
    brew install jq
  else
    sudo apt-get update && sudo apt-get install -y jq
  fi
fi
