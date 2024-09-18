#!/usr/bin/env bash

[[ -f ~/.bash/shell ]] && . ~/.bash/shell

# Load OS specific files
OS=`os`
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
