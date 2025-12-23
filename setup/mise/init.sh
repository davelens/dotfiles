#!/usr/bin/env bash
set -e

if command -v mise >/dev/null; then
  echo "Mise is already installed."
else
  curl https://mise.run | sh
fi
