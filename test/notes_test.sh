#!/usr/bin/env bash
set -e

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export PROJECT_ROOT="$project_root"
test_root=$(mktemp -d "$project_root/.tmp-notes-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export HOME="$test_root/home"
export CALL_LOG="$test_root/calls"
export TEST_OS=arch TEST_PLATFORM=linux TEST_MOUNTED=0 TEST_MOUNT_FAIL=0
mkdir -p "$test_root/bin" "$HOME"

cat >"$test_root/bin/mock" <<'SH'
#!/usr/bin/env bash
name=${0##*/}
case "$name" in
  os)
    if [[ "$1" == --platform ]]; then echo "$TEST_PLATFORM"; else echo "$TEST_OS"; fi
    ;;
  mount)
    if [[ "$TEST_MOUNTED" == 1 ]]; then
      echo "//nas/storage on $HOME/Network/alexandria type cifs (rw)"
    elif [[ "$TEST_MOUNTED" == 2 ]]; then
      echo "//nas/storage on $HOME/Network/alexandria-backup type cifs (rw)"
    fi
    ;;
  networksetup|tailscale)
    echo "FAIL: notes must use the existing Tailscale connection" >&2
    exit 1
    ;;
  sudo|mount_smbfs)
    printf '%s\n' "$name $*" >>"$CALL_LOG"
    exit "$TEST_MOUNT_FAIL"
    ;;
  utility)
    printf '%s\n' "$@" >"$CALL_LOG.utility"
    if [[ "$TEST_DISPATCH" == 1 ]]; then
      script="$PROJECT_ROOT/bin/utilities/$1/$2"
      shift 2
      exec bash "$script" "$@"
    fi
    ;;
  tmux)
    printf '%s\n' "$*" >>"$CALL_LOG.tmux"
    if [[ "$1" == has-session ]]; then exit "$TEST_SESSION_STATUS"; fi
    ;;
esac
SH
chmod +x "$test_root/bin/mock"
for cmd in os mount networksetup sudo mount_smbfs utility tailscale tmux; do
  ln -s mock "$test_root/bin/$cmd"
done
export PATH="$test_root/bin:$PATH"
unset BASH_ENV

run_notes() {
  : >"$CALL_LOG"
  : >"$CALL_LOG.utility"
  bash "$project_root/bin/utilities/misc/notes" "$@"
}

run_notes -f 'config with spaces'
if ! grep -Fqx "sudo mount -t cifs //100.73.75.7/storage $HOME/Network/alexandria -o vers=2.0,username=davelens,prefixpath=projects/notes,uid=$(id -u),gid=$(id -g)" "$CALL_LOG"; then
  echo 'FAIL: native Linux must mount the NAS notes subfolder using CIFS' >&2
  cat "$CALL_LOG" >&2
  exit 1
fi
printf '%s\n' tmux quickstart -f 'config with spaces' -- "$HOME/Network/alexandria" -- >"$test_root/expected"
cmp "$test_root/expected" "$CALL_LOG.utility"

TEST_MOUNTED=1 run_notes
if grep -Eq '^(sudo|mount_smbfs) ' "$CALL_LOG"; then exit 1; fi
test -s "$CALL_LOG.utility"

TEST_MOUNTED=2 run_notes
grep -q '^sudo mount -t cifs ' "$CALL_LOG"

if TEST_MOUNT_FAIL=1 run_notes; then
  echo 'FAIL: notes must stop when mounting fails' >&2
  exit 1
fi
test ! -s "$CALL_LOG.utility"

TEST_OS=wsl run_notes
grep -Fqx "sudo mount -t drvfs \\\\100.73.75.7\\storage\\projects\\notes $HOME/Network/alexandria" "$CALL_LOG"

TEST_OS=macos TEST_PLATFORM=macos run_notes
grep -Fqx "mount_smbfs //davelens@100.73.75.7/storage/projects/notes $HOME/Network/alexandria" "$CALL_LOG"

if TEST_OS=freebsd TEST_PLATFORM=freebsd run_notes 2>"$test_root/error"; then
  echo 'FAIL: unsupported platforms must not open tmux' >&2
  exit 1
fi
grep -Fqx 'notes: unsupported platform: freebsd' "$test_root/error"
test ! -s "$CALL_LOG.utility"

export TEST_DISPATCH=1 TEST_SESSION_STATUS=1 EDITOR=dvim
: >"$CALL_LOG.tmux"
bash "$project_root/bin/utilities/misc/chores"
grep -Fqx 'new-session -s alexandria -n editor -d' "$CALL_LOG.tmux"
grep -Fqx "new-window -S -t =alexandria: -n chores -c $HOME/Network/alexandria dvim ./documents/CHORES.md" "$CALL_LOG.tmux"
grep -Fqx 'select-window -t =alexandria:=chores' "$CALL_LOG.tmux"
test "$(grep -c '^attach ' "$CALL_LOG.tmux")" = 1
test "$(tail -1 "$CALL_LOG.tmux")" = 'attach -t =alexandria'

# An existing session reuses and focuses chores without disturbing its editor.
export TEST_SESSION_STATUS=0
: >"$CALL_LOG.tmux"
bash "$project_root/bin/utilities/misc/chores"
if grep -Eq '^(new-session|send-keys) ' "$CALL_LOG.tmux"; then exit 1; fi
grep -Fqx "new-window -S -t =alexandria: -n chores -c $HOME/Network/alexandria dvim ./documents/CHORES.md" "$CALL_LOG.tmux"
grep -Fqx 'select-window -t =alexandria:=chores' "$CALL_LOG.tmux"
test "$(grep -c '^attach ' "$CALL_LOG.tmux")" = 1

: >"$CALL_LOG.tmux"
if TEST_MOUNT_FAIL=1 bash "$project_root/bin/utilities/misc/chores"; then
  echo 'FAIL: chores must stop when mounting fails' >&2
  exit 1
fi
test ! -s "$CALL_LOG.tmux"

run_notes
grep -Fqx 'attach -t =alexandria' "$CALL_LOG.tmux"
grep -Fqx "alias chores='utility misc chores'" "$project_root/bash/aliases.sh"

echo 'notes and chores tests passed'
