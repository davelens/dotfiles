#!/usr/bin/env bash

OS=`${HOME}/.local/bin/os`

# Load the mandatory shell settings and ENV vars before everything else.
[[ -f ~/.bash/colors ]] && . ~/.bash/colors
[[ -f ~/.bash/shell ]] && . ~/.bash/shell

# OS specific settings
[[ $OS == 'windows' ]] && . ~/.bash/wsl
[[ $OS == 'macos' ]] && . ~/.bash/macos
[[ $OS == 'linux' ]] && . ~/.bash/linux

# Source the files in the bash folder
for file in ~/.bash/{commands,prompt,aliases,private}; do
  [ -r "$file" ] && . "$file";
done;
unset file;

# rbenv is a Ruby version manager.
if [ `command -v rbenv` ]; then
  eval "$(rbenv init -)"
fi

# ASDF is a version manager for multiple languages.
if [ `command -v asdf` ]; then
  source "${BREW_PATH}/opt/asdf/libexec/asdf.sh"
  source "${BREW_PATH}/opt/asdf/etc/bash_completion.d/asdf.bash"
fi
