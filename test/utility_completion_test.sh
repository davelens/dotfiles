#!/usr/bin/env bash
set -e

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-utility-completion-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export DOTFILES_REPO_HOME="$test_root"
export XDG_BIN_HOME="$test_root/bin"
mkdir -p "$XDG_BIN_HOME" "$test_root/private/repo.d"

cat >"$XDG_BIN_HOME/os" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == --platform ]]; then
  echo "$TEST_PLATFORM"
else
  echo "$TEST_DISTRO"
fi
SH
chmod +x "$XDG_BIN_HOME/os"

for category in macos linux freebsd windows arch debian nixos fedora wsl misc; do
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
  export TEST_PLATFORM TEST_DISTRO
  source "$project_root/bash/env/completions/utility_completion.bash"
  COMP_WORDS=(utility '')
  COMP_CWORD=1
  check_completion "$expected"
done <<'CASES'
linux arch arch linux misc private
linux debian debian linux misc private
linux nixos linux misc nixos private
linux fedora fedora linux misc private
linux wsl linux misc private wsl
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

echo 'utility completion test passed'
