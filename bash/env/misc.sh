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

# Some Homebrew specific settings.
if [ -d "$BREW_PATH" ]; then
  # Ensure brew-installed bash versions as our active shell.
  [ -f "$BREW_PATH"/bin/bash ] && export SHELL="$BREW_PATH/bin/bash"

  # This makes sure asdf can configure Erlang with Homebrew's openssl pkg.
  if [ -d "$BREW_PATH/opt/openssl@3" ]; then
    KERL_CONFIGURE_OPTIONS="--with-ssl=$(brew --prefix openssl@3)"
    export KERL_CONFIGURE_OPTIONS
  fi

  # Specific compiler & pkgconf helpers
  _add_to_var() {
    local var="$1" val="$2" sep="${3:- }"
    [[ "${!var}" != *"$val"* ]] && export "$var"="${!var:+${!var}$sep}$val"
  }

  _add_brew_pkg_to_compile_flags() {
    local pkg="$BREW_PATH/opt/$1"
    [ -d "$pkg" ] || return 0
    _add_to_var LDFLAGS "-L$pkg/lib"
    _add_to_var CPPFLAGS "-I$pkg/include"
    _add_to_var PKG_CONFIG_PATH "$pkg/lib/pkgconfig" ":"
  }

  _add_brew_pkg_to_compile_flags "$_DOTS_MYSQL_VERSION"
  _add_brew_pkg_to_compile_flags "$_DOTS_POSTGRESQL_VERSION"

  unset -f _add_to_var _add_brew_pkg_to_compile_flags
fi
