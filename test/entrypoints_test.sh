#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd -P -- "${BASH_SOURCE[0]%/*}/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-entrypoints.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
base_path=$PATH
bash_bin=$(command -v bash)
real_git=$(command -v git)
export REAL_GIT=$real_git TEST_ROOT=$test_root
assert() { "$@" || { printf 'Assertion failed: %s\n' "$*" >&2; exit 1; }; }
fails() { if "$@"; then printf 'Expected failure: %s\n' "$*" >&2; exit 1; fi; }
fixture() {
  case_root="$test_root/$1"
  export HOME="$case_root/home" XDG_CONFIG_HOME="$case_root/config"
  export XDG_DATA_HOME="$case_root/data" XDG_STATE_HOME="$case_root/state"
  export XDG_CACHE_HOME="$case_root/cache" XDG_BIN_HOME="$case_root/bin"
  export XDG_RUNTIME_DIR="$case_root/runtime" TMPDIR="$case_root/tmp"
  export TMP="$TMPDIR" TEMP="$TMPDIR" BREW_PATH="$case_root/brew"
  export PATH="$case_root/fakes:$base_path" CALL_LOG="$case_root/call"
  export OPERATIONS="$case_root/operations" GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL="$case_root/gitconfig" GIT_TERMINAL_PROMPT=0
  unset DOTSYS_REPO_HOME DOTFILES_REPO_HOME DOTFILES_CONFIG_HOME DOTFILES_STATE_HOME
  unset DOTS_INSTALL_SELECTION DOTS_INSTALL_WEZTERM_DESTINATION DELEGATE_STATUS
  mkdir -p "$HOME" "$TMPDIR" "$case_root/fakes" "$XDG_CONFIG_HOME/dots"
  : > "$GIT_CONFIG_GLOBAL"
  printf '# Private fixture; must remain byte-identical.\nexport PRIVATE_SENTINEL=entrypoint-secret\n' > "$XDG_CONFIG_HOME/dots/env"
  cp "$XDG_CONFIG_HOME/dots/env" "$case_root/env.before"
  local command
  for command in sudo brew pacman apt-get xbps-install systemctl sv loginctl gh bw ssh ssh-add gpg curl wget unzip mise; do
    cat > "$case_root/fakes/$command" <<'SPY'
#!/usr/bin/env bash
printf '%s\n' "$0 $*" >> "$OPERATIONS"
exit 99
SPY
    chmod +x "$case_root/fakes/$command"
  done
  cat > "$case_root/fakes/git" <<'SPY'
#!/usr/bin/env bash
for arg in "$@"; do
  case $arg in pull|fetch|reset) printf 'Unsafe Git: %s\n' "$*" >> "$OPERATIONS"; exit 99 ;; esac
