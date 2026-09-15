#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-update-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
base_path=$PATH
# Even fixture Git setup has no access to the real HOME, XDG, temp or credentials.
export HOME="$test_root/bootstrap/home" XDG_CONFIG_HOME="$test_root/bootstrap/config"
export XDG_DATA_HOME="$test_root/bootstrap/data" XDG_CACHE_HOME="$test_root/bootstrap/cache"
export XDG_STATE_HOME="$test_root/bootstrap/state" XDG_BIN_HOME="$test_root/bootstrap/bin"
export XDG_RUNTIME_DIR="$test_root/bootstrap/runtime" TMPDIR="$test_root/bootstrap/tmp"
export TMP="$TMPDIR" TEMP="$TMPDIR" BREW_PATH="$test_root/bootstrap/brew"
mkdir -p "$HOME" "$TMPDIR"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_TERMINAL_PROMPT=0
export GIT_ALLOW_PROTOCOL=file GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture@example.invalid
export PROJECT_ROOT="$project_root" TEST_ROOT="$test_root"
assert() { "$@" || { printf 'Assertion failed: %s\n' "$*" >&2; exit 1; }; }
gitq() { git "$@" >/dev/null 2>&1; }
commit() { gitq -C "$1" add -A; gitq -C "$1" commit -m "$2"; }
# Tracked archives only; never copy ignored application/private state. Nested
# dependency repos are LOCAL fixture history, not changes to the real submodules.
for name in yaml dotbot seed; do
  mkdir -p "$test_root/$name"
  case $name in
    yaml) source_repo="$project_root/dotbot/lib/pyyaml" ;;
    dotbot) source_repo="$project_root/dotbot" ;;
    seed) source_repo="$project_root" ;;
  esac
  git -C "$source_repo" archive HEAD | tar -x -C "$test_root/$name"
  gitq -C "$test_root/$name" init -b main
  if [[ $name == dotbot ]]; then
    rmdir "$test_root/dotbot/lib/pyyaml"
    gitq -C "$test_root/dotbot" submodule add "$test_root/yaml" lib/pyyaml
  elif [[ $name == seed ]]; then
    rmdir "$test_root/seed/dotbot"
    # Overlay ONLY this slice's tracked/new implementation under test.
    for path in bin/autoload/dots .gitmodules setup/check setup/common.sh setup/configuration.py setup/update.sh; do
      cp "$project_root/$path" "$test_root/seed/$path"
    done
    gitq -C "$test_root/seed" submodule add --force "$test_root/dotbot" dotbot
    printf '#!/usr/bin/env bash\nprintf "arch\\n"\n' > "$test_root/seed/bin/autoload/os"
    printf '[tools]\nnode = "22.0.0"\npython = "latest"\n' > "$test_root/seed/config/mise/config.toml"
  fi
  commit "$test_root/$name" baseline
done
base=$(git -C "$test_root/seed" rev-parse HEAD)
dotbot_pin=$(git -C "$test_root/dotbot" rev-parse HEAD)
# Available upstream Dotbot advancement must never be selected independently.
printf 'not selected\n' > "$test_root/dotbot/new-upstream"
commit "$test_root/dotbot" unselected

