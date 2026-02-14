###############################################################################
# Env settings and configuration related to bash's completion.
###############################################################################

# shellcheck disable=SC1090,SC1091

# Load system bash-completion (Arch, Debian, etc,...).
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi

# Load Homebrew-installed completions (macos or Linuxbrew).
# Note: bash_completion.sh handles completion.d lazily, so we don't loop manually.
if [[ -n "$BREW_PATH" ]] && [[ -r "$BREW_PATH"/etc/profile.d/bash_completion.sh ]]; then
  source "$BREW_PATH"/etc/profile.d/bash_completion.sh
fi

# Enable completion for commands run via `sudo`.
complete -cf sudo

# Source all downloaded completion files.
for file in "$DOTFILES_REPO_HOME"/bash/env/completions/*.bash; do
  [[ -r $file ]] && source "$file"
done
unset file

# Set up fzf key bindings and fuzzy completion for existing commands.
# NOTE: This needs to be called AFTER other bash completions are loaded.
# fzf actually picks up on them and preserves original bindings.
command -v fzf >/dev/null && eval "$(fzf --bash)"
