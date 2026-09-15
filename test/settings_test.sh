#!/usr/bin/env bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/install_test.sh"
fixture settings
mkdir -p "$XDG_CONFIG_HOME/dots"
python_test <<'PY'
import os
from pathlib import Path
p = Path(os.environ['XDG_CONFIG_HOME'], 'dots/env')
p.write_bytes(b'# Preserve this comment and CRLF\r\n# Non-UTF8 comment: \xff\nPRIVATE_SENTINEL=secret-settings-sentinel\nprintf "%s\\n" "$PRIVATE_SENTINEL"\n')
Path(os.environ['HOME'], 'original-env').write_bytes(p.read_bytes())
PY
output=$(install_config --select sway --save 2>&1)
assert test "${output/secret-settings-sentinel/}" = "$output"
assert test -L "$XDG_CONFIG_HOME/sway/config"
python_test <<'PY'
import os
from pathlib import Path
p = Path(os.environ['XDG_CONFIG_HOME'], 'dots/env')
original = Path(os.environ['HOME'], 'original-env').read_bytes()
assert p.read_bytes().startswith(original)
assert p.read_bytes().count(b'# BEGIN dots installer') == 1
assert b'DOTS_SELECTION=sway\n' in p.read_bytes()
assert b'secret-settings-sentinel' not in Path(os.environ['XDG_STATE_HOME'], 'dots/managed.json').read_bytes()
assert p.stat().st_mode & 0o077 == 0
PY
before=$(sha256sum "$XDG_CONFIG_HOME/dots/env" "$XDG_STATE_HOME/dots/managed.json")
output=$(install_config --save 2>&1)
assert test "${output/secret-settings-sentinel/}" = "$output"
assert test "$before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env" "$XDG_STATE_HOME/dots/managed.json")"
# Transient empty selection deselects files but never rewrites the saved block.
env_before=$(sha256sum "$XDG_CONFIG_HOME/dots/env")
install_config --select '' >/dev/null
assert test ! -e "$XDG_CONFIG_HOME/sway/config"
assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
install_config >/dev/null
assert test -L "$XDG_CONFIG_HOME/sway/config"
# Explicit empty selection is retained on subsequent headless installs.
install_config --select '' --save >/dev/null
install_config >/dev/null
assert test ! -e "$XDG_CONFIG_HOME/sway/config"
assert grep -q "DOTS_SELECTION=''" "$XDG_CONFIG_HOME/dots/env"
# Unrelated later edits survive a save; sections, not entire files, are owned.
printf '# A user comment after the block\n' >> "$XDG_CONFIG_HOME/dots/env"
install_config --select sway --save >/dev/null
assert grep -q '^# A user comment after the block$' "$XDG_CONFIG_HOME/dots/env"
# Private env remains even after uninstall; no original is auto-restored.
env_before=$(sha256sum "$XDG_CONFIG_HOME/dots/env")
uninstall_config >/dev/null
assert test "$env_before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
assert test ! -e "$test_root/settings/external-operations"

# A trusted symlink can be read, never saved (even with --replace).
fixture symlink-env
mkdir -p "$XDG_CONFIG_HOME/dots"
printf 'PRIVATE_SENTINEL=secret-settings-sentinel\nDOTS_SELECTION=sway\n' > "$HOME/trusted-env"
ln -s "$HOME/trusted-env" "$XDG_CONFIG_HOME/dots/env"
output=$(install_config --save 2>&1) && { printf 'Expected symlink refusal\n' >&2; exit 1; }
assert test "${output/secret-settings-sentinel/}" = "$output"
assert test ! -e "$HOME/.bashrc"
assert test ! -e "$XDG_STATE_HOME"
fails install_config --save --replace "$XDG_CONFIG_HOME/dots/env"
assert test "$(readlink "$XDG_CONFIG_HOME/dots/env")" = "$HOME/trusted-env"
install_config >/dev/null
assert test -L "$XDG_CONFIG_HOME/sway/config"

# All malformed/ambiguous forms fail preflight before links or state directories.
for shape in begin end reversed duplicate partial final-byte; do
  fixture "malformed-$shape"
  mkdir -p "$XDG_CONFIG_HOME/dots"
  case $shape in
    begin) printf '# BEGIN dots installer\n' ;;
    end) printf '# END dots installer\n' ;;
    reversed) printf '# END dots installer\n# BEGIN dots installer\n' ;;
    duplicate) printf '# BEGIN dots installer\nDOTS_SELECTION=""\n# END dots installer\n# BEGIN dots installer\nDOTS_SELECTION=""\n# END dots installer\n' ;;
    partial) printf '# BEGIN dots installer accidental suffix\n' ;;
    final-byte) printf '# no final newline' ;;
  esac > "$XDG_CONFIG_HOME/dots/env"
  before=$(sha256sum "$XDG_CONFIG_HOME/dots/env")
  fails install_config --save
  assert test "$before" = "$(sha256sum "$XDG_CONFIG_HOME/dots/env")"
  assert test ! -e "$HOME/.bashrc"
  assert test ! -e "$XDG_STATE_HOME"