done
if [[ ${1:-} == clone ]]; then
  args=("$@")
  source_repo=${args[${#args[@]}-2]}
  [[ $source_repo == "$TEST_ROOT"/* ]] || { echo 'Network clone refused' >> "$OPERATIONS"; exit 99; }
fi
exec "$REAL_GIT" "$@"
SPY
  chmod +x "$case_root/fakes/git"
  source_root="$case_root/checkout with spaces"
  local file
  for file in bin/autoload/dots bin/utility setup/brew/init.sh bin/utilities/brew/init \
      setup/common.sh bash/helpers.sh bash/utility-context.sh \
      bash/env/xdg.sh bash/env/path.sh bash/env/brew.sh bash/env/misc.sh; do
    mkdir -p "$source_root/${file%/*}"
    cp "$project_root/$file" "$source_root/$file"
  done
  printf '#!/usr/bin/env bash\necho arch\n' > "$source_root/bin/autoload/os"
  chmod +x "$source_root/bin/autoload/os"
  spy "$source_root/setup/install"
  spy "$source_root/setup/check"
  dots="$source_root/bin/autoload/dots"
  # This must never be discovered or sourced by any public entrypoint.
  printf 'echo cwd-env-was-read >> "$OPERATIONS"\n' > "$case_root/.env"
  cd "$case_root"
}
spy() {
  mkdir -p "${1%/*}"
  cat > "$1" <<'SPY'
#!/usr/bin/env bash
printf '%s\0' "$0" "$@" > "$CALL_LOG"
exit "${DELEGATE_STATUS:-0}"
SPY
  chmod +x "$1"
}
called() {
  printf '%s\0' "$@" > "$case_root/expected"
  assert cmp "$case_root/expected" "$CALL_LOG"
}
untouched() {
  assert cmp "$case_root/env.before" "$XDG_CONFIG_HOME/dots/env"
  assert test ! -e "$OPERATIONS"
  assert test ! -e "$XDG_STATE_HOME"
}

fixture direct
args=(--select '' --wezterm-destination "C:\\Users\\a '名'\\wezterm.lua" --save --adopt "$HOME/matching file" --replace "$HOME/other file")
export DOTFILES_REPO_HOME="$case_root/stale" DOTFILES_CONFIG_HOME="$case_root/stale-config"
"$bash_bin" "$dots" install "${args[@]}"
called "$source_root/setup/install" "${args[@]}"
"$bash_bin" "$dots" install --check --select sway
called "$source_root/setup/install" --check --select sway
for mode in prerequisites readiness; do
  "$bash_bin" "$dots" check "$mode" --select ''
  called "$source_root/setup/check" "$mode" --select ''
done
mkdir -p "$XDG_BIN_HOME"
ln -s "$dots" "$XDG_BIN_HOME/dots"
"$bash_bin" "$XDG_BIN_HOME/dots" install "${args[@]}"
called "$source_root/setup/install" "${args[@]}"
DELEGATE_STATUS=42 fails "$bash_bin" "$dots" install
fails "$bash_bin" "$dots" setup --dotfiles > "$case_root/error" 2>&1
assert grep -q DOTSYS_REPO_HOME "$case_root/error"
"$bash_bin" "$dots" --help > "$case_root/help"
assert grep -q 'Neither install nor check provisions' "$case_root/help"
fails "$bash_bin" "$dots" not-a-command > "$case_root/error" 2>&1
untouched

fixture delegates
# Automatic discovery is a real sibling path, not a fixed namespace/home.
sys_root="${source_root%/*}/dotsys"
spy "$sys_root/shared/install.sh"
spy "$sys_root/shared/brew/init.sh"
"$bash_bin" "$source_root/setup/brew/init.sh"
called "$sys_root/shared/brew/init.sh"
for name in --arch --void --dotvim --dotshell --dotfiles --help -h; do
  "$bash_bin" "$dots" setup "$name"
  called "$sys_root/shared/install.sh" setup --dotfiles-root "$source_root" "$name"
done
for platform in arch void macos wsl; do
  "$bash_bin" "$dots" setup --dotsys "$platform"
  called "$sys_root/shared/install.sh" setup --dotfiles-root "$source_root" --dotsys "$platform"
done
setup_args=(--dotvim --dotshell --dotfiles --platform arch --full-machine
  --dotfiles-root "$source_root/explicit" --dotvim-root "$case_root/vim" --dotshell-root "$case_root/shell"
  --home "$HOME" --user fixture --xdg-config-home "$XDG_CONFIG_HOME" --xdg-data-home "$XDG_DATA_HOME"
  --xdg-state-home "$XDG_STATE_HOME" --xdg-cache-home "$XDG_CACHE_HOME" --xdg-bin-home "$XDG_BIN_HOME"
  --select '' --wezterm-destination "$HOME/host file" --save --adopt "$HOME/adopt" --replace "$HOME/replace"
  --helper-adopt "$HOME/helper a" --helper-replace "$HOME/helper r")
"$bash_bin" "$dots" setup "${setup_args[@]}"
called "$sys_root/shared/install.sh" setup --dotfiles-root "$source_root" "${setup_args[@]}"
export DOTSYS_REPO_HOME="$case_root/custom stable dotsys"
spy "$DOTSYS_REPO_HOME/shared/install.sh"
spy "$DOTSYS_REPO_HOME/shared/brew/init.sh"
"$bash_bin" "$dots" setup --dotvim --dotshell
called "$DOTSYS_REPO_HOME/shared/install.sh" setup --dotfiles-root "$source_root" --dotvim --dotshell
DELEGATE_STATUS=43 fails "$bash_bin" "$dots" setup --dotfiles
for entry in "$source_root/setup/brew/init.sh" "$source_root/bin/utilities/brew/init"; do
  for option in --skip-bundles --no-confirm --help -h; do
    "$bash_bin" "$entry" "$option"
    called "$DOTSYS_REPO_HOME/shared/brew/init.sh" "$option"
  done
  "$bash_bin" "$entry" --skip-bundles --no-confirm
  called "$DOTSYS_REPO_HOME/shared/brew/init.sh" --skip-bundles --no-confirm
done
"$bash_bin" "$source_root/bin/utility" brew init --skip-bundles --no-confirm
called "$DOTSYS_REPO_HOME/shared/brew/init.sh" --skip-bundles --no-confirm
ln -s "$source_root/setup/brew/init.sh" "$case_root/brew-entry"
"$bash_bin" "$case_root/brew-entry" --no-confirm
called "$DOTSYS_REPO_HOME/shared/brew/init.sh" --no-confirm
DELEGATE_STATUS=44 fails "$bash_bin" "$source_root/setup/brew/init.sh"
export DOTSYS_REPO_HOME="$case_root/missing"
fails "$bash_bin" "$dots" setup --dotvim > "$case_root/error" 2>&1
assert grep -q DOTSYS_REPO_HOME "$case_root/error"
fails "$bash_bin" "$source_root/setup/brew/init.sh" --no-confirm > "$case_root/error" 2>&1
assert grep -q DOTSYS_REPO_HOME "$case_root/error"
export DOTSYS_REPO_HOME=relative
fails "$bash_bin" "$dots" setup --arch > "$case_root/error" 2>&1
untouched

fixture remote
remote="$project_root/setup/remote/init.sh"
local_remote="$case_root/local remote"
mkdir -p "$local_remote/setup"
spy "$local_remote/setup/install"
git -C "$local_remote" init -q
git -C "$local_remote" add setup/install
# Disposable source commit only: no Git identity/config/signing settings are changed.
tree=$(git -C "$local_remote" write-tree)
commit=$(GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid \
  GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid \
  git -C "$local_remote" commit-tree "$tree" -m fixture)
git -C "$local_remote" update-ref HEAD "$commit"
destination="$case_root/acquired source"
"$bash_bin" "$remote" --source "$local_remote" --destination "$destination" -- "${args[@]}" > "$case_root/output" 2>&1
called "$destination/setup/install" "${args[@]}"
assert test "$(git -C "$destination" rev-parse HEAD)" = "$commit"
printf 'keep\n' > "$destination/user-file"
fails "$bash_bin" "$remote" --source "$local_remote" --destination "$destination" > "$case_root/error" 2>&1
assert grep -q 'Install explicitly:' "$case_root/error"
assert grep -q 'Update explicitly:' "$case_root/error"
assert test "$(cat "$destination/user-file")" = keep
assert test "$(git -C "$destination" rev-parse HEAD)" = "$commit"
# A .git file (worktree-style destination) is also preserved, without Git conversion.
mkdir "$case_root/worktree"
printf 'gitdir: fixture\n' > "$case_root/worktree/.git"
fails "$bash_bin" "$remote" --destination "$case_root/worktree" > "$case_root/error" 2>&1
assert grep -q 'Existing checkout' "$case_root/error"
mkdir "$case_root/nonempty"
printf 'hidden sentinel\n' > "$case_root/nonempty/.private"
fails "$bash_bin" "$remote" --destination "$case_root/nonempty" > "$case_root/error" 2>&1
assert test "$(cat "$case_root/nonempty/.private")" = 'hidden sentinel'
assert test ! -e "$case_root/nonempty/.git"
printf 'file sentinel\n' > "$case_root/file"
fails "$bash_bin" "$remote" --destination "$case_root/file" > "$case_root/error" 2>&1
assert test "$(cat "$case_root/file")" = 'file sentinel'
ln -s "$case_root/nonempty" "$case_root/symlink"
fails "$bash_bin" "$remote" --destination "$case_root/symlink" > "$case_root/error" 2>&1
assert test -L "$case_root/symlink"
fails "$bash_bin" "$remote" --destination "$case_root/symlink/" > "$case_root/error" 2>&1
assert grep -q "symlink destination" "$case_root/error"
mkdir "$case_root/empty"
"$bash_bin" "$remote" --source "$local_remote" --destination "$case_root/empty" --check > "$case_root/output" 2>&1
called "$case_root/empty/setup/install" --check
# Installation failure must not invoke uninstall/delete acquired source or private state.
DELEGATE_STATUS=45 fails "$bash_bin" "$remote" --source "$local_remote" --destination "$case_root/failed" > "$case_root/error" 2>&1
assert test -f "$case_root/failed/setup/install"
assert test -d "$case_root/failed/.git"
assert grep -q 'No automatic rollback' "$case_root/error"
fails "$bash_bin" "$remote" --source https://untrusted.invalid/repo --destination "$case_root/rejected" > "$case_root/error" 2>&1
assert test ! -e "$case_root/rejected"
fails "$bash_bin" "$remote" --destination > "$case_root/error" 2>&1
fails "$bash_bin" "$remote" --destination relative > "$case_root/error" 2>&1
mkdir "$case_root/no-git"
PATH="$case_root/no-git" fails "$bash_bin" "$remote" > "$case_root/error" 2>&1
assert grep -q 'Git is required' "$case_root/error"
"$bash_bin" "$remote" --help > "$case_root/help"
"$bash_bin" "$project_root/setup/remote/configure_env.sh" > "$case_root/identity"
assert grep -q 'separate' "$case_root/identity"
untouched

fixture actual-checks
# Exercise the completed configuration checker/installer, never the legacy updater.
"$bash_bin" "$project_root/bin/autoload/dots" check prerequisites --select '' > "$case_root/output" 2>&1
"$bash_bin" "$project_root/bin/autoload/dots" install --check --select '' >> "$case_root/output" 2>&1
assert test ! -e "$HOME/.bashrc"
assert test ! -e "$XDG_CONFIG_HOME/git"
assert test ! -e "$XDG_CONFIG_HOME/claude"
assert test ! -e "$XDG_CONFIG_HOME/opencode"
assert test ! -e "$XDG_CONFIG_HOME/dotsys"
fails grep -q entrypoint-secret "$case_root/output"
untouched

fixture optional-and-completion
"$bash_bin" "$project_root/bin/utilities/misc/bitwarden" --help > "$case_root/help"
# Restricted executable lookup proves missing optional commands fail before any vault read.
mkdir "$case_root/minimal"
ln -s "$bash_bin" "$case_root/minimal/bash"
PATH="$case_root/minimal" fails "$bash_bin" "$project_root/bin/utilities/misc/bitwarden" items > "$case_root/error" 2>&1
assert grep -q 'Missing optional command bw' "$case_root/error"
ln -s "$case_root/fakes/bw" "$case_root/minimal/bw"
PATH="$case_root/minimal" fails "$bash_bin" "$project_root/bin/utilities/misc/bitwarden" items > "$case_root/error" 2>&1
assert grep -q 'Missing optional command jq' "$case_root/error"
ln -s "$case_root/fakes/bw" "$case_root/minimal/jq"
PATH="$case_root/minimal" fails "$bash_bin" "$project_root/bin/utilities/misc/bitwarden" items > "$case_root/error" 2>&1
assert grep -q 'Missing optional command fzf' "$case_root/error"
source "$project_root/bash/env/completions/dots_completion.bash"
COMP_WORDS=(dots setup --); COMP_CWORD=2; _dots_completions
for name in --arch --void --dotsys --dotfiles --dotvim --dotshell --helper-adopt --helper-replace; do
  assert test "${COMPREPLY[*]#*"$name"}" != "${COMPREPLY[*]}"
done
COMP_WORDS=(dots setup --dotsys ''); COMP_CWORD=3; _dots_completions
assert test "${COMPREPLY[*]}" = 'arch void macos wsl'
COMP_WORDS=(dots install --); COMP_CWORD=2; _dots_completions
for name in --check --save --adopt --replace; do
  assert test "${COMPREPLY[*]#*"$name"}" != "${COMPREPLY[*]}"
done
COMP_WORDS=(dots check ''); COMP_CWORD=2; _dots_completions
assert test "${COMPREPLY[*]#*readiness}" != "${COMPREPLY[*]}"
fails test "${COMPREPLY[*]#*--save}" != "${COMPREPLY[*]}"
brew_complete() { source "$project_root/bash/env/completions/brew_init"; }
COMP_WORDS=(utility brew init --skip-bundles --); COMP_CWORD=4; brew_complete
assert test "${COMPREPLY[*]}" = '--help --skip-bundles --no-confirm'
untouched
printf 'entrypoints test passed (fixtures only; no real-host acceptance)\n'
