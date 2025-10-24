###############################################################################
# Env settings and exports I couldn't quite (yet) fit into other categories.
###############################################################################

# dvim is what loads in my nvim config
# https://github.com/davelens/dotvim
export EDITOR="dvim"

# Stop checking shellmail for new messages
unset MAILCHECK

# This makes it so `gh` will use a bash shell running my default editor.
export GH_EDITOR="bash -c '$EDITOR'"

# Make ls & grep pretty
export CLICOLOR=1

# PAGER is the path to the program used to list the contents of files through
export PAGER='less'

# Erlang history settings to have a cmd history in iex sessions.
export ERL_AFLAGS="-kernel shell_history enabled"

# Silences the default confirmation feedback for Slackadays/Clipboard.
export CLIPBOARD_SILENT="1"

# This is to prevent punycode deprecation logging to stderr, in particular.
export NODE_OPTIONS="--no-deprecation"

# Go lang work dir
export GOPATH="$HOME/.go"

# This makes sure asdf can configure Erlang.
if [ -n "$(which openssl)" ]; then
  KERL_CONFIGURE_OPTIONS="--with-ssl=$(which openssl)"
  export KERL_CONFIGURE_OPTIONS
fi

# Some Homebrew specific settings.
if [ -f "$BREW_PATH" ]; then
  # So we can load in brew-installed bash versions.
  [ -f "$BREW_PATH"/bin/bash ] && export SHELL="$BREW_PATH/bin/bash"

  # This makes sure asdf can configure Erlang with Homebrew's openssl pkg.
  KERL_CONFIGURE_OPTIONS="--with-ssl=$(brew --prefix openssl@3)"
  export KERL_CONFIGURE_OPTIONS

  # MySQL 8.4 compile flags
  if [ -n "$BREW_PATH" ]; then
    LDFLAGS="$LDFLAGS -L$BREW_PATH/opt/mysql@8.4/lib"
    CPPFLAGS="$CPPFLAGS -I$BREW_PATH/opt/mysql@8.4/include"
    export PKG_CONFIG_PATH="$BREW_PATH/opt/mysql@8.4/lib/pkgconfig"
  fi
fi
