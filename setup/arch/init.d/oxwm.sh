#!/usr/bin/env bash
set -e

sudo pacman -S libx11 libxft freetype2 fontconfig pkg-config xterm
paru -S oxwm-git
