#!/usr/bin/env bash
set -e

# Ensure mise is in PATH for this script.
export PATH="$HOME/.local/bin:$PATH"

# Install mise if not present.
if ! command -v mise >/dev/null; then
  echo "==> Installing mise..."
  curl https://mise.run | sh
fi

# Trust the config to avoid prompts.
echo "==> Trusting mise config..."
mise trust

# Install tools defined in config.
echo "==> Installing mise tools..."
mise install
