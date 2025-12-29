###############################################################################
# Env settings and exports related to [Homebrew](https://brew.sh/).
# Primarily used to bootstrap BREW_PATH and HOMEBREW_REPOSITORY.
###############################################################################

# On macos w/ Apple silicon chips (on Intel chips it used to be in /usr/local).
if [ -f /opt/homebrew/bin/brew ]; then
  BREW_PATH=$(/opt/homebrew/bin/brew --prefix)
fi

# Linuxbrew got merged into Homebrew in 2019, but the folder name persists.
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  BREW_PATH=$(/home/linuxbrew/.linuxbrew/bin/brew --prefix)
fi

if [ -n "$BREW_PATH" ]; then
  export BREW_PATH

  # Don't force an update of all packages when target upgrading single packages.
  export HOMEBREW_NO_AUTO_UPDATE=1

  # If HOMEBREW_REPOSITORY isn't set, brew's bash completion won't work properly
  # (see the GH issue [here](https://github.com/orgs/Homebrew/discussions/4227))
  if [ -z "$HOMEBREW_REPOSITORY" ]; then
    eval "$("$BREW_PATH/bin/brew" shellenv | grep -v ^PATH)"
  fi

  # Homebrew typically allows you to install specific major versions of a
  # database. At the time of writing this is mysql@8.4 or postgresql@18, but
  # I don't want to have to edit my dotfiles every time this changes.
  _DOTS_MYSQL_VERSION=$(brew list | grep mysql)
  _DOTS_POSTGRESQL_VERSION=$(brew list | grep postgres)
  export _DOTS_MYSQL_VERSION _DOTS_POSTGRESQL_VERSION

  # Ensure brew-installed bash versions as our active shell.
  [ -f "$BREW_PATH"/bin/bash ] && export SHELL="$BREW_PATH/bin/bash"

  # mise uses kerl under the hood for Erlang; this makes sure that it uses
  # Homebrew's openssl version when compiling from source.
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
    [[ -n $1 ]] && [ -d "$pkg" ] || return 0
    _add_to_var LDFLAGS "-L$pkg/lib"
    _add_to_var CPPFLAGS "-I$pkg/include"
    _add_to_var PKG_CONFIG_PATH "$pkg/lib/pkgconfig" ":"
  }

  _add_brew_pkg_to_compile_flags "$_DOTS_MYSQL_VERSION"
  _add_brew_pkg_to_compile_flags "$_DOTS_POSTGRESQL_VERSION"

  unset -f _add_to_var _add_brew_pkg_to_compile_flags
fi