fixture() {
  local name=$1 tool
  case_root="$test_root/$name"
  export HOME="$case_root/home" XDG_CONFIG_HOME="$case_root/config" XDG_DATA_HOME="$case_root/data"
  export XDG_CACHE_HOME="$case_root/cache" XDG_STATE_HOME="$case_root/state" XDG_BIN_HOME="$case_root/bin"
  export XDG_RUNTIME_DIR="$case_root/runtime" TMPDIR="$case_root/tmp" BREW_PATH="$case_root/brew"
  export TMP="$TMPDIR" TEMP="$TMPDIR" PATH="$case_root/fakes:$base_path"
  export DOTFILES_REPO_HOME=/nonexistent/stale-primary DOTSYS_REPO_HOME="$case_root/dotsys"
  unset DOTS_INSTALL_SELECTION DOTS_INSTALL_WEZTERM_DESTINATION REPO_NAMESPACE
  mkdir -p "$HOME" "$TMPDIR" "$case_root/fakes" "$XDG_CONFIG_HOME/dots" "$DOTSYS_REPO_HOME/shared/mise"
  active="$case_root/actual-checkout"
  upstream="$case_root/incoming"
  gitq clone --recurse-submodules "$test_root/seed" "$upstream"
  gitq clone --recurse-submodules "$upstream" "$active"
  printf 'export FAKE_PRIVATE_SECRET=secret-update-sentinel\nprintf "%%s\\n" "$FAKE_PRIVATE_SECRET"\nexport DOTFILES_REPO_HOME=/stale/saved\n' > "$XDG_CONFIG_HOME/dots/env"
  for tool in tmux dvim nvim delta ghostty foot sway swaymsg swaynag rofi autotiling-rs swayidle swaylock \
    wl-copy wl-paste wl-clip-persist cliphist kanshi qs dshell systemctl loginctl uwsm \
    sudo brew pacman xbps-install sv bw gh curl ssh-add; do
    printf '#!/usr/bin/env bash\nprintf "called %%s\\n" "$0" >> %q\nexit 99\n' "$case_root/operations" > "$case_root/fakes/$tool"
    chmod +x "$case_root/fakes/$tool"
  done
  cp "$case_root/fakes/sudo" "$DOTSYS_REPO_HOME/shared/mise/init.sh"
  cat > "$case_root/fakes/mise" <<'SH'
#!/usr/bin/env bash
[[ $MISE_NO_CONFIG == 1 && $MISE_OFFLINE == 1 && $MISE_NO_HOOKS == 1 && $MISE_SAFE == 1 ]] || exit 91
[[ $MISE_DATA_DIR == /dev/null && $MISE_STATE_DIR == /dev/null && $MISE_CACHE_DIR == /dev/null && $MISE_LOG_FILE == /dev/null && $MISE_TMP_DIR == /dev/null ]] || exit 92
[[ -z ${FAKE_PRIVATE_SECRET+x} && -z ${BASH_ENV+x} ]] || exit 93
if [[ $3 == config ]]; then
  if [[ -f $HOME/trigger ]]; then
    target=$(cat "$HOME/trigger")
    printf '\n# concurrent edit\n' >> "$target"
    rm "$HOME/trigger"
  fi
  sed -n '/ = /p' "$7"
elif [[ $3 == ls && $4 == --installed && $5 == --offline && $6 == --json ]]; then
  printf '[{"version":"22.0.0","installed":true}]\n'
else
  exit 94
fi
SH
  chmod +x "$case_root/fakes/mise"
  bash "$active/setup/install" > "$case_root/install-output" 2>&1
  link_inode=$(stat -c %i "$HOME/.bashrc")
  old_content=$(sha256sum "$HOME/.bashrc")
  env_before=$(sha256sum "$XDG_CONFIG_HOME/dots/env")
  index_before=$(sha256sum "$active/.git/index")
  ledger_before=$(sha256sum "$XDG_STATE_HOME/dots/managed.json")
}
incoming() {
  printf '\n# accepted incoming\n' >> "$upstream/config/bashrc"
  commit "$upstream" incoming
  target=$(git -C "$upstream" rev-parse HEAD)
}
update() { bash "$active/bin/autoload/dots" update "$@" > "$case_root/output" 2>&1; }
pass_update() { if ! update "$@"; then cat "$case_root/output"; exit 1; fi; }
fail_update() { if update "$@"; then cat "$case_root/output"; printf 'Expected blocked update\n' >&2; exit 1; fi; }
preserved() {
  assert test "$(git -C "$active" rev-parse HEAD)" = "$base"
  assert test "$old_content" = "$(sha256sum "$HOME/.bashrc")"
  assert test "$link_inode" = "$(stat -c %i "$HOME/.bashrc")"
  assert test "$(readlink "$HOME/.bashrc")" = "$active/config/bashrc"
  assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
  assert test "$ledger_before" = "$(sha256sum "$XDG_STATE_HOME/dots/managed.json")"
}
safe_output() {
  assert test ! -e "$case_root/operations"
  assert test -z "$(grep -l secret-update-sentinel "$case_root/"*output || true)"
  assert test -z "$(find "$active" "$XDG_CONFIG_HOME" -name '*.pyc' -print)"
  assert test "$(git -C "$active/dotbot" rev-parse HEAD)" = "$dotbot_pin"
}

