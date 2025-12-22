if macos; then
  setup/brew/init.sh --skip-bundles >/dev/null

  if macos_needs_newer_bash; then
    brew install bash
  fi
elif arch; then
  sudo pacman -Syu
elif debian; then
  sudo apt-get update
fi

if ! command -v jq >/dev/null; then
  if macos; then
    brew install jq
  elif arch; then
    sudo pacman -S --noconfirm jq
  elif debian; then
    sudo apt-get install -y jq
  fi
fi
