###############################################################################
# Env settings and exports I couldn't quite (yet) fit into other categories.
###############################################################################

# dvim is what loads in my nvim config.
# https://github.com/davelens/dotvim
export EDITOR="dvim"

# Stop checking shellmail for new messages.
unset MAILCHECK

# This makes it so `gh` will use a bash shell running my default editor.
export GH_EDITOR="$EDITOR"

# Make ls & grep pretty.
export CLICOLOR=1

# PAGER is the path to the program used to list the contents of files through.
export PAGER='less'

# MANPAGER is the program used to open and browse manuals.
export MANPAGER="$EDITOR +Man!"

# Erlang history settings to have a cmd history in iex sessions.
export ERL_AFLAGS="-kernel shell_history enabled"

# Silences the default confirmation feedback for Slackadays/Clipboard.
export CLIPBOARD_SILENT="1"

# This is to prevent punycode deprecation logging to stderr, in particular.
export NODE_OPTIONS="--no-deprecation"
