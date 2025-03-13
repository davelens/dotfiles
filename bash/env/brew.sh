########################################################################
# Env settings and exports related to [Homebrew](https://brew.sh/).
# Primarily used to bootstrap BREW_PATH and HOMEBREW_REPOSITORY.
########################################################################

# Don't force an update of all packages when target upgrading single packages.
export HOMEBREW_NO_AUTO_UPDATE=1

# Homebrew's location has changed over the years, and I still have several
# setups from different eras:
# On macos with M1 chips: /opt/homebrew
# On macos with Intel chips: /usr/local
# On *nix using Linuxbrew: /home/linuxbrew/.linuxbrew
[[ -f /opt/homebrew/bin/brew ]] && BREW_PATH=$(/opt/homebrew/bin/brew --prefix)
[[ -f /home/linuxbrew/.linuxbrew/bin/brew ]] && BREW_PATH=$(/home/linuxbrew/.linuxbrew/bin/brew --prefix)
[[ -f /usr/local/bin/brew ]] && BREW_PATH=$(/usr/local/bin/brew --prefix)
[[ -f /usr/bin/brew ]] && BREW_PATH=$(/usr/bin/brew --prefix)
export BREW_PATH

# If HOMEBREW_REPOSITORY isn't set properly, brew's bash autocompletion won't
# work properly [GH issue](https://github.com/orgs/Homebrew/discussions/4227).
#
# I leave out the PATH override though. Homebrew wants its shims to be at the
# top of the list, but we want ASDF to take precedence.
if [ -z "$HOMEBREW_REPOSITORY" ]; then
  eval "$("$BREW_PATH/bin/brew" shellenv | grep -v ^PATH)"
fi
