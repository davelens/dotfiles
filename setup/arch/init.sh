#!/usr/bin/env bash
set -e

"$DOTFILES_REPO_HOME/setup/arch/preflight.sh"
"$DOTFILES_REPO_HOME/setup/arch/init.d/power-profiles.sh"
"$DOTFILES_REPO_HOME/setup/gnupg/init.sh"
"$DOTFILES_REPO_HOME/setup/mise/init.sh"
"$DOTFILES_REPO_HOME/setup/cargo/init.sh"
"$DOTFILES_REPO_HOME/setup/gnome/init.sh"

utility arch bundle --update
"$DOTFILES_REPO_HOME/setup/arch/init.d/kanata.sh"
"$DOTFILES_REPO_HOME/setup/arch/init.d/albert.sh"
"$DOTFILES_REPO_HOME/setup/arch/init.d/mariadb.sh"
