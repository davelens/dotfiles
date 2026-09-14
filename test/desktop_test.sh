#!/usr/bin/env bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/install_test.sh"
fixture desktop
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME" "$XDG_RUNTIME_DIR"
export OPERATIONS="$test_root/desktop/operations"
# Every invoked desktop command is a fixture. Nothing reaches a live session.
cat > "$test_root/desktop/fakes/utility" <<'PY'
#!/usr/bin/env python3
import json, os, sys
with open(os.environ['OPERATIONS'], 'a') as f:
    f.write(json.dumps(sys.argv[1:])+'\n')
sys.exit(int(os.environ.get('UTILITY_STATUS', '0')))
PY
cat > "$test_root/desktop/fakes/rofi" <<'SH2'
#!/usr/bin/env bash
if [[ -n ${ROFI_ARGUMENTS:-} ]]; then printf '%s\0' "$@" > "$ROFI_ARGUMENTS"; exit 0; fi
if [[ $* == *Confirmation* ]]; then printf '󰄬 Yes\n'; else printf '%s\n' "$MENU_CHOICE"; fi
SH2
cat > "$test_root/desktop/fakes/fzf" <<'SH2'
#!/usr/bin/env bash
printf '%s\n' "$MENU_CHOICE"
SH2
printf '#!/usr/bin/env bash\nexit 1\n' > "$test_root/desktop/fakes/pgrep"
for tool in uptime hostname; do
  printf '#!/usr/bin/env bash\nprintf "fixture\\n"\n' > "$test_root/desktop/fakes/$tool"
done
chmod +x "$test_root/desktop/fakes/"*
install_config --select sway --save >/dev/null
saved=$(sha256sum "$XDG_CONFIG_HOME/dots/env")
SSH_CONNECTION=fixture install_config >/dev/null
assert test "$saved" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
assert test -L "$XDG_CONFIG_HOME/sway/config"
assert test -L "$XDG_CONFIG_HOME/ghostty/config"
assert test -L "$XDG_CONFIG_HOME/foot/foot.ini"
assert test ! -e "$XDG_CONFIG_HOME/uwsm/env-sway"
for name in hypr waybar wezterm macos karabiner alfred; do assert test ! -e "$XDG_CONFIG_HOME/$name"; done
assert test ! -e "$test_root/desktop/external-operations"
python_test <<'PY'
import os, sys
from pathlib import Path
root = Path(os.environ['PROJECT_ROOT'])
def text(p): return (root/p).read_text()
sway = text('config/sway/config')
assert all(line.startswith('include config.d/') for line in sway.splitlines() if line.startswith('include '))
assert 'set $term       foot' in text('config/sway/config.d/00-variables')
keys = text('config/sway/config.d/50-keybindings')
assert 'desktop-session launch $term' in keys and 'utility kanshi restart' in keys
assert 'desktop-session stop' in keys
assert 'desktop-session finalize' in text('config/sway/config.d/99-finalize')
autostart = text('config/sway/config.d/40-autostart')
assert all(x in autostart for x in ('autotiling-rs','swayidle','swaylock','wl-clip-persist','wl-paste','cliphist'))
assert not any(x in autostart for x in ('firefox','discord','ghostty','wezterm'))
assert "lock 'swaylock -f -c 000000'" in autostart
for p in ('config/sway/config.d/50-keybindings', 'config/sway/config.d/99-finalize',
          'config/kanshi/config', 'config/rofi/powermenu/type-1/powermenu.sh', 'config/waybar/scripts/power-menu.sh'):
    assert not any(x in text(p) for x in ('systemctl','loginctl','~/.local/bin','/home/davelens'))
assert text('config/kanshi/config').count('utility quickshell restart') == 7
mac = text('config/macos/aerospace/aerospace.toml')
assert 'open -a Ghostty' in mac and 'com.mitchellh.ghostty' in mac and 'wezterm' not in mac.lower()
assert 'open -g -a Firefox' in mac and 'open -g -a Discord' in mac
assert 'renderer' not in text('config/ghostty/config')
sys.path.insert(0,sys.argv[1])
import configuration
for platform in ('arch','void','macos','wsl'):
    env = dict(os.environ, DOTS_SOURCE_ROOT=str(root), DOTS_INSTALL_ROOT=str(root),
               DOTS_OS=platform, DOTS_SELECTION='', DOTS_WEZTERM_DESTINATION='', DOTS_SAVE='0',
               BASHRC=os.environ['HOME']+'/.bashrc', BASH_PROFILE=os.environ['HOME']+'/.bash_profile',
               GNUPGHOME=os.environ['XDG_DATA_HOME']+'/gnupg')
    targets = [a.get('target','') for a in configuration.plan(env)]
    assert any(x.endswith('/ghostty/config') for x in targets) == (platform!='wsl')
    assert any(x.endswith('/foot/foot.ini') for x in targets) == (platform in ('arch','void'))
    assert not any('/sway/' in x or '/aerospace/' in x for x in targets)
    if platform=='macos':
        targets=[a.get('target','') for a in configuration.plan(dict(env,DOTS_SELECTION='macos-desktop'))]
        assert any('/aerospace/' in x for x in targets)
        assert not any('/karabiner/' in x or '/alfred/' in x or x.endswith('defaults.sh') for x in targets)
