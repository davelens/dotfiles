#!/usr/bin/env bash
set -e

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-utility-completion-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export HOME="$test_root/home"
export XDG_CONFIG_HOME="$test_root/config" XDG_DATA_HOME="$test_root/data"
export XDG_CACHE_HOME="$test_root/cache" XDG_STATE_HOME="$test_root/state"
export XDG_BIN_HOME="$test_root/bin" XDG_RUNTIME_DIR="$test_root/runtime"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME" "$XDG_RUNTIME_DIR" "$test_root/private/repo.d"
export DOTFILES_REPO_HOME="$test_root" DOTS_SELECTION=
source "$project_root/setup/common.sh"

for category in macos linux freebsd windows arch void debian nixos fedora wsl misc kanshi quickshell desktop-session; do
  mkdir -p "$test_root/bin/utilities/$category"
done
ln -s "$test_root/private" "$test_root/bin/utilities/private"
touch "$test_root/private/run" "$test_root/private/netrc.rb" \
  "$test_root/private/_helper" "$test_root/private/helper.sh" \
  "$test_root/private/repo.d/nested"
chmod +x "$test_root/private/run" "$test_root/private/_helper" \
  "$test_root/private/helper.sh" "$test_root/private/repo.d/nested"
ln -s run "$test_root/private/linked"

check_completion() {
  local actual
  _utility_completions || { echo 'Completion failed' >&2; exit 1; }
  actual=$(printf '%s\n' "${COMPREPLY[@]}" | LC_ALL=C sort | paste -sd ' ' -)
  if [[ "$actual" != "$1" ]]; then
    printf 'Expected: %s\nActual:   %s\n' "$1" "$actual" >&2
    exit 1
  fi
}

while read -r TEST_PLATFORM TEST_DISTRO expected; do
  export DOTS_OS=$TEST_DISTRO
  source "$project_root/bash/env/completions/utility_completion.bash"
  COMP_WORDS=(utility '')
  COMP_CWORD=1
  check_completion "$expected"
done <<'CASES'
linux arch arch linux misc private
linux void linux misc private void
linux debian debian linux misc private
linux nixos linux misc nixos private
linux fedora fedora linux misc private
linux wsl arch linux misc private wsl
linux linux linux misc private
macos macos macos misc private
freebsd freebsd freebsd misc private
windows windows misc private windows
CASES

COMP_WORDS=(utility private '')
COMP_CWORD=2
check_completion 'linked run'
COMP_WORDS=(u private ru)
check_completion 'run'

DOTS_OS=arch DOTS_SELECTION=sway
COMP_WORDS=(utility '') COMP_CWORD=1
check_completion 'arch desktop-session kanshi linux misc private quickshell'
DOTS_SELECTION=
COMP_WORDS=(utility macos '') COMP_CWORD=2
check_completion ''
COMP_WORDS=(utility ../private '')
check_completion ''
COMP_WORDS=(utility private ../run '') COMP_CWORD=3
check_completion ''
echo 'utility completion test passed'
