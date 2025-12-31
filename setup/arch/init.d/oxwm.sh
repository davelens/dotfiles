#!/usr/bin/env bash
set -e

sudo pacman -S --needed --noconfirm libx11 libxft freetype2 fontconfig pkg-config xterm
paru -S --needed --noconfirm oxwm-git
