#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-install-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
base_path=$PATH
export PROJECT_ROOT="$project_root" TEST_ROOT="$test_root"

fixture() {
  local name=$1
  export HOME="$test_root/$name/home" XDG_CONFIG_HOME="$test_root/$name/config"
  export XDG_DATA_HOME="$test_root/$name/data" XDG_CACHE_HOME="$test_root/$name/cache"
  export XDG_STATE_HOME="$test_root/$name/state" XDG_BIN_HOME="$test_root/$name/bin"
  export XDG_RUNTIME_DIR="$test_root/$name/runtime" BREW_PATH="$test_root/$name/brew"
  export SOURCE="$test_root/$name/source" TEST_OS=arch
  export PATH="$test_root/$name/fakes:$base_path" TMPDIR="$test_root/$name/tmp"
  export TMP="$TMPDIR" TEMP="$TMPDIR"
  unset DOTS_INSTALL_SELECTION DOTS_INSTALL_WEZTERM_DESTINATION
  mkdir -p "$HOME" "$SOURCE" "$test_root/$name/fakes" "$TMPDIR"
  # Only explicit public manifest sources; never recursively copy config/state.
  python3 -I -B - <<'PY'
import os, pathlib, shutil, sys
root, source = pathlib.Path(os.environ['PROJECT_ROOT']), pathlib.Path(os.environ['SOURCE'])
sys.path[:0] = [str(root/'dotbot/src'), str(root/'dotbot/lib/pyyaml/lib')]
from dotbot.config import ConfigReader
manifests = ['setup/install.conf.yaml'] + ['setup/profiles/'+name+'.conf.yaml' for name in
    ('native-linux', 'native-macos', 'sway', 'macos-desktop', 'karabiner', 'alfred', 'wsl-integration')]
files = ['config/wezterm/wezterm.lua'] + manifests + ['setup/'+name for name in ('install', 'uninstall', 'restore', 'common.sh', 'requirements.sh', 'configuration.py', 'managed.py', 'ssh/init.sh')]
files += ['bash/env/'+name+'.sh' for name in ('xdg', 'path', 'brew')]
for task in ConfigReader([str(root/p) for p in manifests]).get_config():
    files += list(task.get('link', {}).values())
for p in set(files):
    (source/p).parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(root/p, source/p)
(source/'dotbot').symlink_to(root/'dotbot', target_is_directory=True)
(source/'bin/autoload/os').write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$TEST_OS"\n')
(source/'bin/autoload/os').chmod(0o755)
PY
  local tool
  for tool in sudo brew pacman xbps-install systemctl sv ssh-add bw gh mise; do
    printf '#!/usr/bin/env bash\nprintf "called\\n" >> "%s"\nexit 99\n' "$test_root/$name/external-operations" > "$test_root/$name/fakes/$tool"
    chmod +x "$test_root/$name/fakes/$tool"
  done
}
assert() { "$@" || { printf 'Assertion failed: %s\n' "$*" >&2; exit 1; }; }
fails() { if "$@"; then printf 'Expected failure: %s\n' "$*" >&2; exit 1; fi; }
install_config() { bash --noprofile --norc "$SOURCE/setup/install" "$@"; }
uninstall_config() { bash --noprofile --norc "$SOURCE/setup/uninstall" "$@"; }
python_test() { python3 -I -B - "$project_root/setup"; }

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  fixture fresh
  fails install_config --check --uninstall
  fails install_config --backup not-a-restore
  install_config --check
  assert test ! -e "$XDG_CONFIG_HOME"
  assert test ! -e "$XDG_STATE_HOME"
  install_config
  assert test "$(readlink "$HOME/.bashrc")" = "$SOURCE/config/bashrc"
  assert test "$(readlink "$XDG_CONFIG_HOME/git/config")" = "$SOURCE/config/git/config"
  assert test "$(readlink "$XDG_CONFIG_HOME/foot/foot.ini")" = "$SOURCE/config/foot/foot.ini"
  assert test -L "$XDG_CONFIG_HOME/ghostty/config"
  assert test ! -e "$XDG_CONFIG_HOME/sway"
  assert test ! -e "$XDG_CONFIG_HOME/claude"
  assert test ! -e "$XDG_CONFIG_HOME/opencode"
  assert test ! -e "$XDG_CONFIG_HOME/hypr"
  assert test ! -e "$XDG_CONFIG_HOME/dots/env"
  assert test ! -e "$HOME/.ssh/github"
  assert test "$(readlink "$HOME/.ssh/dots-client.conf")" = "$SOURCE/config/ssh/client.conf"
  ledger=$(sha256sum "$XDG_STATE_HOME/dots/managed.json")
  link_inode=$(stat -c %i "$HOME/.bashrc")
  install_config
  assert test "$ledger" = "$(sha256sum "$XDG_STATE_HOME/dots/managed.json")"
  assert test "$link_inode" = "$(stat -c %i "$HOME/.bashrc")"
  install_config --select sway
  assert test -L "$XDG_CONFIG_HOME/sway/config"
  assert test -L "$XDG_BIN_HOME/rofi-start"
  mkdir -p "$XDG_CONFIG_HOME/tmux/plugins/private"
  printf 'private plugin\n' > "$XDG_CONFIG_HOME/tmux/plugins/private/state"
  install_config --select ''
  assert test ! -e "$XDG_CONFIG_HOME/sway/config"
  assert test -f "$XDG_CONFIG_HOME/tmux/plugins/private/state"
  uninstall_config
  assert test ! -L "$HOME/.bashrc"
  assert test -f "$XDG_CONFIG_HOME/tmux/plugins/private/state"
  assert test -d "$XDG_STATE_HOME/dots/backups"
  assert test -f "$SOURCE/config/bashrc"
  assert test ! -e "$test_root/fresh/external-operations"

  fixture macos
  export TEST_OS=macos
  install_config
  assert test -L "$XDG_CONFIG_HOME/ghostty/config"
  assert test ! -e "$XDG_CONFIG_HOME/foot"
  assert test ! -e "$XDG_CONFIG_HOME/aerospace"
  install_config --select macos-desktop
  assert test -L "$XDG_CONFIG_HOME/aerospace/aerospace.toml"
  assert test -L "$XDG_CONFIG_HOME/sketchybar/sketchybarrc"
  assert test ! -e "$XDG_CONFIG_HOME/karabiner"
  assert test ! -e "$XDG_CONFIG_HOME/alfred"
  install_config --select macos-desktop,karabiner,alfred
  assert test -L "$XDG_CONFIG_HOME/karabiner/karabiner.json"
  assert test -L "$XDG_CONFIG_HOME/alfred/take-screenshot.alfredworkflow"

  fixture wsl
  export TEST_OS=wsl
  install_config --select wsl-integration --save
  assert test -L "$XDG_BIN_HOME/windows-open"
  assert test -L "$XDG_BIN_HOME/windows-clipboard"
  install_config
  assert test ! -e "$XDG_CONFIG_HOME/wezterm"
  assert test ! -e "$XDG_CONFIG_HOME/ghostty"
  ledger=$(sha256sum "$XDG_STATE_HOME/dots/managed.json")
  fails install_config --wezterm-destination "$HOME/host/wezterm.lua"
  assert test "$ledger" = "$(sha256sum "$XDG_STATE_HOME/dots/managed.json")"
  assert test ! -e "$HOME/host"

  # Candidate planning inspects incoming sources but keeps stable link targets.
  fixture candidate
  python_test <<'PY'
