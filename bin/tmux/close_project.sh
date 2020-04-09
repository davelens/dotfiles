#!/usr/bin/env bash

company=$1
project=$2

if [ "$company" == "" ]; then
	echo "$(tput setaf 11)What project do you want to close?$(tput sgr0)"
	echo -n "$(tput sgr0)$(tput bold)blimp/$(tput sgr0)"
	company='blimp'
	read project
fi

if [ "$project" == "" ]; then
	company='blimp'
	project=$1
fi

tmux kill-session -t $company/$project
