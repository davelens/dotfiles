###############################################################################
# Executable PATH setup, shared by direct bootstrap and shell startup.
###############################################################################

# Preserve inherited host/toolchain paths, including empty entries. GNU paths
# must lead even when inherited PATH already contains them after BSD commands.
_dots_prefix=
for _dots_path in \
  "${BREW_PATH:+$BREW_PATH/opt/coreutils/libexec/gnubin}" \
  "${BREW_PATH:+$BREW_PATH/opt/gnu-sed/libexec/gnubin}" \
  "${BREW_PATH:+$BREW_PATH/bin}" "${BREW_PATH:+$BREW_PATH/sbin}" \
  "${BREW_PATH:+$BREW_PATH/opt/${_DOTS_MYSQL_VERSION:-mysql}/bin}" \
  "${BREW_PATH:+$BREW_PATH/opt/${_DOTS_POSTGRESQL_VERSION:-postgresql}/bin}" \
  "${CARGO_HOME:-$XDG_DATA_HOME/cargo}/bin" \
  "${NPM_DATA_HOME:-$XDG_DATA_HOME/npm}/bin" \
  "${DOTFILES_REPO_HOME:+$DOTFILES_REPO_HOME/bin}" \
  "${DOTFILES_REPO_HOME:+$DOTFILES_REPO_HOME/bin/autoload}" "$XDG_BIN_HOME"; do
  [[ -n $_dots_path && -d $_dots_path ]] || continue
  _dots_prefix+="$_dots_path:"
done
if [[ -n $_dots_prefix && ${PATH-} != "$_dots_prefix"* && ${PATH-} != "${_dots_prefix%:}" ]]; then
  PATH="${_dots_prefix%:}${PATH+:$PATH}"
fi
export PATH
unset _dots_prefix _dots_path

# Tool activation belongs to interactive startup, not path calculation.
