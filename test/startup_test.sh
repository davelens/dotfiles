#!/usr/bin/env bash
set -e
project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-startup-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/config" XDG_DATA_HOME="$test_root/data"
export XDG_CACHE_HOME="$test_root/cache" XDG_STATE_HOME="$test_root/state" XDG_BIN_HOME="$test_root/bin"
export XDG_RUNTIME_DIR="$test_root/runtime" TMPDIR="$test_root/tmp"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/dots" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME" "$XDG_RUNTIME_DIR" "$TMPDIR"
bash=$(type -P bash)
export CHECKOUT="$test_root/alternate checkout" BREW_PATH="$test_root/brew"
mkdir -p "$CHECKOUT/"{config,setup,bash/env/completions,bin/autoload} "$BREW_PATH/opt/coreutils/libexec/gnubin" "$BREW_PATH/bin" "$test_root/inherited"
cp "$project_root/config/"{bash_profile,bashrc} "$CHECKOUT/config/"
cp "$project_root/setup/common.sh" "$CHECKOUT/setup/"
cp "$project_root/bash/"{helpers,colors,aliases,prompt,utility-context}.sh "$CHECKOUT/bash/"
for file in xdg path brew misc ruby completion ssh options history; do
  cp "$project_root/bash/env/$file.sh" "$CHECKOUT/bash/env/"
done
cp "$project_root/bash/env/completions/"*.bash "$CHECKOUT/bash/env/completions/"
for os in arch void macos wsl; do
  mkdir -p "$CHECKOUT/bash/env/os/$os"
  cp "$project_root/bash/env/os/$os/"*.sh "$CHECKOUT/bash/env/os/$os/"
done
for tool in bash readlink mkdir chmod cat; do ln -s "$(type -P "$tool")" "$XDG_BIN_HOME/$tool"; done
ln -s "$bash" "$BREW_PATH/bin/bash"
printf '#!/usr/bin/env bash\necho "$TEST_OS"\n' >"$CHECKOUT/bin/autoload/os"
chmod +x "$CHECKOUT/bin/autoload/os"
printf '#!/usr/bin/env bash\necho gnu\n' >"$BREW_PATH/opt/coreutils/libexec/gnubin/ls"
chmod +x "$BREW_PATH/opt/coreutils/libexec/gnubin/ls"
export OP_LOG="$test_root/operations" HOOK_LOG="$test_root/hooks" PROJECT_ERR="$test_root/project.err"
for tool in sudo systemctl sv mysql.server pg_ctl pacman paru xbps-install brew apt-get ssh-agent setxkbmap findmnt umount sleep xclip uwsm swaymsg; do
  printf '#!/usr/bin/env bash\necho "${0##*/} $*" >>"$OP_LOG"\nexit 99\n' >"$XDG_BIN_HOME/$tool"
  chmod +x "$XDG_BIN_HOME/$tool"
done
printf '#!/usr/bin/env bash\nexit 2\n' >"$XDG_BIN_HOME/ssh-add"
chmod +x "$XDG_BIN_HOME/ssh-add"
cat >"$XDG_CONFIG_HOME/dots/env" <<'SH'
DOTFILES_REPO_HOME=/stale/private-export
DOTS_SELECTION=${TEST_SELECTION-}
EDITOR=fixture-editor
GH_EDITOR=fixture-gh-editor
PAGER=fixture-pager
RUBY_YJIT_ENABLE=0
NODE_OPTIONS=fixture-node-options
SHELL=/fixture/user-shell
BROWSER=fixture-browser
GH_BROWSER=fixture-gh-browser
PATH="$XDG_BIN_HOME:$INHERITED_PATH"
alias pbcopy='fixture-copy'
SH
export INHERITED_PATH="$test_root/inherited"
startup_path="$XDG_BIN_HOME:$test_root/inherited"
ln -s "$CHECKOUT/config/bash_profile" "$test_root/profile-link"
ln -s ../profile-link "$HOME/.bash_profile"
ln -s "$CHECKOUT/config/bashrc" "$HOME/.bashrc"

