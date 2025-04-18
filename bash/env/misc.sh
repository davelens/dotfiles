##############################################################################
# Env settings and exports I couldn't quite (yet) fit into other categories.
##############################################################################

# dvim is what loads in my nvim config
# https://github.com/davelens/dotvim
export EDITOR="dvim"

# Stop checking shellmail for new messages
unset MAILCHECK

# So software can pick up and load this entire config.
export SHELL="$BREW_PATH/bin/bash"

# This makes it so `gh` will use a bash shell running my default editor.
export GH_EDITOR="bash -c '$EDITOR'"

# Make ls & grep pretty
export CLICOLOR=1

# PAGER is the path to the program used to list the contents of files through
export PAGER='less --quit-if-one-screen --no-init --ignore-case --RAW-CONTROL-CHARS --quiet --dumb'

# Erlang history settings to have a cmd history in iex sessions.
export ERL_AFLAGS="-kernel shell_history enabled"

# Silences the default confirmation feedback for Slackadays/Clipboard.
export CLIPBOARD_SILENT="1"

# MySQL 8.4 compilation flags
LDFLAGS="$LDFLAGS -L$BREW_PATH/opt/mysql@8.4/lib"
CPPFLAGS="$CPPFLAGS -I$BREW_PATH/opt/mysql@8.4/include"
export PKG_CONFIG_PATH="$BREW_PATH/opt/mysql@8.4/lib/pkgconfig"

# This is to prevent punycode deprecation logging to stderr, in particular.
export NODE_OPTIONS="--no-deprecation"

# Go lang work dir
export GOPATH="$HOME/.go"

# This makes sure asdf can configure Erlang with Homebrew's openssl pkg.
KERL_CONFIGURE_OPTIONS="--with-ssl=$(brew --prefix openssl)"
export KERL_CONFIGURE_OPTIONS
