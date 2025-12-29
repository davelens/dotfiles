#!/usr/bin/env bash
set -e

echo "==> Configuring GnuPG..."

# Ensure correct permissions on GNUPGHOME (created by dotbot).
chmod 700 "$GNUPGHOME"

# Creates the keyring on first run (batch mode to avoid prompts).
gpg --batch --list-keys >/dev/null 2>&1 || true
