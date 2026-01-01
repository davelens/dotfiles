#!/usr/bin/env bash
set -e

sudo pacman -S --needed --noconfirm fprintd

echo "Starting fingerprint enrollment..."
fprintd-enroll

# Enable fingerprint authentication in GDM.
# NOTE: I'd have to test this in isolation if this is sufficient, or if I
# do actually need to update the pam.d files manually.
sudo gdm-config fingerprint --enable

# PAM configuration for fingerprint auth. Afaik you only need to cover
# login, su, and sudo files.
PAM_CONFIG="auth required pam_env.so
auth sufficient pam_fprintd.so
auth sufficient pam_unix.so try_first_pass likeauth nullok
auth required pam_deny.so"

for file in login su sudo; do
  pam_file="/etc/pam.d/$file"
  if ! grep -q "pam_fprintd.so" "$pam_file" 2>/dev/null; then
    echo "$PAM_CONFIG" | sudo tee "$pam_file" >/dev/null
    echo "Configured $pam_file"
  else
    echo "$pam_file already configured, skipping"
  fi
done