PY
# The session PATH honors explicit roots/workarounds without running mise.
export MISE_DATA_DIR="$XDG_DATA_HOME/custom mise" SUSHI_USE_GST_GTKSINK=explicit
source "$project_root/config/desktop-session/env"
assert test "$SUSHI_USE_GST_GTKSINK" = explicit
assert test "${PATH%%:*}" = "$XDG_BIN_HOME"
export PATH="$test_root/desktop/fakes:$PATH"
assert test ! -e "$test_root/desktop/external-operations"
for MENU_CHOICE in Lock Shutdown Reboot Logout Hibernate Suspend; do
  export MENU_CHOICE
  bash "$project_root/config/waybar/scripts/power-menu.sh"
done
for MENU_CHOICE in '󰌾 Lock' '󰐥 Shutdown' '󰜉 Reboot' '󰍃 Logout' '󰤄 Suspend'; do
  export MENU_CHOICE
  bash "$project_root/config/rofi/powermenu/type-1/powermenu.sh"
done
python_test <<'PY'
import json, os
from pathlib import Path
calls = [json.loads(x) for x in Path(os.environ['OPERATIONS']).read_text().splitlines()]
assert calls == [['power','control',x] for x in ('lock','shutdown','reboot','logout','hibernate','suspend','lock','shutdown','reboot','logout','suspend')]
PY
UTILITY_STATUS=37 MENU_CHOICE=Lock fails bash "$project_root/config/waybar/scripts/power-menu.sh"
UTILITY_STATUS=37 MENU_CHOICE='󰌾 Lock' fails bash "$project_root/config/rofi/powermenu/type-1/powermenu.sh"
export ROFI_ARGUMENTS="$test_root/desktop/rofi-arguments"
XDG_CONFIG_HOME="$test_root/desktop/config with spaces" bash "$project_root/bin/autoload/rofi-start" --theme 'style with spaces' >/dev/null
python_test <<'PY2'
import os
from pathlib import Path
args=Path(os.environ['ROFI_ARGUMENTS']).read_bytes().split(b'\0')[:-1]
assert args[args.index(b'-run-command')+1]==b'desktop-session launch {cmd}'
assert args[args.index(b'-theme')+1].endswith(b'/config with spaces/rofi/launchers/type-1/style with spaces.rasi')
PY2
unset ROFI_ARGUMENTS
# Exercise actual classification, never execute a native capability probe.
source "$project_root/setup/common.sh"
source "$project_root/setup/requirements.sh"
DOTS_SOURCE_ROOT=$SOURCE DOTS_INSTALL_ROOT=$SOURCE DOTS_SELECTION=sway DOTS_OS=arch DOTS_WEZTERM_DESTINATION=''
for helper in desktop-session/launch desktop-session/stop desktop-session/finalize kanshi/restart quickshell/restart power/control; do
  mkdir -p "$SOURCE/bin/utilities/${helper%/*}"
  ln -s "$test_root/desktop/fakes/utility" "$SOURCE/bin/utilities/$helper"
done
dots_prerequisites() { :; }
dots_require_gnu() { :; }
dots_mise_readiness() { :; }
dots_require_command() { [[ $1 != "${MISSING:-}" ]]; }
dots_readiness >/dev/null 2>&1
for MISSING in swayidle swaylock wl-copy wl-paste wl-clip-persist cliphist ghostty foot rofi-start autotiling-rs kanshi qs dshell loginctl uwsm; do
  fails dots_readiness >/dev/null 2>&1
done
for MISSING in grim slurp brightnessctl pactl firefox; do dots_readiness >/dev/null 2>&1; done
DOTS_OS=void MISSING=turnstile-update-runit-env fails dots_readiness >/dev/null 2>&1
DOTS_SELECTION='' MISSING=swaylock dots_readiness >/dev/null 2>&1
printf 'desktop test passed\n'
