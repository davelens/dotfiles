# Reuse current/forwarded agents. Identity selection belongs to SSH/ssh-add.
[[ $- == *i* ]] || return 0
[[ -z ${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-} ]] || return 0
[[ ${DOTS_OS:-} != macos && $OSTYPE == linux* ]] || return 0

_dots_agent_status=2
if [[ -n ${SSH_AUTH_SOCK:-} ]]; then
  type -P ssh-add >/dev/null || { unset _dots_agent_status; return 0; }
  ssh-add -l >/dev/null 2>&1 && _dots_agent_status=0 || _dots_agent_status=$?
fi
if (( _dots_agent_status <= 1 )); then
  unset _dots_agent_status
  return 0
fi
unset _dots_agent_status
type -P keychain >/dev/null || return 0

# No runtime-dir requirement, key list, SSH-file rewrite, or unmanaged agent.
_dots_keychain="$XDG_STATE_HOME/dots/keychain"
if [[ ! -L $XDG_STATE_HOME/dots && ! -L $_dots_keychain ]] &&
  (umask 077; mkdir -p -- "$_dots_keychain") 2>/dev/null &&
  [[ -O $XDG_STATE_HOME/dots && -O $_dots_keychain ]] &&
  chmod 700 -- "$XDG_STATE_HOME/dots" "$_dots_keychain" 2>/dev/null; then
  dots_optional_hook keychain --eval --quiet --ssh-allow-forwarded --absolute --dir "$_dots_keychain" || :
fi
unset _dots_keychain
