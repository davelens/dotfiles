#!/usr/bin/env bash
set -e
project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-utility-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/config" XDG_DATA_HOME="$test_root/data"
export XDG_CACHE_HOME="$test_root/cache" XDG_STATE_HOME="$test_root/state" XDG_BIN_HOME="$test_root/bin"
export XDG_RUNTIME_DIR="$test_root/runtime" TMPDIR="$test_root/tmp"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/dots" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME" "$XDG_RUNTIME_DIR" "$TMPDIR"
export CHECKOUT="$test_root/alternate checkout" BREW_PATH="$test_root/brew"
mkdir -p "$CHECKOUT/"{setup,bash/env/completions,bin/autoload,bin/utilities} "$test_root/private"
cp "$project_root/setup/common.sh" "$CHECKOUT/setup/"
cp "$project_root/bash/"{helpers,utility-context}.sh "$CHECKOUT/bash/"
cp "$project_root/bash/env/"{xdg,brew,path,misc}.sh "$CHECKOUT/bash/env/"
cp "$project_root/bash/env/completions/utility_completion.bash" "$CHECKOUT/bash/env/completions/"
cp "$project_root/bin/utility" "$CHECKOUT/bin/"
cp "$project_root/bin/autoload/desktop-session" "$CHECKOUT/bin/autoload/"
for tool in bash readlink dirname realpath; do ln -s "$(type -P "$tool")" "$XDG_BIN_HOME/$tool"; done
bash=$(type -P bash)
cat >"$CHECKOUT/bin/autoload/os" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$TEST_OS"
SH
chmod +x "$CHECKOUT/bin/autoload/os"
cat >"$XDG_CONFIG_HOME/dots/env" <<'SH'
DOTFILES_REPO_HOME=/stale/saved-export
DOTS_SELECTION=${TEST_SELECTION-}
EDITOR=fixture-editor
SH
for category in arch void linux macos wsl misc kanshi quickshell desktop-session; do
  mkdir -p "$CHECKOUT/bin/utilities/$category"
done
ln -s "$test_root/private" "$CHECKOUT/bin/utilities/private"
cat >"$test_root/private/run" <<'SH'
#!/usr/bin/env bash
[[ $DOTFILES_REPO_HOME == "$CHECKOUT" && $EDITOR == fixture-editor ]] || exit 1
printf '<%s>\n' "$@"
SH
chmod +x "$test_root/private/run"
ln -s run "$test_root/private/linked"
cp "$test_root/private/run" "$test_root/private/_helper"
cp "$test_root/private/run" "$test_root/private/helper.sh"
cat >"$test_root/private/missing-tool" <<'SH'
#!/usr/bin/env bash
fixture-missing-executable
SH
chmod +x "$test_root/private/missing-tool"
for path in arch/run void/run linux/run macos/run wsl/run misc/clean-my-mac misc/screenshot misc/screencast kanshi/restart quickshell/restart; do
  cp "$test_root/private/run" "$CHECKOUT/bin/utilities/$path"
