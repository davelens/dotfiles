###############################################################################
# Env settings and configuration related to bash's completion.
###############################################################################

# shellcheck disable=SC1090,SC1091

# Load system bash-completion (Arch, Debian, etc,...).
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
fi

# Load Homebrew-installed completions (macos or Linuxbrew).
if command -v brew >/dev/null; then
  if [[ -r "$BREW_PATH"/etc/profile.d/bash_completion.sh ]]; then
    source "$BREW_PATH"/etc/profile.d/bash_completion.sh
  fi

  if [[ -d "$BREW_PATH"/etc/bash_completion.d/ ]]; then
    for completion in "$BREW_PATH"/etc/bash_completion.d/*; do
      [[ -r "$completion" ]] && source "$completion"
    done
    unset completion
  fi
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
