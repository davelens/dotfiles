########################################################################
# $PATH configuration
########################################################################

# List the directories we want to add to the PATH variable, if they exist.
# The order is important, as the first directory in the list will be the first
# one to be searched (and used) for binaries.
#
# So Homebrew binaries are typically installed in the Cellar/ directory.
# If a package has multiple possible versions however, it will get symlinked
# into the opt/ directory (e.g. python@3, mysql@8.4, ...).
#
# We *could* load in all homebrew binaries in opt/, but that would be a LOT
# of binaries added to $PATH one by one. That can't be healthy for the shell,
# and at the very least it's not readable for humans. Instead, we add specific
# packages like mysql to $PATH manually.
#
# If you want to load in all of them however, you can use this:
#
#   $BREW_PATH/opt/*/bin # All Homebrew binaries
#
paths_to_add=(
  "${ASDF_DATA_DIR:-$XDG_DATA_HOME/asdf}"/shims # Always prefer asdf shims
  "$XDG_BIN_HOME"                               # User-made and controlled binaries
  /usr/local/{,s}bin                            # Docker, npm, Private Internet Access,...
  /usr/{,s}bin                                  # User specific system binaries. A *lot* of them.
  /{,s}bin                                      # *nix shells and binaries, and basic commands like ls, cp, echo,...
)

if [ -n "$BREW_PATH" ]; then
  paths_to_add+=(
    "$BREW_PATH"/{,s}bin           # unbound in sbin/, most Homebrew binaries in bin/
    "$BREW_PATH"/opt/mysql@8.4/bin # Brew wants you to use `brew services`, but I want direct access
  )
fi

if [ "$("$XDG_BIN_HOME/os")" == "windows" ] >/dev/null; then
  paths_to_add+=(
    /mnt/c/Windows/System32
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0
    /mnt/c/Windows/SysWOW64
  )
fi

[ -d $HOME/.cargo ] && paths_to_add+=("$HOME"/.cargo/bin)

# Now implode everything into the new PATH variable.
printf -v PATH "%s:" "${paths_to_add[@]}"
export PATH="${PATH%:}"
