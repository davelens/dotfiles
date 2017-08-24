#!/bin/bash

# Source the files in the bash folder
for file in ~/.bash/{shell,commands,prompt,aliases,private}; do
	[ -r "$file" ] && . "$file";
done;
unset file;

OS=`uname -s`
[ $OS == 'Darwin' ] && . ~/.bash/macos
[ $OS == 'Linux' ] && . ~/.bash/linux

[ -f $(brew --prefix)/etc/bash_completion  ] && . $(brew --prefix)/etc/bash_completion
