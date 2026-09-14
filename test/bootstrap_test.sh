#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-bootstrap-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
export HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/config" XDG_DATA_HOME="$test_root/data"
export XDG_CACHE_HOME="$test_root/cache" XDG_STATE_HOME="$test_root/state" XDG_BIN_HOME="$test_root/bin"
export XDG_RUNTIME_DIR="$test_root/runtime" BREW_PATH="$test_root/brew"
export TEST_OS=arch
mkdir -p "$XDG_CONFIG_HOME/dots" "$test_root/source/setup" "$test_root/source/bash/env" \
  "$test_root/source/bin/autoload" "$test_root/elsewhere" "$test_root/stable" "$XDG_BIN_HOME"
cp "$project_root/setup/common.sh" "$project_root/setup/check" "$test_root/source/setup/"
cp "$project_root/bash/env/"{xdg,path,brew}.sh "$test_root/source/bash/env/"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$TEST_OS"\n' > "$test_root/source/bin/autoload/os"
source "$project_root/setup/common.sh"
entry="$test_root/source/setup/check"
assert() { "$@" || { printf 'Assertion failed: %s\n' "$*" >&2; exit 1; }; }
expect_failure() { if "$@"; then printf 'Expected failure: %s\n' "$*" >&2; exit 1; fi; }
snapshot() {
  find "$test_root" -printf '%P %y %m %l\n' | LC_ALL=C sort
  find "$test_root" -type f -exec sha256sum {} + | LC_ALL=C sort
}

# An absent env uses defaults; source root never comes from stale exports or cwd.
(
  export DOTFILES_REPO_HOME=/stale DOTS_SOURCE_ROOT=/stale DOTS_SELECTION=sway
  cd "$test_root/elsewhere"
  dots_bootstrap prerequisites "$entry"
  assert test "$DOTS_SOURCE_ROOT" = "$test_root/source"
  assert test "$DOTFILES_REPO_HOME" = "$test_root/source"
  assert test "$DOTS_INSTALL_ROOT" = "$test_root/source"
  assert test "$DOTS_SELECTION" = ''
  assert test "$XDG_STATE_HOME" = "$test_root/state"
  assert test ! -e "$XDG_STATE_HOME"
)
cat > "$XDG_CONFIG_HOME/dots/env" <<'SH'
DOTS_SELECTION=sway
DOTS_WEZTERM_DESTINATION=''
DOTFILES_REPO_HOME=/stale-private-root
export PRIVATE_SENTINEL=secret-bootstrap-sentinel
export CARGO_HOME="$HOME/custom-cargo"
export EDITOR=custom-editor
printf '%s\n' "$PRIVATE_SENTINEL"
SH
printf 'touch "$HOME/cwd-env-executed"\n' > "$test_root/elsewhere/.env"
ln -s "$entry" "$test_root/elsewhere/check"
before=$(snapshot)
output=$({
  cd "$test_root/elsewhere"
  dots_bootstrap readiness "$test_root/elsewhere/check"
  assert test "$DOTS_SELECTION" = sway
  assert test "$CARGO_HOME" = "$HOME/custom-cargo"
  assert test "$EDITOR" = custom-editor
  assert test "$DOTS_ENV_FILE" = "$XDG_CONFIG_HOME/dots/env"
  export DOTS_INSTALL_SELECTION=''
  dots_bootstrap install "$entry"
  assert test "$DOTS_SELECTION" = ''
  assert test "$DOTS_SAVE" = 0
  dots_bootstrap install "$entry" --select sway --save
  assert test "$DOTS_SELECTION" = sway
  assert test "$DOTS_SAVE" = 1
  export DOTS_INSTALL_SELECTION=sway
  dots_bootstrap readiness "$entry" --select ''
  assert test "$DOTS_SELECTION" = ''
  unset DOTS_INSTALL_SELECTION
  dots_bootstrap candidate "$entry" --install-root "$test_root/stable"
  assert test "$DOTS_SOURCE_ROOT" = "$test_root/source"
  assert test "$DOTS_INSTALL_ROOT" = "$test_root/stable"
  expect_failure dots_bootstrap readiness "$entry" --save
  expect_failure dots_bootstrap readiness "$entry" --select
  for selection in unknown macos-desktop sway,sway sway, sway,,karabiner; do
    expect_failure dots_bootstrap readiness "$entry" --select "$selection"
  done
  export TEST_OS=macos DOTS_INSTALL_SELECTION=alfred
  dots_bootstrap readiness "$entry" --select macos-desktop,karabiner
  assert test "$DOTS_SELECTION" = macos-desktop,karabiner
  export TEST_OS=wsl DOTS_INSTALL_SELECTION=wsl-integration
  export DOTS_INSTALL_WEZTERM_DESTINATION='C:\Users\Example Name\wezterm.lua'
  dots_bootstrap install "$entry"
  assert test "$DOTS_WEZTERM_DESTINATION" = "$DOTS_INSTALL_WEZTERM_DESTINATION"
  dots_bootstrap install "$entry" --wezterm-destination ''
  assert test "$DOTS_WEZTERM_DESTINATION" = ''
  expect_failure dots_bootstrap install "$entry" --wezterm-destination relative
} 2>&1)
assert test "$before" = "$(snapshot)"
assert test "${output/secret-bootstrap-sentinel/}" = "$output"

