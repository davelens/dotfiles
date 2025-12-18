#!/usr/bin/env bash

# TODO
# - [ ] Check if gnome-keyring is what we want, or kwallet (kde plasma).
#       i.e. which display manager are we starting out with on Arch?

# Arch-specific system packages (not from Brewfile.default)
arch_packages=(
  base                                # Minimal base system
  base-devel                          # Development tools (make, gcc, etc.)
  gnome-keyring                       # Secret storage (dep for bitwarden-cli)
  dkms                                # Dynamic kernel module support
  dolphin                             # File manager
  dunst                               # Notification daemon
  gdm                                 # Display manager
  # grim                                # Screenshot tool for Wayland
  grub                                # Bootloader
  iwd                                 # iNet wireless daemon
  # libva-nvidia-driver               # NVIDIA VA-API driver
  linux                               # Linux kernel
  linux-firmware                      # Firmware files for Linux
  linux-headers                       # Header files for Linux kernel
  mesa-utils                          # Mesa utilities
  meson                               # Build system
  nano                                # Text editor
  neovim                              # Vim-fork text editor
  noto-fonts                          # Font provider
  # nvidia-open-dkms                  # NVIDIA open kernel modules
  openssh                             # OpenSSH client and server
  pipewire-jack                       # Audio implementation
  # polkit-kde-agent                    # Polkit authentication agent
  # qt5-wayland                         # Qt5 Wayland support
  # qt6-wayland                         # Qt6 Wayland support
  rust                                # Rust programming language
  shfmt                               # Shell script formatter
  # slurp                               # Region selector for Wayland
  smartmontools                       # S.M.A.R.T. disk monitoring
  # uwsm                                # Universal Wayland Session Manager
  # vim                                 # Vi Improved text editor
  # virtualbox-guest-utils              # VirtualBox guest utilities
  wezterm                             # Terminal emulator
  wireless_tools                      # Wireless network tools
  # wl-clipboard                        # Wayland clipboard utilities
  # wofi                                # Application launcher for Wayland
  wpa_supplicant                      # WPA/WPA2 supplicant
  xdg-utils                           # XDG desktop integration utilities
  xorg-server                         # X.Org display server
  xorg-xinit                          # X.Org initialization
  zram-generator                      # Systemd zram generator
)

