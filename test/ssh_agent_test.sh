#!/usr/bin/env bash
set -e
project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-ssh-agent-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/config" XDG_DATA_HOME="$test_root/data"
export XDG_CACHE_HOME="$test_root/cache" XDG_STATE_HOME="$test_root/state" XDG_BIN_HOME="$test_root/bin"
export TMPDIR="$test_root/tmp"
unset XDG_RUNTIME_DIR
mkdir -p "$HOME/.ssh" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME" "$TMPDIR"
printf 'fixture private config sentinel\n' >"$HOME/.ssh/config"
bash=$(type -P bash)
for tool in bash mkdir chmod; do ln -s "$(type -P "$tool")" "$XDG_BIN_HOME/$tool"; done
export AGENT_LOG="$test_root/agent.log" KEYCHAIN_LOG="$test_root/keychain.log" PROJECT_ERR="$test_root/project.err"
export HELPERS="$project_root/bash/helpers.sh" SSH_ENV="$project_root/bash/env/ssh.sh"
cat >"$XDG_BIN_HOME/ssh-add" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$AGENT_LOG"
exit "$AGENT_STATUS"
SH
cat >"$test_root/keychain" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$KEYCHAIN_LOG"
[[ $* != *id_rsa* && $* != *id_ed25519* ]] || exit 99
printf 'export SSH_AUTH_SOCK="$XDG_STATE_HOME/dots/keychain/fixture-socket"\n'
SH
chmod +x "$XDG_BIN_HOME/ssh-add" "$test_root/keychain"

run_agent() {
  local interactive=$1 expected=$2
  local -a flags=()
  [[ $interactive == no ]] || flags=(-i)
  export EXPECTED_SOCK=$expected
  PATH="$XDG_BIN_HOME" "$bash" --noprofile --norc "${flags[@]}" -c '
    exec 2>"$PROJECT_ERR"
    source "$HELPERS"
    source "$SSH_ENV"
    [[ ${SSH_AUTH_SOCK-unset} == "$EXPECTED_SOCK" ]] || exit 1
    [[ ! ${XDG_RUNTIME_DIR+x} ]] || exit 1
  ' >"$test_root/output" 2>"$test_root/bash.err"
  [[ ! -s $PROJECT_ERR && ! -s $test_root/output ]]
}

export DOTS_OS=arch SSH_AUTH_SOCK="$test_root/current-socket" AGENT_STATUS=0
# Reachable full and empty agents are reused even with keychain installed.
ln -s "$test_root/keychain" "$XDG_BIN_HOME/keychain"
for AGENT_STATUS in 0 1; do
  export AGENT_STATUS
  run_agent yes "$SSH_AUTH_SOCK"
  [[ ! -e $KEYCHAIN_LOG && ! -d $XDG_STATE_HOME/dots ]]
done
[[ $(cat "$AGENT_LOG") == $'-l\n-l' ]]
# Without a probe, a supplied socket is not evidence for replacing the agent.
mv "$XDG_BIN_HOME/ssh-add" "$test_root/ssh-add"
run_agent yes "$SSH_AUTH_SOCK"
[[ ! -e $KEYCHAIN_LOG ]]
mv "$test_root/ssh-add" "$XDG_BIN_HOME/ssh-add"
# Stale local agents may use keychain, without a runtime directory or identities.
export AGENT_STATUS=2
run_agent yes "$XDG_STATE_HOME/dots/keychain/fixture-socket"
[[ $(stat -c %a "$XDG_STATE_HOME/dots") == 700 && $(stat -c %a "$XDG_STATE_HOME/dots/keychain") == 700 ]]
expected=$(printf '%s\n' --eval --quiet --ssh-allow-forwarded --absolute --dir "$XDG_STATE_HOME/dots/keychain")
[[ $(cat "$KEYCHAIN_LOG") == "$expected" ]]
: >"$KEYCHAIN_LOG"
: >"$AGENT_LOG"
# Remote, noninteractive, and native macOS startup never probes/prompts/starts.
for AGENT_STATUS in 0 1 2; do
  export AGENT_STATUS SSH_CONNECTION='fixture remote'
  run_agent yes "$SSH_AUTH_SOCK"
  unset SSH_CONNECTION
  export SSH_CLIENT='fixture client'
  run_agent yes "$SSH_AUTH_SOCK"
  unset SSH_CLIENT
  export SSH_TTY=fixture-tty
  run_agent yes "$SSH_AUTH_SOCK"
  unset SSH_TTY
  run_agent no "$SSH_AUTH_SOCK"
done
export DOTS_OS=macos
run_agent yes "$SSH_AUTH_SOCK"
[[ ! -s $KEYCHAIN_LOG && ! -s $AGENT_LOG ]]
# No agent/keychain remains usable; no fallback unmanaged ssh-agent is started.
export DOTS_OS=void
unset SSH_AUTH_SOCK
rm "$XDG_BIN_HOME/keychain"
run_agent yes unset
[[ ! -s $KEYCHAIN_LOG && ! -s $AGENT_LOG ]]
# A symlinked bookkeeping destination is not followed or chmodded.
rm -r "$XDG_STATE_HOME/dots/keychain"
mkdir "$test_root/unrelated"
ln -s "$test_root/unrelated" "$XDG_STATE_HOME/dots/keychain"
ln -s "$test_root/keychain" "$XDG_BIN_HOME/keychain"
run_agent yes unset
[[ ! -s $KEYCHAIN_LOG && -L $XDG_STATE_HOME/dots/keychain ]]
[[ $(cat "$HOME/.ssh/config") == 'fixture private config sentinel' ]]
echo 'ssh agent test passed'
