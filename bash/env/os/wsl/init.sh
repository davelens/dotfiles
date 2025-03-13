# Where we're going, we don't need GUIs.
export WSL2_GUI_APPS_ENABLED="0"

###############################################################################
# Additional settings/overrides to maintain behaviour across my machines.
###############################################################################
source "$DOTFILES_PATH/bash/env/os/wsl/wait-for-user.sh"
source "$DOTFILES_PATH/bash/env/os/wsl/bootstrap-ssh-agent.sh"
source "$DOTFILES_PATH/bash/env/os/wsl/aliases.sh"
source "$DOTFILES_PATH/bash/env/os/wsl/misc.sh"
