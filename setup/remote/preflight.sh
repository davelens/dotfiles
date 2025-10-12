if macos_needs_newer_bash; then
  if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

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
