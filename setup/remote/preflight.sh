# Only the bare minimum needed by the remaining installer steps. Package
# bundles and system upgrades live in dotsys (`dots setup --dotsys <os>`).
if macos; then
  if ! command -v brew >/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # A fresh install isn't on $PATH yet in this shell.
    for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [ -x "$brew" ] && eval "$("$brew" shellenv)" && break
    done
  fi

  if macos_needs_newer_bash; then
    brew install bash
  fi
fi

if ! command -v jq >/dev/null; then
  if macos; then
    brew install jq
  elif arch; then
    sudo pacman -S --needed --noconfirm jq
  elif debian; then
    sudo apt-get update
    sudo apt-get install -y jq
  fi
fi