fixture clean
incoming
# A future stable file is absent now but must be validated from candidate content.
printf 'future file\n' > "$upstream/config/future"
printf '\n- link:\n    ${XDG_CONFIG_HOME}/future/config: config/future\n' >> "$upstream/setup/install.conf.yaml"
commit "$upstream" future
target=$(git -C "$upstream" rev-parse HEAD)
# Direct candidate check: no changes ANYWHERE in configuration, state, caches or source.
readonly_snapshot() {
  find "$case_root" -printf '%P %y %m %l\n' | LC_ALL=C sort
  find "$case_root" -type f -not -path '*/.git/*' -exec sha256sum {} + | LC_ALL=C sort
}
before=$(readonly_snapshot)
output=$(bash "$upstream/setup/check" candidate --install-root "$active" 2>&1) || { printf '%s\n' "$output"; exit 1; }
assert test "$before" = "$(readonly_snapshot)"
assert test ! -e "$active/config/future"
pass_update
assert test "$(git -C "$active" rev-parse HEAD)" = "$target"
assert test "$(cat "$XDG_CONFIG_HOME/future/config")" = 'future file'
assert test "$(readlink "$XDG_CONFIG_HOME/future/config")" = "$active/config/future"
assert test "$link_inode" = "$(stat -c %i "$HOME/.bashrc")"
assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
assert test "$(git -C "$active" rev-list --count "$base..HEAD")" = 2
assert test -z "$(find "$XDG_STATE_HOME/dots" -maxdepth 1 -name 'update-*' -print)"
safe_output
printf 'ok clean FF, candidate read-only, future stable links, pinned Dotbot\n'

for kind in unstaged staged untracked divergence detached upstream dirty-submodule moved-submodule dirty-recursive uninitialized; do
  fixture "$kind"
  incoming
  case $kind in
    unstaged) printf '\nlocal unstaged\n' >> "$active/README.md" ;;
    staged) printf 'local staged\n' > "$active/local-file"; gitq -C "$active" add local-file ;;
    untracked) printf 'untracked contents\n' > "$active/config/new"; printf 'incoming conflict\n' > "$upstream/config/new"; commit "$upstream" conflict ;;
    divergence) printf 'local history\n' > "$active/local-file"; commit "$active" local ;;
    detached) gitq -C "$active" checkout --detach ;;
    upstream) gitq -C "$active" branch --unset-upstream ;;
    dirty-submodule) gitq -C "$active" config submodule.dotbot.ignore all; printf 'local dotbot\n' >> "$active/dotbot/README.md" ;;
    moved-submodule) gitq -C "$active/dotbot" fetch origin; gitq -C "$active/dotbot" checkout origin/main ;;
    dirty-recursive) printf 'local YAML\n' >> "$active/dotbot/lib/pyyaml/README.md" ;;
    uninitialized) gitq -C "$active" submodule deinit dotbot ;;
  esac
  case $kind in
    unstaged) changed="$active/README.md" ;;
    staged|divergence) changed="$active/local-file" ;;
    untracked) changed="$active/config/new" ;;
    dirty-submodule) changed="$active/dotbot/README.md" ;;
    dirty-recursive) changed="$active/dotbot/lib/pyyaml/README.md" ;;
    *) changed="$active/config/bashrc" ;;
  esac
  changed_before=$(sha256sum "$changed")
  expected=$(git -C "$active" rev-parse HEAD)
  index_before=$(sha256sum "$active/.git/index")
  status_before=$(git -C "$active" status --porcelain --ignore-submodules=none --untracked-files=all)
  fail_update
  assert test "$(git -C "$active" rev-parse HEAD)" = "$expected"
  assert test "$index_before" = "$(sha256sum "$active/.git/index")"
  assert test "$status_before" = "$(git -C "$active" status --porcelain --ignore-submodules=none --untracked-files=all)"
  assert test "$changed_before" = "$(sha256sum "$changed")"
  assert test "$old_content" = "$(sha256sum "$HOME/.bashrc")"
  assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
  assert test ! -e "$case_root/operations"
done
printf 'ok dirty/index/untracked/divergent/detached/upstream/recursive submodule rejection\n'

