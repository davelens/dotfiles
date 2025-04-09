# Download the iTerm2 shell integration file and place it in the completions dir.
if [ ! -f "$DOTFILES_REPO_HOME/bash/env/autocompletions/iterm2_shell_integration.bash" ]; then
  curl -L https://iterm2.com/shell_integration/bash \
    -o "$DOTFILES_REPO_HOME/bash/env/autocompletions/iterm2_shell_integration.bash"
fi

###############################################################################
# Additional settings/overrides to maintain behaviour across my machines.
###############################################################################
source "$DOTFILES_REPO_HOME/bash/env/os/macos/aliases.sh"
source "$DOTFILES_REPO_HOME/bash/env/os/macos/commands.sh"
