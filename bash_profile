#!/bin/bash

# Load up the .env file, if present.
[ -r ~/.env ] && export $(cat ~/.env | grep -v ^\# | xargs)

# Source the files in the bash folder
for file in ~/.bash/{shell,commands,prompt,aliases,private}; do
	[ -r "$file" ] && . "$file";
done;
unset file;

# Load OS specific files
OS=`uname -s`
[ $OS == 'Darwin' ] && . ~/.bash/macos
[ $OS == 'Linux' ] && . ~/.bash/linux

# Provide BASH completion for a myriad of functions
[ -f $(brew --prefix)/etc/bash_completion ] && . $(brew --prefix)/etc/bash_completion
