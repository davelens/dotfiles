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
fi
