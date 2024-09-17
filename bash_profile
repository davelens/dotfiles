#!/usr/bin/env bash

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
[ -f ~/.aliases ] && . ~/.aliases
[ $OS == 'windows' ] && . ~/.bash/wsl
[ $OS == 'macos' ] && . ~/.bash/macos
[ $OS == 'linux' ] && . ~/.bash/linux

# Source all downloaded completion files.
for file in ~/.bash/completions/*.bash; do
  [ -r "$file" ] && . "$file";
done;
unset file;

# Soom tools that need to be hooked before use.
eval "$(rbenv init -)"
eval "$(zoxide init bash)" # zoxide is a "better cd"
[ -f /usr/local/etc/profile.d/z.sh ] && . /usr/local/etc/profile.d/z.sh
