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

# Source all downloaded completion files.
for file in ~/.bash/completions/*.bash; do
  [ -r "$file" ] && . "$file";
done;
unset file;

# Some tools that need to be hooked before use.
eval "$(rbenv init -)"
