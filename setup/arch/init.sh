#!/usr/bin/env bash
set -e

"$DOTFILES_REPO_HOME/setup/arch/preflight.sh"
"$DOTFILES_REPO_HOME/setup/mise/init.sh"
"$DOTFILES_REPO_HOME/setup/cargo/init.sh"
"$DOTFILES_REPO_HOME/setup/arch/init.d/kanata.sh"
"$DOTFILES_REPO_HOME/setup/arch/init.d/albert.sh"
