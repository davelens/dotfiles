#!/bin/bash

function lowercase()
{
	if [ -n "$1" ]; then
		echo "$1" | tr "[:upper:]" "[:lower:]"
	else
	    cat - | tr "[:upper:]" "[:lower:]"
	fi
}

# accepts path and session (=company/project)
function create_new_project()
{
	path=$1
	session=$2

	echo "$(tput setaf 10)Creating project directory ...$(tput sgr0)"
	mkdir -p $path/$session

	echo "$(tput setaf 10)Clone git repo ...$(tput sgr0)"
	git clone git@$github_url:$session.git $path/$session && cd $path/$session

	echo "$(tput setaf 10)Done.$(tput sgr0)"
}

# accepts path and session (=company/project)
function open_tmux_session()
{
	path=$1
	session=$2
	mysql_running=`pgrep -n mysqld`

	if [ ! $mysql_running ]; then
		echo -n "$(tput setaf 11)MySQL is not running. Would you like to start it? $(tput sgr0)$(tput bold)(y/n)$(tput sgr0)$(tput setaf 11):$(tput sgr0) "
		read start_mysql

		if [ $(lowercase $start_mysql) == "y" ]; then
			mysql.server start
			mysql_running=`pgrep -n mysqld`
		fi
	fi

	# editor window
	tmux new-session -s $session -n editor -d
	tmux send-keys -t $session "cd $path/$session" C-m
	tmux send-keys -t $session "clear && vim" C-m
	# database window (only when MySQL is up and running)
	if [ $mysql_running ]; then
		tmux new-window -n database -t $session
		tmux send-keys -t $session:database "cd $path/$session" C-m
		if [ -f "$path/$session/dbshell" ]; then
			tmux send-keys -t $session:database "clear && ./dbshell" C-m
		fi
		tmux select-pane -t $session:database -U
	fi
	# shell window
	tmux new-window -n shell -t $session
	tmux send-keys -t $session:shell "cd $path/$session && clear" C-m
	# rails needs a console window
	if [ -f "$path/$session/Gemfile" ] && grep -Rq "gem 'rails'" "$path/$session/Gemfile"; then
		tmux send-keys -t $session:shell "clear && bundle install" C-m

		if [ $mysql_running ]; then
			# open a client connection to the dev database for this rails project
			database="$project""_dev"
			tmux send-keys -t $session:database "clear && mysql $database" C-m

			# console window
			tmux new-window -n console -t $session
			tmux send-keys -t $session:console "cd $path/$session" C-m
			tmux send-keys -t $session:console "clear && rails c" C-m

			# guard window
			tmux new-window -n guard -t $session
			tmux send-keys -t $session:guard "cd $path/$session" C-m
			tmux send-keys -t $session:guard "clear && bundle exec guard" C-m
		fi
	fi
	# select the editor and attach to the session
	tmux select-window -t $session:1
}

# accepts session (=company/project)
function attach_to_tmux_session()
{
	session=$1

	echo -n "$(tput setaf 11)Do you want to attach to the $(tput sgr0)$(tput bold)$session$(tput sgr0)$(tput setaf 11) session? $(tput sgr0)$(tput bold)(y/n)$(tput sgr0)$(tput setaf 11):$(tput sgr0) "
	read switchToSession

	if [ $(lowercase $switchToSession) == "y" ]; then
		tmux attach -t $session
	else
		exit 1
	fi
}


# Define our project working directory path
path="$HOME/Sites"

# Get the project from a given parameter, or query the user if none was provided
if [ "$1" == "" ]; then
	echo "$(tput setaf 11)What project do you want to open?$(tput sgr0)"
	echo -n "$(tput sgr0)$(tput bold)$path/$(tput sgr0)"
	read project
else
	project=$1
fi

# Determine company and project that was given
IFS='/' read -a array <<< "$project"
split_count=${#array[@]}
company=${array[0]}
project=${array[1]}
script_location="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/$(echo `basename $0`)"

if [ $split_count != 2 ]; then
	echo "$(tput setaf 9)You need a $(tput sgr0)$(tput bold)~/Sites/company/project $(tput sgr0)$(tput setaf 9)structure for this script to work.$(tput sgr0)"
	echo "$(tput setaf 9)You can make adjustments to this script by editing $script_location$(tput sgr0)"
	exit
fi

# Determine the github URL
github_url=$([ "$2" == '' ] && echo 'github.com' || echo $2)

# The directory doesn't exist
if [ ! -d "$path/$company/$project" ]; then
	echo "$(tput setaf 9)The given project directory $(tput sgr0)$(tput bold)$path/$company/$project$(tput sgr0)$(tput setaf 9) does not exist.$(tput sgr0)"
	echo -n "$(tput setaf 11)Would you like to create it? $(tput sgr0)$(tput bold)(y/n)$(tput sgr0)$(tput setaf 11):$(tput sgr0) "
	read createNewProject

	if [ $(lowercase $createNewProject) == "y" ]; then
		create_new_project $path "$company/$project"
	else
		exit
	fi
fi

# A session with that name already exists
tmux has-session -t "$company/$project" > /dev/null 2>&1
if [ $? == 0 ]; then
	echo "$(tput setaf 9)A session with that name is already running.$(tput sgr0)"
# Session name is free, open a new one
else
	open_tmux_session $path "$company/$project"
fi

attach_to_tmux_session "$company/$project"
