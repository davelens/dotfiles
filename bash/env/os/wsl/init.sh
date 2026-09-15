# Windows integration is an explicit selection, never a boot repair.
source "$DOTFILES_REPO_HOME/bash/env/os/wsl/misc.sh"
if dots_selected wsl-integration && [[ -z ${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-} ]]; then
  source "$DOTFILES_REPO_HOME/bash/env/os/wsl/aliases.sh"
fi
