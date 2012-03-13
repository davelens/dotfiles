#!/bin/bash

# Set a global variable representing the OS we're on.
# This way I can filter out dotfiles content for specific OSes.
# Mac OS X = Darwin
# Ubuntu, Debian, Mint,...  Linux
OS=`uname -s`

# Source the files in the bash folder
for file in ~/.bash/{shell,commands,prompt,aliases,private}; do
	[ -r "$file" ] && source "$file";
done;
unset file;

if [[ $OS == 'Darwin' ]];
then
	source ~/.bash/osx
fi