# Cross-platform packages (from Brewfile.default)
cross_platform_packages=(
  act                                 # Run GitHub Actions locally
  asciinema                           # Records shareable terminal sessions
  atuin                               # Shell history with syncing
  autoconf                            # dep for automake
  automake                            # Generates Makefiles
  bash                                # Bourne Again SHell
  bash-completion                     # Generates completion for bash commands
  bash-language-server                # LSP server for Bash
  bat                                 # Cat clone with git integration + colors
  bitwarden-cli                       # Access Bitwarden vaults in shell
  btop                                # Resource monitor
  cairo                               # dep for imagemagick, ffmpeg, chafa,...
  chafa                               # Image to ANSI/unicode art generator
  cmake                               # Cross-platform meta build tool
  cmatrix                             # Follow the white rabbit ...
  cmus                                # Music player
  coreutils                           # GNU Core Utils, helps do work in Unix
  ctags                               # Generates tag files for source code
  dav1d                               # Open source AV1 decoder
  deno                                # Modern JS and TypeScript runtime
  dialog                              # Swiss army knife of CLI dialog boxes
  discount                            # Markdown processor
  dos2unix                            # DOS to Unix and back file format converter
  duf                                 # Like df, but humanized
  dust                                # Like du, but humanized
  entr                                # File change listener
  fastfetch                           # System information tool
  fd                                  # File search
  fdupes                              # Duplicate file finder
  ffmpeg                              # Media conversion tool
  figlet                              # Text to ASCII generator
  fish                                # Friendly interactive shell
  fzf                                 # Fuzzy finder
  gawk                                # awk, but the GNU version
  gcc                                 # GNU compiler collection
  gdk-pixbuf2                         # dep for chafa
  github-cli                          # GitHub CLI tool
  ghostscript                         # dep for imagemagick
  git                                 # The stupid content tracker
  git-crypt                           # Transparent git file encryption
  git-delta                           # Diff tool
  git-lfs                             # Git system to version large files
  glib2                               # dep for imagemagick, ffmpeg, chafa,...
  gmp                                 # dep for coreutils, gcc,...
  sed                                 # GNU sed (default on Arch)
  tar                                 # GNU tar (default on Arch)
  gnupg                               # GNU Privacy Guard
  gnutls                              # Sets up TLS connections
  gpgme                               # GnuPG library access
  gum                                 # Fancy input processing for the terminal
  harfbuzz                            # dep for imagemagick, ffmpeg, chafa,...
  imagemagick                         # Image manipulation tools, v7+
  inetutils                           # GNU network utilities
  jq                                  # JSON processor
  less                                # Like `more`, but with more features
  libass                              # dep for ffmpeg
  libavif                             # dep for chafa
  libheif                             # dep for imagemagick
  libmicrohttpd                       # dep for ffmpeg
  libmpc                              # dep for gcc
  libraw                              # dep for imagemagick
  librsvg                             # dep for chafa
  libssh2                             # dep for bat, git-delta,...
  libtool                             # dep for imagemagick, elixir,...
  libx11                              # dep for imagemagick, ffmpeg, chafa,...
  libzip                              # Library to manipulate ZIP archives
  lolcat                              # Rainbow colours for ASCII text
  luarocks                            # Package manager for Lua
  m4                                  # dep for elixir, erlang,...
  mariadb                             # MySQL-compatible database
  navi                                # Terminal cheatsheet
  ncdu                                # Disk usage monitor written in ncurses
  ncftp                               # FTP browser
  nethack                             # One of the best games ever made
  nmap                                # Open source network exploration tool
  nodejs                              # Headache in a box
  openssl                             # dep for pretty much everything
  p11-kit                             # dep for ffmpeg
  pandoc                              # Markup conversion tool
  pango                               # dep for imagemagick, ffmpeg, chafa,...
  pastel                              # Terminal colour manipulation
  pgcli                               # A better PostgreSQL client
  pkgconf                             # Helps configure compiler/linker flags
  postgresql                          # Relational database
  pv                                  # Progress bar for the terminal
  python-pipx                         # Package manager for python
  redis                               # In-memory key/value database
  ripgrep                             # Fuzzy search
  rsync                               # Local and remote file copying tool
  sd                                  # Find/replace tool
  sdl2                                # dep for ffmpeg
  shared-mime-info                    # dep for imagemagick
  shellcheck                          # Shell script analysis tool
  srt                                 # dep for ffmpeg
  starship                            # Customizable shell prompt
  tealdeer                            # TL;DR client for man pages
  tesseract                           # Open source text recognition engine
  tmux                                # Terminal multiplexer
  tree                                # Dumps visual file trees for folders
  tree-sitter                         # Parser generator and library
  tree-sitter-cli                     # Interact with tree-sitter through CLI
  unbound                             # Caching DNS resolver
  viu                                 # Image viewer
  wget                                # Network downloader
  x264                                # dep for ffmpeg
  yarn                                # JavaScript package manager
  yq                                  # Convert YAML to JSON
  yt-dlp                              # YouTube video downloader
  zstd                                # dep for elixir, erlang,...
)

# AUR packages (requires yay)
aur_packages=(
  ack                                 # Grep-like text finder
  asdf-vm                             # Runtime version manager
  browsh                              # TUI webpage browser
  clipboard                           # Clipboard manager
  ddgr                                # DuckDuckGo from the terminal
  elixir-ls                           # Language server for Elixir
  fswatch                             # Directory change listener
  imagemagick6                        # Image manipulation tools, v6
  jqp                                 # Interactive jq playground
  kanata-bin                          # Cross-platform keyboard remapper
  mycli                               # A better MySQL client
  opencode-bin                        # TUI coding agent
  pipes.sh                            # Terminal screensaver, win95 style
  scc                                 # Counts lines of code; cloc alternative
  spicetify-cli                       # Provides theming for Spotify
  television                          # Fuzzy finder TUI
  ttysvr                              # Terminal screensaver, win95 style
  v8-r                                # Google's JS/wasm engine
  watson                              # Time registration
)

# Install pacman packages
sudo pacman -Syu
sudo pacman -S --noconfirm --needed \
  "${arch_packages[@]}" "${cross_platform_packages[@]}"

# Install yay (AUR helper) from source
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
  rm -rf /tmp/yay
fi

# Install AUR packages
yay -S --needed "${aur_packages[@]}"
