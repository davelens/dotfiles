alias clearcache='sudo dscacheutil -flushcache'
alias csh='configure_ssh_host'
alias fs='get_filesizes'
alias gsd='get_sql_dump'
alias his='history | grep'
alias ls='ls -G'
alias lsa='ls -hal'
alias mr='mysql_replace'
alias se='svn_export_changed_files'
alias ss='take_screenshot'

# dir size in current dir
alias ds='du -sh */'

# remove all .svn folders recursively in current dir
alias purgesvn="find . -type d -name '.svn' -exec rm -rf '{}' '+' "