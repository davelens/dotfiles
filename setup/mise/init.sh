#!/usr/bin/env bash
set -e

if command_exists mise; then
  echo "Mise is already installed."
else
  curl https://mise.run | sh
fi

mise upgrade
