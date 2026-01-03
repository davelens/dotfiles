#!/usr/bin/env bash
set -e

sudo pacman -S --needed --noconfirm power-profiles-daemon

sudo systemctl enable --now power-profiles-daemon

# Install udev rule for automatic profile switching
sudo cp "$DOTFILES_REPO_HOME/config/arch/udev/99-power-profiles.rules" /etc/udev/rules.d/
sudo udevadm control --reload-rules

echo "Power profiles daemon installed and enabled."
echo "Automatic switching enabled: power-saver on battery, performance on AC."
echo ""
echo "Available profiles:"
powerprofilesctl list

echo ""
echo "Manual usage:"
echo "  powerprofilesctl set power-saver    # Maximum battery life"
echo "  powerprofilesctl set balanced       # Default"
echo "  powerprofilesctl set performance    # Maximum performance"
