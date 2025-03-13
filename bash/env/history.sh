##############################################################################
# Env settings and exports related to the command history in bash.
##############################################################################

# When the command contains an invalid history operation (for instance when
# using an unescaped "!" (I get that a lot in quick e-mails and commit
# messages) or a failed substitution (e.g. "^foo^bar" when there was no "foo"
# in the previous command line), do not throw away the command line, but let me
# correct it.
shopt -s histreedit

# Append to the history file rather than overwriting
shopt -s histappend

# Make the history file go to infinity and beyond.
export HISTSIZE=
export HISTFILESIZE=

# When executing the same command twice or more in a row, only store it once.
export HISTCONTROL=ignoredups

# Keep track of the time the commands were executed.
# The xterm colour escapes require special care when piping; e.g. "| less -R".
export HISTTIMEFORMAT="${FG_BLUE}${FONT_BOLD}%Y/%m/%d %H:%M:%S${FONT_RESET} "

# let the history ignore the following commands
export HISTIGNORE="ls:lsa:ll:la:pwd:clear:h:j"

# Disable macos keeping separate history per session in ~/.bash_sessions.
export SHELL_SESSION_HISTORY=0
