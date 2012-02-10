#!/bin/bash

# Source the files in the bash folder
for file in ~/.bash/{shell,commands,prompt,aliases}; do
	[ -r "$file" ] && source "$file";
done;
unset file;


