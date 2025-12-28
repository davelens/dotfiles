#!/usr/bin/env bash
set -e

# Install QEMU/KVM with both virt-manager and GNOME Boxes frontends.

echo "==> Installing QEMU/KVM and VM management tools..."
sudo pacman -S --needed --noconfirm qemu-full virt-manager gnome-boxes libvirt

echo "==> Enabling libvirtd service..."
sudo systemctl enable --now libvirtd

echo "==> Adding user to libvirt group..."
sudo usermod -aG libvirt "$USER"

echo "==> QEMU/KVM installation complete."
echo "    Log out and back in for group changes to take effect."
