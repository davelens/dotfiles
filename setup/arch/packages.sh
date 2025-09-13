#!/usr/bin/env bash

sudo pacman -S --needed \
  base \
  base-devel \
  bash-language-server \
  bitwarden \
  bitwarden-cli \
  cmake \
  deno \
  dkms \
  dolphin \
  dunst \
  fd \
  firefox \
  fzf \
  gdm \
  git \
  github-cli \
  grim \
  grub \
  htop \
  imagemagick \
  iwd \
  less \
  libva-nvidia-driver \
  linux \
  linux-firmware \
  linux-headers \
  lolcat \
  luarocks \
  mariadb \
  mesa-utils \
  meson \
  nano \
  neovim \
  nvidia-open-dkms \
  openssh \
  polkit-kde-agent \
  qt5-wayland \
  qt6-wayland \
  rust \
  shfmt \
  slurp \
  smartmontools \
  starship \
  tmux \
  uwsm \
  vim \
  virtualbox-guest-utils \
  wezterm \
  wget \
  wireless_tools \
  wl-clipboard \
  wofi \
  wpa_supplicant \
  xdg-utils \
  xorg-server \
  xorg-xinit \
  zram-generator

yay -S --needed \
  asdf-vm \
  getnf \
  kanata \
  yay \
  yay-debug
