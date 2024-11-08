#!/usr/bin/env bash

export DOTFILES_PATH=$(<~/.local/.dotfiles_path)
export OS="${DOTFILES_PATH}/bin/os"

# Load the mandatory shell settings and ENV vars before everything else.
[[ -f "${DOTFILES_PATH}/bash/colors" ]] && . "${DOTFILES_PATH}/bash/colors"
[[ -f "${DOTFILES_PATH}/bash/shell" ]] && . "${DOTFILES_PATH}/bash/shell"

# OS specific settings
[[ $OS == 'windows' ]] && . "${DOTFILES_PATH}/bash/wsl"
[[ $OS == 'macos' ]] && . "${DOTFILES_PATH}/bash/macos"
[[ $OS == 'linux' ]] && . "${DOTFILES_PATH}/bash/linux"

# Source the files in the bash folder
for file in "${DOTFILES_PATH}/bash/{commands,prompt,aliases,private}"; do
  [ -r "$file" ] && . "$file";
done;
unset file;