fixture pinned-advance
incoming
gitq -C "$upstream/dotbot" fetch origin
gitq -C "$upstream/dotbot" checkout origin/main
gitq -C "$upstream" add dotbot
commit "$upstream" selected-dotbot-pin
target=$(git -C "$upstream" rev-parse HEAD)
selected_pin=$(git -C "$upstream/dotbot" rev-parse HEAD)
pass_update
assert test "$(git -C "$active" rev-parse HEAD)" = "$target"
assert test "$(git -C "$active/dotbot" rev-parse HEAD)" = "$selected_pin"
assert test "$(cat "$active/dotbot/new-upstream")" = 'not selected'
assert test "$(git -C "$active" rev-list --count "$base..HEAD")" = 2
assert test -z "$(git -C "$active" status --porcelain --ignore-submodules=none)"
assert test ! -e "$case_root/operations"
printf 'ok incoming superproject-selected Dotbot pin advances without independent commits\n'

fixture unavailable-check
incoming
gitq -C "$upstream" rm setup/check
commit "$upstream" unavailable-check
fail_update
preserved
assert test "$index_before" = "$(sha256sum "$active/.git/index")"
safe_output
printf 'ok unavailable candidate check fails closed\n'

fixture requirements
incoming
printf '[tools]\nnode = "99.0.0"\n' > "$upstream/config/mise/config.toml"
commit "$upstream" requirements
target=$(git -C "$upstream" rev-parse HEAD)
fail_update
preserved
assert test "$index_before" = "$(sha256sum "$active/.git/index")"
retained=$(find "$XDG_STATE_HOME/dots" -maxdepth 1 -name 'update-*')
assert test -f "$retained/source/config/mise/config.toml"
assert test "$(git -C "$retained/source" rev-parse HEAD)" = "$target"
assert grep -Fq 'shared/mise/init.sh --config' "$case_root/output"
assert grep -Fq "$retained/source/config/mise/config.toml" "$case_root/output"
assert test ! -e "$retained/source/bin/utilities/ac"
safe_output
printf 'ok unmet incoming requirements retain exact preparation config without advancement\n'

fixture conflict
incoming
printf 'future file\n' > "$upstream/config/future"
printf '\n- link:\n    ${XDG_CONFIG_HOME}/future/config: config/future\n' >> "$upstream/setup/install.conf.yaml"
commit "$upstream" conflict
mkdir -p "$XDG_CONFIG_HOME/future"
printf 'private conflict\n' > "$XDG_CONFIG_HOME/future/config"
fail_update
preserved
assert test "$(cat "$XDG_CONFIG_HOME/future/config")" = 'private conflict'
assert test ! -L "$XDG_CONFIG_HOME/future/config"
assert test "$index_before" = "$(sha256sum "$active/.git/index")"
safe_output
printf 'ok candidate configuration conflict preserves source/index/live configuration\n'

fixture retargeted-link
incoming
printf 'user-owned referent\n' > "$HOME/private-bashrc"
rm "$HOME/.bashrc"
ln -s "$HOME/private-bashrc" "$HOME/.bashrc"
retargeted_inode=$(stat -c %i "$HOME/.bashrc")
fail_update
assert test "$(git -C "$active" rev-parse HEAD)" = "$base"
assert test "$index_before" = "$(sha256sum "$active/.git/index")"
assert test "$(readlink "$HOME/.bashrc")" = "$HOME/private-bashrc"
assert test "$(cat "$HOME/private-bashrc")" = 'user-owned referent'
assert test "$retargeted_inode" = "$(stat -c %i "$HOME/.bashrc")"
safe_output
printf 'ok retargeted owned links remain untouched after candidate rejection\n'

fixture helpers
# Stable external registrations are not copied to the candidate or mistaken for sources.
mkdir -p "$case_root/helpers"
for helper in desktop-session/launch desktop-session/stop desktop-session/finalize kanshi/restart quickshell/restart power/control; do
  mkdir -p "$case_root/helpers/${helper%/*}"
  cp "$case_root/fakes/sudo" "$case_root/helpers/$helper"
