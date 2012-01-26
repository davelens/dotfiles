# /usr/local binaries
if [[ $PATH != */usr/local* ]] ; then
	export PATH="$PATH:/usr/local/bin"
	export PATH="$PATH:/usr/local/sbin"
fi

if [[ $PATH != */opt/local* ]] ; then
	export PATH="$PATH:/opt/local/bin"
	export PATH="$PATH:/opt/local/sbin"
fi

# MAMP binaries
if [[ $PATH != */Applications/MAMP/Library/bin* ]] ; then
	export PATH="$PATH:/Applications/MAMP/Library/bin"
fi

# XCode X11 binaries
if [[ $PATH != */usr/X11/bin* ]] ; then
	export PATH="$PATH:/usr/X11/bin"
fi

# rbenv
if [[ $PATH != */.rbenv* ]] ; then
	export PATH="$HOME/.rbenv/bin:$PATH"
fi

# Aliases
if [ -f ~/.aliases ]; then
	. ~/.aliases
fi

# Git autocomplete
if [ -f ~/.bin/git-completion.bash ]; then
	. ~/.bin/git-completion.bash
fi

# color ls
export CLICOLOR=1

# don't put duplicate lines in the history
export HISTCONTROL=ignoredups 

# append to the history file rather than overwriting
shopt -s histappend 

export HISTIGNORE="ls:ll:la:pwd:clear:h:j"

# Methods

# creates an SSH key and uploads it to the given host
configure_ssh_host()
{
	username=$1
	hostname=$2
	identifier=$3
	keyfile=$4
	
	if [[ "$identifier" == "" ]] || [[ "$username" == "" ]] || [[ "$hostname" == "" ]] || [[ "$keyfile" == "" ]]
	then
		echo "usage: configure_ssh_host <username> <hostname> <identifier> <keyfile>"
	else
		ssh-keygen -f ~/.ssh/$keyfile.id_rsa -C "$USER $(date +'%Y/%m%/%d %H:%M:%S')"
		
		echo -e "Host $identifier\n\tHostName $hostname\n\tUser $username\n\tIdentityFile ~/.ssh/$keyfile.id_rsa" >> ~/.ssh/config
		
		ssh $identifier 'mkdir -p .ssh && cat >> ~/.ssh/authorized_keys' < ~/.ssh/$keyfile.id_rsa.pub
		
		tput bold; ssh -o PasswordAuthentication=no $identifier true && { tput setaf 2; echo 'Success!'; } || { tput setaf 1; echo 'Failure'; }; tput sgr0
		
		ssh_load_autocomplete
	fi
}

# Command used to test rest services that are under development
curlrest()
{
	method=$1
	url=$2
	parameters=$3

	if [[ "$method" == "" ]] || [[ "$url" == "" ]]
	then
		echo "usage: curlrest <method> <url> <*parameters>"
	else
		if [[ "$parameters" != "" ]]
		then
			parameters="--data-urlencode $(echo $parameters | xargs | sed 's/&/ --data-urlencode /g')"
		fi
	
		curl -v --globoff --get -X$method $url $parameters
		echo ""
	fi
}

# recursively gathers all files that match the search query to the chosen directory
gather_files()
{
	search=$1
	destination=$2

	if [[ "$search" == "" ]] || [[ "$destination" == "" ]]
	then	
		echo "usage: gather_files <search> <destination>"
	else
		find . -type f -name "$search" -exec mv -fv '{}' "$destination" ';'
	fi
}

# returns the active git branch - this is used in rewrite_bash_prompt()
git_branch()
{
	git branch 2>/dev/null | grep '*' | sed 's/\* /:/'
}

# get filesize
get_filesizes()
{
	ls -laSh | grep -v ^d | awk '{print $5 "\t" $9}'
}

# performs a mysqldump through SSH, and stores it in the "backups" folder on your desktop
get_sql_dump()
{
	project=$1
	ssh_hostname=$2
	mysql_database=$3
	mysql_username=$4
	mysql_host=$5
	datefolder=$(date +'%d-%m')
	
	if [[ $project == "" ]] || [[ $ssh_hostname == "" ]] || [[ $mysql_database == "" ]]
	then
		echo "usage: get_sql_dump <project> <ssh_hostname> <mysql_database> <*mysql_username> <*mysql_host>"
	else
		if [[ $mysql_username != "" ]]
		then
			mysql_username="-u $mysql_username -p "
		fi

		if [[ $mysql_host != "" ]]
		then
			mysql_host=" -h $mysql_host"
		fi
		
		# Prepare the backup dir if it does not exist yet
		backup_dir=${HOME}/Desktop/backups/$project/$datefolder
		if [[ ! -d $backup_dir ]]
		then
		    echo "Creating backup dir ($backup_dir)"
    		mkdir -p $backup_dir
		fi

		# Give the user a warning if the file already exists		
		if [[ -f $backup_dir/$ssh_hostname.tar ]]
		then
		    echo -e "WARNING: Backup file already exists ($backup_dir/$ssh_hostname.tar).\nContinue? (y/n)"
		    read proceed
		    
		    if [[ $proceed != "y" ]]
		    then
		    	echo "Exiting..."
		    	return
		    fi
		fi

		# Because the scope of all our vars is local, we have to put them in a backticked string to execute them with parsed vars
		echo "Executing mysqldump on the server..."
		prepare_dump=`ssh $ssh_hostname "mysqldump $mysql_username$mysql_database$mysql_host > $ssh_hostname.sql" > /dev/null`
		
		# create the tarball
		echo "Creating tarball..."
		create_tarball=`ssh $ssh_hostname "tar -cvzf $ssh_hostname.tar $ssh_hostname.sql && rm $ssh_hostname.sql" > /dev/null`
		
		# Prepare the backup dir and transfer the tarball
		echo "Transferring tarball to $backup_dir/$ssh_hostname.tar"
		rsync -ur $ssh_hostname:$ssh_hostname.tar $backup_dir/$ssh_hostname.tar > /dev/null
		
		# See the comments above
		echo "Cleaning up the server..."
		clear_server=`ssh $ssh_hostname "rm $ssh_hostname.tar"`

		cd $backup_dir
		echo "Done."
	fi 	
}

