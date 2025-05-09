########################################################################
# Env settings and configuration related to bash's completion.
########################################################################

# Set up fzf key bindings and fuzzy completion
[[ ! $(which fzf) ]] && eval "$(fzf --bash)"

# Load brew's bash_completion, if available.
if command -v brew >/dev/null; then
  if [ -r "$BREW_PATH"/etc/profile.d/bash_completion.sh ]; then
    source "$BREW_PATH"/etc/profile.d/bash_completion.sh
  fi

  if [ -d "$BREW_PATH"/etc/bash_completion.d/ ]; then
    for completion in "$BREW_PATH"/etc/bash_completion.d/*; do
      [ -r "$completion" ] && source "$completion"
    done
    unset completion
  fi
fi

# Source all downloaded completion files.
for file in "$DOTFILES_REPO_HOME"/bash/env/completions/*.bash; do
  [ -r "$file" ] && source "$file"
done
unset file