(
  cd "$test_root/source/setup"
  dots_bootstrap prerequisites check
  assert test "$DOTS_SOURCE_ROOT" = "$test_root/source"
)

# Saved host paths and selection can both be explicitly cleared, including via env.
printf "DOTS_SELECTION=wsl-integration\nDOTS_WEZTERM_DESTINATION='C:\\\\saved\\\\wezterm.lua'\n" > "$XDG_CONFIG_HOME/dots/env"
(
  export TEST_OS=wsl DOTS_INSTALL_SELECTION='' DOTS_INSTALL_WEZTERM_DESTINATION=''
  dots_bootstrap install "$entry"
  assert test "$DOTS_SELECTION" = ''
  assert test "$DOTS_WEZTERM_DESTINATION" = ''
)

# Real executable GNU lookup, inherited PATH (including empty entries), no Python.
mkdir -p "$BREW_PATH/opt/coreutils/libexec/gnubin" "$BREW_PATH/opt/gnu-sed/libexec/gnubin" "$test_root/host-bin"
for tool in bash readlink; do ln -s "$(type -P "$tool")" "$test_root/host-bin/$tool"; done
ln -s "$(type -P realpath)" "$BREW_PATH/opt/coreutils/libexec/gnubin/realpath"
ln -s "$(type -P sed)" "$BREW_PATH/opt/gnu-sed/libexec/gnubin/sed"
(
  export PATH="$test_root/host-bin:$BREW_PATH/opt/coreutils/libexec/gnubin::" TEST_OS=arch DOTS_INSTALL_SELECTION='' DOTS_INSTALL_WEZTERM_DESTINATION=''
  old_path=$PATH
  dots_bootstrap prerequisites "$entry"
  assert test "${PATH%"$old_path"}" != "$PATH"
  assert test "$(type -P realpath)" = "$BREW_PATH/opt/coreutils/libexec/gnubin/realpath"
  assert test "$(type -P sed)" = "$BREW_PATH/opt/gnu-sed/libexec/gnubin/sed"
  expect_failure type -P python3
  initial_path=$PATH
  source "$project_root/bash/env/path.sh"
  assert test "$PATH" = "$initial_path"
)
(
  unset XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_BIN_HOME
  dots_bootstrap prerequisites "$entry"
  assert test "$XDG_CONFIG_HOME" = "$HOME/.config"
  assert test ! -e "$HOME/.config"
)
printf 'bootstrap test passed\n'
