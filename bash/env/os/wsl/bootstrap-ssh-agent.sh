###############################################################################
# A fix for the wonky Arch-on-WSL2 ssh-agent behaviour I've had.
###############################################################################

# Bootstrap an ssh-agent and add your default key to it.
if [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ] || ! pgrep -u "$USER" ssh-agent >/dev/null; then
  export DOTFILES_SSH_AUTH_SOCK="$DOTFILES_STATE_HOME/tmp/ssh-agent.socket"
  export SSH_AUTH_SOCK="$DOTFILES_SSH_AUTH_SOCK"
  [ -S "$SSH_AUTH_SOCK" ] && rm -f "$SSH_AUTH_SOCK"
  eval "$(ssh-agent -s -a "$SSH_AUTH_SOCK")"
  echo "$SSH_AGENT_PID" >>"$XDG_RUNTIME_DIR/ssh-agent.pid"
fi

# Does two things:
# 1. Make sure keychain doesn't create files in the home dir
# 2. Store / keep alive our initialized ssh-agent
keychain --ssh-allow-forwarded id_rsa --absolute --dir "${XDG_RUNTIME_DIR}keychain" --quiet