import os, sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import configuration, managed
root = os.environ['SOURCE']
env = dict(os.environ, DOTS_SOURCE_ROOT=root, DOTS_INSTALL_ROOT=root+'/stable',
           DOTS_OS='arch', DOTS_SELECTION='', DOTS_SAVE='0', DOTS_WEZTERM_DESTINATION='',
           GNUPGHOME=os.environ['XDG_DATA_HOME']+'/gnupg',
           BASHRC=os.environ['XDG_CONFIG_HOME']+'/bash/bashrc',
           BASH_PROFILE=os.environ['XDG_CONFIG_HOME']+'/bash/bash_profile')
a = configuration.plan(env)
assert all(x['target'].startswith(root+'/stable/') for x in a if x['kind']=='link')
managed.check(a, 'dots', os.environ['XDG_STATE_HOME']+'/dots')
assert not Path(os.environ['XDG_STATE_HOME']).exists()
# The actual engine is required, not a parallel os.symlink implementation.
from unittest.mock import patch
from dotbot.plugins.link import Link
p = os.environ['HOME']+'/literal $NAME link'
original = Link._link
calls = []
def observed(self, *args, **kwargs):
    calls.append(args)
    return original(self, *args, **kwargs)
with patch.object(Link, '_link', observed):
    managed.apply([dict(kind='link', destination=p, target=root+'/config/bashrc')],
                  'dotsys', os.environ['XDG_STATE_HOME']+'/dotsys')
assert len(calls) == 1 and os.readlink(p) == root+'/config/bashrc'
PY
  printf 'install test passed\n'
fi