done
for category in desktop-session kanshi quickshell power; do
  ln -s "$case_root/helpers/$category" "$active/bin/utilities/$category"
  printf 'bin/utilities/%s\n' "$category" >> "$active/.git/info/exclude"
done
ln -s "$case_root/helpers" "$active/bin/utilities/ac"
# Saved selection and transient override survive bootstrap reload with private root redirection.
printf '\nDOTS_SELECTION=sway\nexport XDG_CACHE_HOME="$HOME/redirected-cache"\n' >> "$XDG_CONFIG_HOME/dots/env"
env_before=$(sha256sum "$XDG_CONFIG_HOME/dots/env")
bash "$active/setup/install" > "$case_root/install-output" 2>&1
incoming
pass_update
assert test -L "$XDG_CONFIG_HOME/sway/config"
assert test "$(readlink "$active/bin/utilities/kanshi")" = "$case_root/helpers/kanshi"
assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
safe_output
printf 'ok saved selection, external helper registrations and redirected machine input\n'

fixture transient
# A saved desktop with unavailable helpers must not defeat explicit core-only inputs.
printf '\nDOTS_SELECTION=sway\n' >> "$XDG_CONFIG_HOME/dots/env"
env_before=$(sha256sum "$XDG_CONFIG_HOME/dots/env")
incoming
pass_update --select ''
assert test ! -e "$XDG_CONFIG_HOME/sway/config"
assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
printf '\n# another incoming\n' >> "$upstream/config/bashrc"
commit "$upstream" environment-choice
export DOTS_INSTALL_SELECTION=''
pass_update
assert test ! -e "$XDG_CONFIG_HOME/sway/config"
assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
safe_output
printf 'ok transient argument/environment choices stay consistent without saving\n'

fixture redirected
# Bootstrap must read the ORIGINAL env location each time, not the resolved root.
export HOME="$case_root/redirected-home" XDG_CONFIG_HOME="$case_root/input-config"
export XDG_STATE_HOME="$case_root/input-state" XDG_DATA_HOME="$case_root/input-data"
export XDG_BIN_HOME="$case_root/input-bin"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/dots"
cat > "$XDG_CONFIG_HOME/dots/env" <<'SH'
export XDG_CONFIG_HOME="$HOME/resolved-config"
export XDG_STATE_HOME="$HOME/resolved-state"
export XDG_DATA_HOME="$HOME/resolved-data"
export XDG_BIN_HOME="$HOME/resolved-bin"
export FAKE_PRIVATE_SECRET=secret-update-sentinel
printf '%s\n' "$FAKE_PRIVATE_SECRET"
SH
bash "$active/setup/install" > "$case_root/install-output" 2>&1
incoming
pass_update
assert test -f "$HOME/resolved-state/dots/managed.json"
assert test ! -e "$case_root/input-state"
assert test ! -e "$HOME/resolved-config/dots/env"
assert test "$(readlink "$HOME/resolved-config/git/config")" = "$active/config/git/config"
assert test "$(readlink "$HOME/.bashrc")" = "$active/config/bashrc"
assert test -z "$(find "$HOME/resolved-state/dots" -maxdepth 1 -name 'update-*' -print)"
safe_output
printf 'ok private env redirects configuration/state roots consistently across check/apply\n'

fixture ignored-conflict
incoming
mkdir -p "$case_root/private-helper"
printf 'private helper\n' > "$case_root/private-helper/value"
ln -s "$case_root/private-helper" "$active/bin/utilities/ac"
mkdir -p "$upstream/bin/utilities/ac"
printf 'incoming\n' > "$upstream/bin/utilities/ac/value"
gitq -C "$upstream" add -f bin/utilities/ac/value
commit "$upstream" ignored-conflict
fail_update
preserved
assert test "$(readlink "$active/bin/utilities/ac")" = "$case_root/private-helper"
assert test "$(cat "$case_root/private-helper/value")" = 'private helper'
printf 'ok ignored external registration source collision fails closed\n'

