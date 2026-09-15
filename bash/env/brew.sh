###############################################################################
# Env settings and exports related to [Homebrew](https://brew.sh/).
# Primarily used to bootstrap BREW_PATH and HOMEBREW_REPOSITORY.
# Intended to work on both macos and linux.
###############################################################################

# On macos w/ Apple silicon chips (on Intel chips it used to be in /usr/local).
if [[ -z ${BREW_PATH:-} && -x /opt/homebrew/bin/brew ]]; then
  BREW_PATH=/opt/homebrew
fi

# Linuxbrew got merged into Homebrew in 2019, but the folder name persists.
if [[ -z ${BREW_PATH:-} && -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  BREW_PATH=/home/linuxbrew/.linuxbrew
fi

if [ -n "${BREW_PATH:-}" ]; then
  export BREW_PATH

  # Don't force an update of all packages when target upgrading single packages.
  export HOMEBREW_NO_AUTO_UPDATE="${HOMEBREW_NO_AUTO_UPDATE-1}"

  # If HOMEBREW_REPOSITORY isn't set, brew's bash completion won't work properly
  # (see the GH issue [here](https://github.com/orgs/Homebrew/discussions/4227))
  export HOMEBREW_REPOSITORY="${HOMEBREW_REPOSITORY:-$BREW_PATH}"
  export HOMEBREW_PREFIX="${HOMEBREW_PREFIX-$BREW_PATH}"

  # Homebrew typically allows you to install specific major versions of a
  # database. At the time of writing this is mysql@8.4 or postgresql@18, but
  # I don't want to have to edit my dotfiles every time this changes.
  # Inspect installed opt links without executing the package manager.
  for _dots_pkg in "$BREW_PATH"/opt/mysql* "$BREW_PATH"/opt/postgresql*; do
    [[ -d $_dots_pkg ]] || continue
    case ${_dots_pkg##*/} in
      mysql*) _DOTS_MYSQL_VERSION=${_dots_pkg##*/} ;;
      postgresql*) _DOTS_POSTGRESQL_VERSION=${_dots_pkg##*/} ;;
    esac
  done
  unset _dots_pkg
  export _DOTS_MYSQL_VERSION _DOTS_POSTGRESQL_VERSION

  # Ensure brew-installed bash versions as our active shell.
  [ -f "$BREW_PATH"/bin/bash ] && export SHELL="${SHELL-$BREW_PATH/bin/bash}"

  # mise uses kerl under the hood for Erlang; this makes sure that it uses
  # Homebrew's openssl version when compiling from source.
  if [ -d "$BREW_PATH/opt/openssl@3" ]; then
    KERL_CONFIGURE_OPTIONS="${KERL_CONFIGURE_OPTIONS---with-ssl=$BREW_PATH/opt/openssl@3}"
    export KERL_CONFIGURE_OPTIONS
  fi

  # Specific compiler & pkgconf helpers
  _add_to_var() {
    local var="$1" val="$2" sep="${3:- }"
    if [[ "${!var-}" != *"$val"* ]]; then
      export "$var"="${!var:+${!var}$sep}$val"
    fi
  }

  _add_brew_pkg_to_compile_flags() {
    local pkg="$BREW_PATH/opt/$1"
    [[ -n $1 ]] && [ -d "$pkg" ] || return 0
    _add_to_var LDFLAGS "-L$pkg/lib"
    _add_to_var CPPFLAGS "-I$pkg/include"
    _add_to_var PKG_CONFIG_PATH "$pkg/lib/pkgconfig" ":"
  }

  _add_brew_pkg_to_compile_flags "${_DOTS_MYSQL_VERSION:-}"
  _add_brew_pkg_to_compile_flags "${_DOTS_POSTGRESQL_VERSION:-}"

  unset -f _add_to_var _add_brew_pkg_to_compile_flags
fi
