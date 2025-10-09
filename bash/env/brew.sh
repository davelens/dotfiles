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
  #
  # I leave out the PATH override though. Homebrew wants its shims to be at the
  # top of the list, but we want ASDF to take precedence.
  if [ -z "$HOMEBREW_REPOSITORY" ]; then
    eval "$("$BREW_PATH/bin/brew" shellenv | grep -v ^PATH)"
  fi
fi