done

# Matching existing blocks without a ledger require exact adoption.
fixture matching-block
mkdir -p "$XDG_CONFIG_HOME/dots"
printf "# BEGIN dots installer\nDOTS_SELECTION=''\nDOTS_WEZTERM_DESTINATION=''\n# END dots installer\n" > "$XDG_CONFIG_HOME/dots/env"
fails install_config --save
assert test ! -e "$HOME/.bashrc"
install_config --save --adopt "$XDG_CONFIG_HOME/dots/env" >/dev/null
# Modifying an owned block is not automatic overwrite authority.
printf "# BEGIN dots installer\nDOTS_SELECTION='sway'\nDOTS_WEZTERM_DESTINATION=''\n# END dots installer\n" > "$XDG_CONFIG_HOME/dots/env"
fails install_config --save
assert test ! -e "$XDG_CONFIG_HOME/sway/config"
install_config --save --replace "$XDG_CONFIG_HOME/dots/env" >/dev/null
assert test -L "$XDG_CONFIG_HOME/sway/config"

# Private SSH hosts are preserved byte-for-byte and require explicit approval.
fixture ssh-private
mkdir -p "$HOME/.ssh"
printf 'Host private-fixture\n  HostName example.invalid\n  IdentityFile custom-key\n' > "$HOME/.ssh/config"
cp "$HOME/.ssh/config" "$HOME/original-ssh"
fails install_config
assert test ! -e "$HOME/.bashrc"
install_config --replace "$HOME/.ssh/config" >/dev/null
python_test <<'PY'
import os
from pathlib import Path
home = Path(os.environ['HOME'])
assert (home/'.ssh/config').read_bytes().endswith((home/'original-ssh').read_bytes())
assert (home/'.ssh/config').read_text().startswith('# BEGIN dots SSH\nInclude dots-client.conf\n')
PY
# Source compatibility entry point is a quiet no-op, not a startup rewrite.
before=$(sha256sum "$HOME/.ssh/config")
source "$SOURCE/setup/ssh/init.sh"
assert test "$before" = "$(sha256sum "$HOME/.ssh/config")"
uninstall_config >/dev/null
assert cmp "$HOME/.ssh/config" "$HOME/original-ssh"

# Focused failure and concurrent-edit injection uses stdlib mocks, no host writes.
fixture block-races
python_test <<'PY'
import os, sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, sys.argv[1])
import managed as m
home = Path(os.environ['HOME'])

def fails(call):
    try: call()
    except (m.Conflict, OSError): return
    raise AssertionError('Expected failure')

for name in ('backup', 'write', 'concurrent'):
    root = home/name
    root.mkdir()
    p, state = str(root/'env'), str(root/'state')
    original = b'PRIVATE=secret-settings-sentinel\n# comment\n'
    Path(p).write_bytes(original)
    a = dict(kind='block', destination=p, begin='# BEGIN fixture', end='# END fixture',
             content="DOTS_SELECTION=''", append=True, retain=True)
    if name == 'backup':
        with patch.object(m.os, 'rename', side_effect=OSError('controlled backup failure')):
            fails(lambda: m.apply([a], 'dots', state))
        assert Path(p).read_bytes() == original
    elif name == 'write':
        with patch.object(m, 'publish', side_effect=OSError('controlled write failure')):
            fails(lambda: m.apply([a], 'dots', state))
        assert not Path(p).exists()
        backups = list(Path(state, 'backups').iterdir())
        assert len(backups) == 1 and (backups[0]/'original').read_bytes() == original
    else:
        real_backup = m.backup
        def edited(state, path, observed, parent):
            Path(path).write_bytes(original+b'# concurrent edit\n')
            return real_backup(state, path, observed, parent)
        with patch.object(m, 'backup', edited):
            fails(lambda: m.apply([a], 'dots', state))
        assert Path(p).read_bytes() == original+b'# concurrent edit\n'
    assert b'secret-settings-sentinel' not in Path(state, 'managed.json').read_bytes()

# Check observes content without generating state, bytecode or caches.
p = str(home/'read-only-env')
Path(p).write_bytes(b'# user bytes\n')
a = dict(kind='block', destination=p, begin='# BEGIN fixture', end='# END fixture',
         content="DOTS_SELECTION=''", append=True, retain=True)
state = str(home/'read-only-state')
before = sorted(str(x.relative_to(home)) for x in home.rglob('*'))
m.check([a], 'dots', state)
assert before == sorted(str(x.relative_to(home)) for x in home.rglob('*'))
assert Path(p).read_bytes() == b'# user bytes\n'
PY
assert test ! -e "$test_root/block-races/external-operations"
printf 'settings test passed\n'
