#!/usr/bin/env bash

# Load up the .env file, if present.
[ -r ~/.env ] && export $(cat ~/.env | grep -v ^\# | xargs)

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
