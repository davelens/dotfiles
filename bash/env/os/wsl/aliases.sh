###############################################################################
# Some commands need an override to maintain behaviour between my machines.
###############################################################################

alias gls='ls' # We already use GNU ls in bash/aliases.sh
alias pbcopy="clip.exe"
alias pbpaste="powershell.exe -command 'Get-Clipboard' | head -n -1"
