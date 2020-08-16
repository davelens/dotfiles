#!/usr/bin/env bash

# Load up the .env file, if present.
[[ -f ~/.bash/commands ]] && . ~/.bash/commands
OS=`os`
export_env_vars_from_file

# Source the files in the bash folder
for file in ~/.bash/{shell,commands,prompt,aliases,private}; do
  [ -r "$file" ] && . "$file";
done;
unset file;

# Load OS specific files
[ $OS == 'windows' ] && . ~/.bash/wsl
[ $OS == 'macos' ] && . ~/.bash/macos
[ $OS == 'linux' ] && . ~/.bash/linux

# Source all downloaded completion files.
for file in ~/.bash/completions/*.bash; do
  [ -r "$file" ] && . "$file";
done;
unset file;

eval "$(rbenv init -)"
eval "$(hub alias -s)" # Alias hub straight into git