run_startup() {
  local entry=$1 mode=$2
  export ENTRY=$entry DOTFILES_REPO_HOME=/stale/inherited-export TEST_RUNTIME=${XDG_RUNTIME_DIR-unset}
  local -a flags=()
  [[ $mode != interactive ]] || flags=(-i)
  # Bash itself warns about job control without a tty; capture project stderr
  # separately, after Bash has initialized, rather than masking startup errors.
  PATH="$startup_path" "$bash" --noprofile --norc "${flags[@]}" -c '
    exec 2>"$PROJECT_ERR"
    source "$ENTRY" || exit 11
    [[ $DOTFILES_REPO_HOME == "$CHECKOUT" && $DOTS_SOURCE_ROOT == "$CHECKOUT" ]] || exit 12
    [[ $DOTS_SELECTION == "$TEST_SELECTION" ]] || exit 13
    [[ ${XDG_RUNTIME_DIR-unset} == "${TEST_RUNTIME-unset}" ]] || exit 23
    [[ $PATH == *"$INHERITED_PATH"* && $(type -P ls) == "$BREW_PATH/opt/coreutils/libexec/gnubin/ls" ]] || exit 14
    [[ $EDITOR == fixture-editor && $GH_EDITOR == fixture-gh-editor && $PAGER == fixture-pager ]] || exit 15
    [[ $NODE_OPTIONS == fixture-node-options && $RUBY_YJIT_ENABLE == 0 && $SHELL == /fixture/user-shell ]] || exit 16
    [[ ${WLR_RENDERER-unset} == "${TEST_RENDERER-unset}" && ${WLR_NO_HARDWARE_CURSORS-unset} == unset ]] || exit 17
    [[ $BROWSER == fixture-browser && $GH_BROWSER == fixture-gh-browser ]] || exit 22
    [[ ${WAYLAND_DISPLAY-unset} == "${TEST_DISPLAY-unset}" ]] || exit 18
    if [[ $- == *i* ]]; then
      [[ $(alias pbcopy) == "alias pbcopy='"'"'fixture-copy'"'"'" ]] || exit 19
    else
      [[ -z ${PROMPT_COMMAND:-} ]] && ! declare -F _utility_completions >/dev/null || exit 20
    fi
    "$BASH" --noprofile --norc -c "declare -F command_exists >/dev/null" || exit 21
  ' >"$test_root/output" 2>"$test_root/bash.err" || {
    printf 'Startup failed: %s %s %s\n' "$TEST_OS" "$entry" "$mode" >&2
    cat "$PROJECT_ERR" >&2
    exit 1
  }
  [[ ! -s $PROJECT_ERR && ! -s $test_root/output && ! -s $OP_LOG ]]
}

for TEST_OS in arch void macos wsl; do
  export TEST_OS TEST_SELECTION=
  for entry in "$CHECKOUT/config/bash_profile" "$HOME/.bash_profile" "$CHECKOUT/config/bashrc" "$HOME/.bashrc"; do
    run_startup "$entry" interactive
  done
  run_startup "$CHECKOUT/config/bash_profile" noninteractive
  case $TEST_OS in arch|void) TEST_SELECTION=sway ;; macos) TEST_SELECTION=macos-desktop ;; wsl) TEST_SELECTION=wsl-integration ;; esac
  export TEST_SELECTION SSH_CONNECTION='fixture remote'
  run_startup "$HOME/.bash_profile" interactive
  run_startup "$CHECKOUT/config/bash_profile" noninteractive
  unset SSH_CONNECTION
done
[[ ! -d $XDG_STATE_HOME/dots ]]

# Successful optional interfaces see trusted overrides; rejected ones stay quiet.
for tool in mise fzf starship; do
  cat >"$XDG_BIN_HOME/$tool" <<'SH'
#!/usr/bin/env bash
printf '%s %s %s\n' "${0##*/}" "$*" "$EDITOR" >>"$HOOK_LOG"
if [[ ${REJECT_HOOKS:-0} == 1 ]]; then echo unsupported >&2; exit 2; fi
printf 'export FIXTURE_HOOK=loaded\n'
SH
  chmod +x "$XDG_BIN_HOME/$tool"
done
export TEST_OS=void TEST_SELECTION=sway WAYLAND_DISPLAY=fixture-wayland SWAYSOCK=fixture-sway TEST_DISPLAY=fixture-wayland
run_startup "$HOME/.bash_profile" interactive
for expected in 'mise activate bash fixture-editor' 'fzf --bash fixture-editor' 'starship init bash fixture-editor'; do
  grep -Fxq "$expected" "$HOOK_LOG"
done
export REJECT_HOOKS=1
run_startup "$HOME/.bash_profile" interactive
: >"$HOOK_LOG"
run_startup "$CHECKOUT/config/bash_profile" noninteractive
[[ ! -s $HOOK_LOG ]]
unset XDG_RUNTIME_DIR WAYLAND_DISPLAY SWAYSOCK TEST_DISPLAY
run_startup "$HOME/.bash_profile" interactive
[[ ! -s $OP_LOG ]]
export WLR_RENDERER=fixture-renderer TEST_RENDERER=fixture-renderer
run_startup "$HOME/.bash_profile" interactive
# Noninteractive bashrc remains inert even if PS1 was inherited.
ENTRY="$HOME/.bashrc" PS1=not-interactivity "$bash" --noprofile --norc -c 'source "$ENTRY"; [[ $DOTFILES_REPO_HOME == /stale/inherited-export ]]'
echo 'startup test passed'
