# Settings
export PATH="${PATH}:/opt/local/bin:/opt/local/sbin:/opt/local/git:/Applications/MAMP/Library/bin"


# Aliases
alias lsa='ls -hal'
alias his='history | grep'
alias ml='mysql -u root -p'


# file size in current dir
alias fs='ls -ltraSh | grep -v ^d'

# dir size in current dir
alias ds='du -sh */'

# remove all .svn folders recursively in current dir
alias purgesvn="find . -type d -name '.svn' -exec rm -rf '{}' '+' "


# SSH keys to add - I generally don't use an id_rsa file, so add/delete this at your leisure
ssh-add ~/.ssh/github.id_rsa


# Methods

##################################################
# Fancy PWD display function
##################################################
# The home directory (HOME) is replaced with a ~
# The last pwdmaxlen characters of the PWD are displayed
# Leading partial directory names are striped off
# /home/me/stuff          -> ~/stuff               if USER=me
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

	local UC=$C                 # user's color
	[ $UID -eq "0" ] && UC=$R   # root's color

	# rewrite prompt
	PS1="${G}\u@local:$(git_branch)> \${NEW_PWD} \\$ ${NONE}\n\$ "
}

# returns the active git branch - this is used in rewrite_bash_prompt()
git_branch()
{
	git branch 2>/dev/null | grep '*' | sed 's/\* //'
}

# export all changed files between the given revision and HEAD, to a given location
svnecf()
{
	tarfile=$1
	start_rev=$2
	end_rev=$3

	if [[ "$end_rev" == "" ]]; then
		 end_rev='HEAD'
	fi 

	svn diff -r "$start_rev":"$end_rev" --summarize | 
	awk '{if ($1 != "D") print $2}'| 
	xargs  -I {} tar -rvf "$tarfile" {}
}


# Execute methods
PROMPT_COMMAND=rewrite_pwd
rewrite_bash_prompt
git st
