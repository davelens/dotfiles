#!/usr/bin/env bash
set -e

# This installs QEMU alongside gnome-boxes for a basic GUI.
# I might remove gnome-boxes once I'm familiar enough with QEMU on the CLI.

echo "==> Installing QEMU/KVM and VM management tools..."
sudo pacman -S --needed --noconfirm qemu-full virt-manager libvirt dmidecode

echo "==> Enabling libvirtd service..."
sudo systemctl enable --now libvirtd

echo "==> Adding user to libvirt group..."
sudo usermod -aG libvirt "$USER"

echo "==> Enabling default NAT network for VM internet access..."
sudo virsh net-start default 2>/dev/null || true
sudo virsh net-autostart default

echo "==> QEMU/KVM installation complete."
echo "    Log out and back in for group changes to take effect."