for kind in concurrent-source concurrent-env concurrent-destination; do
  fixture "$kind"
  incoming
  case $kind in
    concurrent-source) trigger="$active/README.md" ;;
    concurrent-env) trigger="$XDG_CONFIG_HOME/dots/env" ;;
    concurrent-destination) trigger="$HOME/.ssh/config" ;;
  esac
  printf '%s\n' "$trigger" > "$HOME/trigger"
  fail_update
  assert test "$(git -C "$active" rev-parse HEAD)" = "$base"
  assert test "$index_before" = "$(sha256sum "$active/.git/index")"
  assert grep -Fq '# concurrent edit' "$trigger"
  assert test "$old_content" = "$(sha256sum "$HOME/.bashrc")"
  assert test "$link_inode" = "$(stat -c %i "$HOME/.bashrc")"
  safe_output
done
printf 'ok concurrent source, private choices and live destination changes block advancement\n'

fixture batch
incoming
printf '[tools]\nnode = "99.0.0"\n' > "$upstream/config/mise/config.toml"
commit "$upstream" blocked
mkdir -p "$case_root/other-remote"
gitq -C "$case_root/other-remote" init -b main
printf 'old\n' > "$case_root/other-remote/value"
commit "$case_root/other-remote" old
gitq clone "$case_root/other-remote" "$case_root/other"
other_old=$(git -C "$case_root/other" rev-parse HEAD)
printf 'new\n' > "$case_root/other-remote/value"
commit "$case_root/other-remote" new
other_new=$(git -C "$case_root/other-remote" rev-parse HEAD)
fail_update --repo "$case_root/other"
preserved
assert test "$(cat "$case_root/other/value")" = new
assert grep -Fq "$other_old -> $other_new: updated" "$case_root/output"
safe_output
# Default discovery still includes actual dotfiles, and ignores nonrepositories.
export REPO_NAMESPACE="$case_root/namespace"
mkdir -p "$REPO_NAMESPACE/davelens/dot-not-a-repo"
mv "$case_root/other" "$REPO_NAMESPACE/davelens/dotother"
printf 'newer\n' > "$case_root/other-remote/value"
commit "$case_root/other-remote" newer
fail_update
preserved
assert test "$(cat "$REPO_NAMESPACE/davelens/dotother/value")" = newer
assert grep -Fq "$REPO_NAMESPACE/davelens/dotother:" "$case_root/output"
assert test -z "$(grep dot-not-a-repo "$case_root/output" || true)"
printf 'ok blocked dotfiles still permits independent batch success and nonzero summary\n'

fixture partial
incoming
printf '#!/usr/bin/env bash\nexit 71\n' > "$upstream/setup/install"
commit "$upstream" post-advance-failure
target=$(git -C "$upstream" rev-parse HEAD)
fail_update
assert test "$(git -C "$active" rev-parse HEAD)" = "$target"
assert grep -Fq 'PARTIAL advancement; no rollback' "$case_root/output"
assert grep -Fq '# accepted incoming' "$HOME/.bashrc"
assert test "$link_inode" = "$(stat -c %i "$HOME/.bashrc")"
assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
safe_output
printf 'ok post-advance failure reports partial advancement without rollback or auto commits\n'

fixture gitfile
incoming
# Worktree .git is a file, with an actual invoked entrypoint through a symlink.
gitq -C "$active" worktree add "$case_root/worktree" -b linked HEAD
gitq -C "$case_root/worktree" branch --set-upstream-to=origin/main linked
gitq -C "$case_root/worktree" submodule update --init --recursive
active="$case_root/worktree"
# This fixture must install directly into its own fresh live configuration.
export HOME="$case_root/linked-home" XDG_CONFIG_HOME="$case_root/linked-config" XDG_STATE_HOME="$case_root/linked-state"
mkdir -p "$HOME"
export XDG_BIN_HOME="$case_root/linked-bin" XDG_DATA_HOME="$case_root/linked-data"
bash "$active/setup/install" > "$case_root/install-output" 2>&1
ln -s "$active/bin/autoload/dots" "$case_root/invoked-dots"
if ! bash "$case_root/invoked-dots" update > "$case_root/output" 2>&1; then cat "$case_root/output"; exit 1; fi
assert test -f "$active/.git"
assert test "$(git -C "$active" rev-parse HEAD)" = "$target"
assert test "$(readlink "$HOME/.bashrc")" = "$active/config/bashrc"
safe_output
printf 'ok gitfile checkout and symlink invocation ignore stale checkout exports\n'
printf 'update test passed\n'
