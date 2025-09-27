###############################################################################
# ENCRYPTED SALT / BITWARDEN (WIP)
###############################################################################
# Salt is used to encrypt and decrypt sensitive values or files with a passkey.
#
# TODO: Add a mild warning when the salt file hasn't changed for a while.

# If the salt file is gone, we don't want to keep the old value.
if [ ! -f "$DOTFILES_SALT_PATH" ]; then
  unset DOTFILES_SALT
  unset BW_SESSION
fi

###############################################################################
# TODO: There is bug with salt generation where undesired characters end
# up as part of the salt. I think forward slashes are the main issue.
# As a potential solution, I should continue generating a salt until a "clean"
# value is born. That should solve all lingering inconsistencies with salt
# generation!
###############################################################################

#
# Outside of tmux, we ask for the salt passkey once and store it in an ENV var.
# Because I'm in tmux 24/7 I have access to DOTFILES_SALT in all my panes and
# windows.
#
# This way we don't need to enter our Bitwarden master password beyond the
# first time, ever.
#
# TODO: This is functional but I've disabled it for now.
#
# The issue is that ENV vars (ie. DOTFILES_SALT) don't persist outside of
# subshells.
#
# I might have to ask for the passkey to the salt every single time. It won't
# defeat the purpose of having a salt
#
# `utility misc screenshot` would ask for a passkey every time, for instance.
#
#if [[ -z $TMUX ]]; then
#salt=$(salt current)

#if [[ $? -eq 0 ]]; then
#export DOTFILES_SALT="$salt"

#if [[ -z $BW_SESSION ]]; then
#export BW_SESSION="$(utility misc bitwarden unlock)"
#fi
#else
#print_status -i error "Encrypted salt not ready; possibly wrong passkey."
#fi
#fi
