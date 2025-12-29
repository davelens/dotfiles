#!/usr/bin/env bash
set -e

echo "==> Configuring GnuPG..."

# Creates the keyring on first run.
gpg --list-keys >/dev/null 2>&1

# Ensure the gnupg directory exists with correct permissions.
mkdir -p "$HOME/.local/share/gnupg"
chmod 700 "$HOME/.local/share/gnupg"
