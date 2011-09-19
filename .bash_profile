# Settings
# /opt/local binaries
if [[ ${PATH} != */opt/local/bin* ]] ; then
	export PATH="${PATH}:/opt/local/bin"
fi
if [[ ${PATH} != */opt/local/sbin* ]] ; then
	export PATH="${PATH}:/opt/local/sbin"
fi

# MAMP binaries
if [[ ${PATH} != */Applications/MAMP/Library/bin* ]] ; then
	export PATH="${PATH}:/Applications/MAMP/Library/bin"
fi

# XCode X11 binaries
if [[ ${PATH} != */usr/X11/bin* ]] ; then
	export PATH="${PATH}:/usr/X11/bin"
fi

# Aliases
if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi


# Methods

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
	PS1="${G}\u@local:$(git_branch)> \${NEW_PWD} \\$ ${NONE}\n\$ "
}

# returns the active git branch - this is used in rewrite_bash_prompt()
git_branch()
{
	git branch 2>/dev/null | grep '*' | sed 's/\* //'
}

# get filesize
get_filesizes()
{
	ls -laSh | grep -v ^d | awk '{print $5 "\t" $9}'
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

# performs a mysqldump through SSH, and stores it in the "backups" folder on your desktop
get_sql_dump()
{
	project=$1
	ssh_hostname=$2
	mysql_username=$3
	mysql_database=$4
	mysql_host=$5
	datefolder=$(date +'%d-%m')
	
	if [[ "$project" == "" ]] || [[ "$ssh_hostname" == "" ]] || [[ "$mysql_username" == "" ]] || [[ "$mysql_database" == "" ]]
	then
		echo "usage: get_sql_dump <project> <ssh_hostname> <mysql_username> <mysql_database> <*mysql_host>"
	else
		backup_dir=${HOME}/Desktop/backups/$project/$datefolder

		if [[ "$mysql_host" != "" ]]
		then
			mysql_host="-h $mysql_host"
		fi

		mkdir -p $backup_dir
		cd $backup_dir
		ssh $ssh_hostname mysqldump -u $mysql_username -p $mysql_database $mysql_host > $ssh_hostname.sql
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

# adds ~/.ssh/config to the ssh autocomplete
ssh_load_autocomplete()
{
	complete -W "$(awk '/^\s*Host\s*/ { sub(/^\s*Host /, ""); print; }' ~/.ssh/config)" ssh
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


# Execute methods

PROMPT_COMMAND=rewrite_pwd
rewrite_bash_prompt

# add my personal.id_rsa key to the SSH agent (needed for Github and possibly other connections as well)
ssh-add ~/.ssh/personal.id_rsa

# adds ~/.ssh/config to the ssh autocomplete
ssh_load_autocomplete

# show the status of our config repo in the username dir
git st
