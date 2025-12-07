###############################################################################
# $PATH configuration
###############################################################################

# Adds all necessary directories to the PATH variable, if they exist.
#
# The order is important, as the first directory in the list will be the first
# one to be searched (and used) for binaries. The order is:
#
#   Package managers > user made bins > system bins > everything else

# About mysql@8.4: Homebrew binaries are typically installed in the Cellar/
# directory. If a package has multiple possible versions however, it will get
# symlinked into the opt/ directory (e.g. python@3, mysql@8.4, ...).
#
# We *could* load in all homebrew binaries in opt/, but that would be a LOT
# of binaries added to $PATH one by one. That can't be healthy, but here's how
# you'd do it:
#
#   $BREW_PATH/opt/*/bin
#
# Another alternative is to set up our own symlinks into our $XDG_BIN_HOME.
# This would benefit from a helper that targets a source dir and symlinks all
# executables into a target dir. But that's a lot of effort for a single tool.
#
# For now though, I add specific packages like mysql to $PATH manually.

paths_to_add=()

if [ -d "$ASDF_DATA_DIR" ]; then
  paths_to_add+=("${ASDF_DATA_DIR:-$XDG_DATA_HOME/asdf}"/shims)
fi

if [ -d "$CARGO_HOME" ]; then
  paths_to_add+=("${CARGO_HOME:-$XDG_DATA_HOME/cargo}"/bin)
fi

if [ -f "$NPM_CONFIG_USERCONFIG" ]; then
  paths_to_add+=("$XDG_DATA_HOME"/npm/bin)
fi

# Brew needs to go before /usr/bin e.a.
if [ -n "$BREW_PATH" ]; then
  paths_to_add+=(
    "$BREW_PATH"/{,s}bin               # Default bin files (mount, unbound,...)
    "$BREW_PATH"/opt/mysql@8.4/bin     # mysqldump, mysql.server,...
    "$BREW_PATH"/opt/postgresql@18/bin # pg_dump, psql,...
  )
fi

# User + system defined
paths_to_add+=(
  "$XDG_BIN_HOME"    # User-made and controlled binaries
  /usr/local/{,s}bin # Docker, npm, kubernetes,...
  /usr/{,s}bin       # User specific system binaries. A *lot* of them.
  /{,s}bin           # *nix shells, bins, and basic commands like ls, cp,...
)

# Add all system32 executables on WSL.
if [ "$("$XDG_BIN_HOME"/os 2>/dev/null)" == "windows" ]; then
  paths_to_add+=(
    /mnt/c/Windows/System32
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0
    /mnt/c/Windows/SysWOW64
  )
fi

# Now implode everything into the new PATH variable.
printf -v PATH "%s:" "${paths_to_add[@]}"
export PATH="${PATH%:}"
