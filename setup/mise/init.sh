#!/usr/bin/env bash
set -e

# Install mise if not present.
if ! command -v mise >/dev/null; then
  echo "==> Installing mise..."
  curl https://mise.run | sh

  # Activate mise for the current shell session.
  echo "==> Activating mise..."
  eval "$(mise activate bash)"
fi

# Trust the config to avoid prompts.
echo "==> Trusting mise config..."
mise trust

# Install tools defined in config.
echo "==> Installing mise tools..."
mise install