done
ln -s "$CHECKOUT/bin/utility" "$XDG_BIN_HOME/utility"
ln -s "$CHECKOUT/bin/autoload/desktop-session" "$XDG_BIN_HOME/desktop-session"
export DOTFILES_REPO_HOME=/stale/inherited-export TEST_OS=arch TEST_SELECTION=
run_utility() { PATH="$XDG_BIN_HOME" "$CHECKOUT/bin/utility" "$@"; }
reject() {
  if run_utility "$@" >"$test_root/output" 2>"$test_root/error"; then
    printf 'Unexpected utility success: %s\n' "$*" >&2; exit 1
  fi
  [[ -s $test_root/error ]]
}
# Invocation, help, and completion all share context, including private links.
for TEST_OS in arch void macos wsl; do
  export TEST_OS
  case $TEST_OS in arch|void) TEST_SELECTION=sway ;; macos) TEST_SELECTION=macos-desktop ;; wsl) TEST_SELECTION=wsl-integration ;; esac
  export TEST_SELECTION
  help=$(run_utility --help)
  discovery=$(PATH="$XDG_BIN_HOME" "$bash" --noprofile --norc -c '
    source "$CHECKOUT/setup/common.sh"
    dots_bootstrap readiness "$CHECKOUT/bin/utility"
    source "$CHECKOUT/bash/env/completions/utility_completion.bash"
    COMP_WORDS=(utility "") COMP_CWORD=1
    _utility_completions
    categories=("${COMPREPLY[@]}")
    for category in "${categories[@]}"; do
      COMP_WORDS=(utility "$category" "") COMP_CWORD=2
      _utility_completions
      for command in "${COMPREPLY[@]}"; do printf "  %s %s\n" "$category" "$command"; done
    done
  ')
  [[ ${help#*$'Available commands:\n'} == "$discovery" ]]
  [[ $help == *'private run'* && $help == *'private linked'* && $help != *'_helper'* && $help != *'helper.sh'* ]]
  [[ $(run_utility private run 'space value' '$(not code)' 'quote"') == $'<space value>\n<$(not code)>\n<quote">' ]]
  [[ $(PATH="$XDG_BIN_HOME" "$XDG_BIN_HOME/utility" private linked ok) == '<ok>' ]]
  reject ../private run
  reject private ../run
  reject private _helper
  reject private helper.sh
  if [[ $TEST_OS == wsl ]]; then
    [[ $help == *'arch run'* && $help != *'misc screenshot'* ]]
  fi
done
export TEST_OS=arch TEST_SELECTION=sway
reject private missing-tool
grep -Fq 'Missing command fixture-missing-executable' "$test_root/error"
mkdir -p "$test_root/cwd"
printf 'echo must-not-source-project-env; exit 99\n' >"$test_root/cwd/.env"
[[ $(cd "$test_root/cwd" && run_utility private run safe) == '<safe>' ]]
mkdir "$CHECKOUT/bin/utilities/_custom.sh"
cp "$test_root/private/run" "$CHECKOUT/bin/utilities/_custom.sh/run"
[[ $(run_utility _custom.sh run custom) == '<custom>' ]]
[[ $(run_utility --help) == *'_custom.sh run'* ]]
# Selected commands stay discoverable headlessly and when software is missing.
reject misc screenshot
grep -Fq 'running selected Sway session' "$test_root/error"
export SWAYSOCK=fixture-sway WAYLAND_DISPLAY=fixture-wayland
reject misc screenshot
grep -Fq 'Missing flameshot' "$test_root/error"
reject postgresql start
grep -Fq 'register the dotsys helper' "$test_root/error"
if PATH="$XDG_BIN_HOME" "$XDG_BIN_HOME/desktop-session" launch true >"$test_root/output" 2>"$test_root/error"; then exit 1; fi
grep -Fq 'Missing executable' "$test_root/error"
export TEST_SELECTION=
reject misc screenshot
grep -Fq 'platform/selection' "$test_root/error"
reject macos run
# Keep external registrations as links; no registration or provider selection here.
mkdir -p "$test_root/helper/desktop-session"
cat >"$test_root/helper/desktop-session/launch" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$HELPER_LOG"
exit "${HELPER_STATUS:-0}"
SH
chmod +x "$test_root/helper/desktop-session/launch"
rmdir "$CHECKOUT/bin/utilities/desktop-session"
ln -s "$test_root/helper/desktop-session" "$CHECKOUT/bin/utilities/desktop-session"
export TEST_SELECTION=sway HELPER_LOG="$test_root/helper.log"
PATH="$XDG_BIN_HOME" "$XDG_BIN_HOME/desktop-session" launch 'command with spaces' 'arg "quoted"'
[[ $(cat "$HELPER_LOG") == $'command with spaces\narg "quoted"' ]]
export HELPER_STATUS=23
status=0
PATH="$XDG_BIN_HOME" "$CHECKOUT/bin/autoload/desktop-session" launch command || status=$?
[[ $status == 23 && -L $CHECKOUT/bin/utilities/private && -L $CHECKOUT/bin/utilities/desktop-session ]]
[[ ! -e $project_root/bin/utilities/postgresql/start && ! -e $project_root/bin/utilities/postgresql/stop ]]
echo 'utility test passed'