# replaces a local mysql database with the specified one
mysql_replace()
{
	database=$1
	sql_file=$2
	
	if [[ "$database" == "" ]] || [[ "$sql_file" == "" ]]
	then
		echo "usage: mysql_replace <database> <sql_file>"
	else
		echo "Dropping and re-creating database '$database'"
		mysql $database -e "drop database $database; create database $database;"
		
		echo "Importing $sql_file ..."
		mysql $database < $sql_file
		
		echo "Done."
	fi 	
}

##################################################
# Fancy PWD display function
##################################################
# The home directory (HOME) is replaced with a ~
# The last pwdmaxlen characters of the PWD are displayed
# Leading partial directory names are striped off
# /home/me/stuff          -> ~/stuff               if username=me
# /usr/share/big_dir_name -> ../share/big_dir_name if pwdmaxlen=20
##################################################
rewrite_pwd()
{
	# how many characters of the $PWD should be kept
	local pwdmaxlen=25

	# indicate that there has been dir truncation
	local trunc_symbol=".."
	local dir=${PWD##*/}

	pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))

	NEW_PWD=${PWD/$HOME/~}

	local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))

	if [ ${pwdoffset} -gt "0" ]
		then
		NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
		NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
	fi
}

# rewrites the PS1 bash prompt var
rewrite_bash_prompt()
{
	local NONE='\[\033[0m\]'    # unsets color to term's fg color

	# regular colors
	local K='\[\033[0;30m\]'    # black
	local R='\[\033[0;31m\]'    # red
	local G='\[\033[0;32m\]'    # green
	local Y='\[\033[0;33m\]'    # yellow
	local B='\[\033[0;34m\]'    # blue
	local M='\[\033[0;35m\]'    # magenta
	local C='\[\033[0;36m\]'    # cyan
	local W='\[\033[0;37m\]'    # white
				    
	# empahsized (bolded) colors
	local EMK='\[\033[1;30m\]'
	local EMR='\[\033[1;31m\]'
	local EMG='\[\033[1;32m\]'
	local EMY='\[\033[1;33m\]'
	local EMB='\[\033[1;34m\]'
	local EMM='\[\033[1;35m\]'
	local EMC='\[\033[1;36m\]'
	local EMW='\[\033[1;37m\]'

	# background colors
	local BGK='\[\033[40m\]'
	local BGR='\[\033[41m\]'
	local BGG='\[\033[42m\]'
	local BGY='\[\033[43m\]'
	local BGB='\[\033[44m\]'
	local BGM='\[\033[45m\]'
	local BGC='\[\033[46m\]'
	local BGW='\[\033[47m\]'

	local UC=$C                 # username's color
	[ $UID -eq "0" ] && UC=$R   # root's color

	# rewrite prompt
	PS1="${G}\u@\h> \${NEW_PWD} \\$ ${NONE}\n\$ "
}

# adds ~/.ssh/config to the ssh autocomplete
ssh_load_autocomplete()
{
	complete -W "$(awk '/^\s*Host\s*/ { sub(/^\s*Host /, ""); print; }' ~/.ssh/config)" ssh
}

# export all changed files between the given revision and HEAD, to a given location
svn_export_changed_files()
{
	tarfile=$1
	start_rev=$2
	end_rev=$3

	if [[ "$end_rev" == "" ]]; then
		 end_rev='HEAD'
	fi
	
	if [[ "$tarfile" == "" ]] || [[ "$start_rev" == "" ]]
	then
		echo "usage: svn_export_changed_files <tarfile> <start_rev> <*end_rev>"
	else
		svn diff -r "$start_rev":"$end_rev" --summarize | 
		awk '{if ($1 != "D") print $2}'| 
		xargs  -I {} tar -rvf "$tarfile" {}
	fi
}

# takes a screenshot and uploads it to my hosting
take_screenshot()
{
	filename="$(date +%Y-%m-%d-%H-%M-%S).png"

	screencapture -ix ~/Desktop/$filename && 
	scp ~/Desktop/$filename davelens.be:screenshots/$filename
	echo "http://code.davelens.be/screenshots/$filename" | pbcopy
	rm -rf ~/Desktop/$filename
}

# toggles between hiding/showing of hidden files
toggle_hidden_files()
{
	value="$(defaults read com.apple.finder AppleShowAllFiles)"
	
	if [[ "$value" == "FALSE" ]]; then
		newValue="TRUE"
	else
		newValue="FALSE"
	fi
	
	defaults write com.apple.finder AppleShowAllFiles $newValue
	killall Finder
	echo "AppleShowAllFiles is now $newValue."
}


# Execute methods

PROMPT_COMMAND=rewrite_pwd
rewrite_bash_prompt

# add my personal.id_rsa key to the SSH agent (needed for Github and possibly other connections as well)
ssh-add ~/.ssh/personal.id_rsa

# adds ~/.ssh/config to the ssh autocomplete
ssh_load_autocomplete

# initialize rbenv
eval "$(rbenv init -)"
