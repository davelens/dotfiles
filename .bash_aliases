alias clearcache='sudo dscacheutil -flushcache'
alias csh='configure_ssh_host'
alias fs='get_filesizes'
alias gf='gather_files'
alias gsd='get_sql_dump'
alias his='history | grep'
alias ls='ls -G'
alias lsa='ls -halG'
alias mr='mysql_replace'
alias se='svn_export_changed_files'
alias tss='take_screenshot'
alias ss='osascript ~/.bin/hide_terminal.scpt && tss'
alias thf='toggle_hidden_files'
alias webview='git instaweb --httpd=webrick'

# dir size in current dir
alias ds='du -sh */'

# remove all .svn folders recursively in current dir
alias purgesvn="find . -type d -name '.svn' -exec rm -rf '{}' '+' "

# the Fork Tool
alias ft=/Users/dave/.bin/forktool/ForkTool/ft.sh
