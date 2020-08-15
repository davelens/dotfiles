#!/usr/bin/env bash

# After an upgrade to Ubuntu 20.04 LTS, brew no longer gets loaded by default.
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)

# Load up the .env file, if present.
[[ -f ~/.bash/commands ]] && . ~/.bash/commands
export_env_vars_from_file

# Source the files in the bash folder
for file in ~/.bash/{shell,commands,prompt,aliases,private}; do
  [ -r "$file" ] && . "$file";
done;
unset file;

# Load OS specific files
OS=`os`
[ $OS == 'windows' ] && . ~/.bash/wsl
[ $OS == 'macos' ] && . ~/.bash/macos
[ $OS == 'linux' ] && . ~/.bash/linux

# Source all downloaded completion files.
for file in ~/.bash/completions/*.bash; do
  [ -r "$file" ] && . "$file";
done;
unset file;
