#!/usr/bin/env bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/install_test.sh"
fixture windows
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME" "$XDG_RUNTIME_DIR"
export TEST_OS=wsl HOST_DRIVE="$test_root/windows/host drive" WINDOWS_LOG="$test_root/windows/windows-log"
export WSL_DISTRO_NAME="Arch owner 雪 ' \" \$(not-code)"
mkdir -p "$HOST_DRIVE" "$WINDOWS_LOG"
cat > "$test_root/windows/fakes/windows-spy" <<'PY'
#!/usr/bin/env python3
import base64, json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
log = Path(os.environ['WINDOWS_LOG'])
with (log/'calls').open('a') as f: f.write(json.dumps([name, args])+'\n')
if name == 'wslpath':
    mode, value = args
    if os.environ.get('FAIL_CONVERSION'): sys.exit(1)
    drive = os.environ['HOST_DRIVE']
    if mode == '-u':
        if value.startswith('Z:\\'): print(drive+'/'+value[3:].replace('\\','/'))
        elif value.startswith('/'): print(value)
        else: sys.exit(1)
    elif mode == '-w' and value.startswith(drive+'/'):
        print('Z:\\'+value[len(drive)+1:].replace('/','\\'))
    else: sys.exit(1)
elif name == 'wsl.exe':
    assert args == ['--list','--quiet']
    value = os.environ.get('REGISTERED_DISTRO', os.environ['WSL_DISTRO_NAME'])
    sys.stdout.buffer.write((value+'\r\n').encode('utf-16-le'))
elif name == 'powershell.exe':
    assert args[:4] == ['-NoLogo','-NoProfile','-NonInteractive','-Command'] and len(args) == 5
    code = args[4]
    if 'ReparsePoint' in code:
        data = base64.b64decode(sys.stdin.buffer.read()).decode('utf-8')
        assert data.startswith('Z:\\') and data not in code
        sys.exit(1 if os.environ.get('FAIL_HOST_PROBE') else 0)
    if 'Start-Process' in code or 'Set-Clipboard' in code:
        data = base64.b64decode(sys.stdin.buffer.read())
        (log/('opened' if 'Start-Process' in code else 'clipboard')).write_bytes(data)
        assert data.decode('utf-8') not in code
    elif 'Get-Clipboard' in code:
        sys.stdout.buffer.write((log/'clipboard').read_bytes())
    elif 'Get-Command wezterm.exe' not in code: sys.exit(99)
    sys.exit(int(os.environ.get('WINDOWS_STATUS','0')))
else: sys.exit(98)
PY
chmod +x "$test_root/windows/fakes/windows-spy"
for tool in powershell.exe wslpath wsl.exe; do ln -s windows-spy "$test_root/windows/fakes/$tool"; done
# No destination means no Windows query, copy, or guessed Linux terminal config.
install_config --select wsl-integration --save >/dev/null
assert test ! -e "$WINDOWS_LOG/calls"
assert test ! -e "$XDG_CONFIG_HOME/wezterm"
assert test ! -e "$XDG_CONFIG_HOME/ghostty"
assert test "$(readlink "$XDG_BIN_HOME/windows-open")" = "$SOURCE/bin/autoload/windows-open"
export HOST_DESTINATION="$HOST_DRIVE/owner's 雪 \$(not-code).lua"
install_config --wezterm-destination "$HOST_DESTINATION" --save >/dev/null
assert test -f "$HOST_DESTINATION"
assert test ! -L "$HOST_DESTINATION"
before=$(sha256sum "$XDG_STATE_HOME/dots/managed.json" "$HOST_DESTINATION" "$XDG_CONFIG_HOME/dots/env")
inode=$(stat -c %i "$HOST_DESTINATION")
install_config >/dev/null
assert test "$before" = "$(sha256sum "$XDG_STATE_HOME/dots/managed.json" "$HOST_DESTINATION" "$XDG_CONFIG_HOME/dots/env")"
assert test "$inode" = "$(stat -c %i "$HOST_DESTINATION")"
# Clearing export never removes previously exported host files.
install_config --wezterm-destination '' --save >/dev/null
assert test -f "$HOST_DESTINATION"
# Whole-owner preflight detects a changed host copy before saving or other links.
printf '\n-- user edit\n' >> "$HOST_DESTINATION"
before=$(sha256sum "$XDG_STATE_HOME/dots/managed.json" "$HOST_DESTINATION" "$XDG_CONFIG_HOME/dots/env")
fails install_config --wezterm-destination "$HOST_DESTINATION" --save >/dev/null 2>&1
assert test "$before" = "$(sha256sum "$XDG_STATE_HOME/dots/managed.json" "$HOST_DESTINATION" "$XDG_CONFIG_HOME/dots/env")"
python_test <<'PY'
import base64, json, os, sys, subprocess
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, sys.argv[1])
import configuration as c, managed as m
root = Path(os.environ['PROJECT_ROOT'])
drive = Path(os.environ['HOST_DRIVE'])
log = Path(os.environ['WINDOWS_LOG'])
base = dict(os.environ, DOTS_OS='wsl')
def export(p):
    return c.windows_export(dict(base, DOTS_WEZTERM_DESTINATION=str(p)), root)
def fails(fn, *args, **kwargs):
    try: fn(*args, **kwargs)
    except (m.Conflict, OSError): return
    raise AssertionError('Expected failure: '+fn.__name__)
def case(name):
    p = drive/(name+'.lua')
    return str(p), str(Path(os.environ['XDG_STATE_HOME'])/name)
def state_bytes(state): return Path(state,'managed.json').read_bytes()
def apply(p, state, **kw): m.apply([export(p)], 'dots', state, **kw)
# Exact rendered UTF-8 bytes and registered distro, no fixed user or shell code.
p, state = case('copy 雪')
a = export(p)
distro = "'"+''.join('\\%03d'%b for b in os.environ['WSL_DISTRO_NAME'].encode())+"'"
expected = (root/'config/wezterm/wezterm.lua').read_bytes().replace(b"'@DOTS_WSL_DISTRIBUTION@'", distro.encode())
assert a['content'].encode() == expected
assert export('Z:\\copy 雪.lua') == a
assert b"'-u'" not in expected and b"'--user'" not in expected
assert b"'--cd', '~'" in expected
apply(p,state)
assert Path(p).read_bytes() == expected and not Path(p).is_symlink()
record = json.loads(state_bytes(state))['artifacts'][p]
assert record['kind']=='file' and record['expected']==m.snapshot(p) and record['owner']=='dots'
before, ledger = m.snapshot(p), state_bytes(state)
apply(p,state)
assert m.snapshot(p)==before and state_bytes(state)==ledger
# Explicit adoption enrolls exact bytes without changing file/link identity.
p, state = case('adopt')
Path(p).write_bytes(expected)
before = m.snapshot(p)
fails(apply,p,state)
assert not Path(state).exists()
apply(p,state,adopt=[p])
assert m.snapshot(p)==before
# Replacement backs up the actual inode/metadata; no copy-based backup fallback.
p, state = case('replace')
Path(p).write_bytes(b'original\r\n')
Path(p).chmod(0o640)
before = m.snapshot(p)
fails(apply,p,state,adopt=[p])
apply(p,state,replace=[p])
r = json.loads(state_bytes(state))['artifacts'][p]
backup = Path(state,'backups',r['backups'][0],'original')
assert m.snapshot(str(backup))==before and backup.read_bytes()==b'original\r\n'
assert Path(p).read_bytes()==expected
# Windows files are retained on absent-destination plans/removal, not inferred cleanup.
m.apply([], 'dots', state)
m.remove('dots',state)
assert Path(p).read_bytes()==expected
# Edited files and symlinks are never silently overwritten or followed.
Path(p).write_bytes(b'user edited')
fails(apply,p,state)
referent = drive/'referent'
referent.write_bytes(b'private')
p2, s2 = case('link')
Path(p2).symlink_to(referent)
fails(export,p2)
fails(apply,p2,s2,replace=[p2])
assert os.readlink(p2)==str(referent) and referent.read_bytes()==b'private'
parent = drive/'junction'
parent.symlink_to(drive, target_is_directory=True)
fails(export,parent/'new.lua')
# Invalid paths fail without creating parents, state, or host artifacts.
for value in (drive/'missing parent'/'x.lua', drive/'NUL.lua', drive/'bad"quote.lua',
              drive/'file.lua:stream', drive/'trailing. ', Path(os.environ['HOME'])/'linux.lua'):
    fails(export,value)
assert not (drive/'missing parent').exists()
unwritable = drive/'unwritable'; unwritable.mkdir(); unwritable.chmod(0o500)
fails(export,unwritable/'config.lua')
unwritable.chmod(0o700)
for key in ('FAIL_CONVERSION','FAIL_HOST_PROBE'):
    with patch.dict(os.environ,{key:'1'}): fails(export,drive/'refused.lua')
with patch.dict(os.environ,{'REGISTERED_DISTRO':'a different distro'}):
    fails(export,drive/'refused.lua')
assert not (drive/'refused.lua').exists()
# A failed backup or cross-filesystem original is never relaxed for Windows.
p, state = case('failed-backup'); Path(p).write_bytes(b'keep original')
a = export(p); before=m.snapshot(p)
rename = m.os.rename
def fail_backup(src,dst):
    if src==p: raise OSError('fixture backup failure')
    return rename(src,dst)
with patch.object(m.os,'rename',fail_backup): fails(m.apply,[a],'dots',state,replace=[p])
assert m.snapshot(p)==before
p, state = case('cross-filesystem'); Path(p).write_bytes(b'keep ACLs')
a=export(p); before=m.snapshot(p); snapshot=m.snapshot
def other_device(path):
    s=snapshot(path)
    return dict(s,device=-1) if path==p else s
with patch.object(m,'snapshot',other_device): fails(m.apply,[a],'dots',state,replace=[p])
assert m.snapshot(p)==before and not Path(state).exists()
# Failed publication retains a pending record, no falsely completed copy.
p, state = case('failed-copy'); a=export(p)
with patch.object(m,'publish',side_effect=OSError('fixture copy failure')):
    fails(m.apply,[a],'dots',state)
assert not Path(p).exists()
assert json.loads(state_bytes(state))['artifacts'][p]['status']=='pending'
# Browser/file inputs are data. The exact URL bypasses wslpath completely.
opening = root/'bin/autoload/windows-open'
clipboard = root/'bin/autoload/windows-clipboard'
values = ['https://example.invalid/雪?q="; $(touch NEVER); \\ backslash',
          "mailto:owner@example.invalid?subject='quoted'", 'https://example.invalid/%20']
for value in values:
    count=(log/'calls').read_text().count('"wslpath"')
    subprocess.run([str(opening),value],check=True)
    assert (log/'opened').read_bytes()==value.encode()
    assert (log/'calls').read_text().count('"wslpath"')==count
value=drive/"file '雪 $(touch NEVER).txt"
subprocess.run([str(opening),str(value)],check=True)
assert (log/'opened').read_text()=="Z:\\"+value.name
subprocess.run([str(opening),"Z:\\"+value.name],check=True)
assert (log/'opened').read_text()=="Z:\\"+value.name
text='雪 "quotes" \\ path\r\n$(touch NEVER)\nlast line\n'
subprocess.run([str(clipboard),'copy'],input=text.encode(),check=True)
assert subprocess.check_output([str(clipboard),'paste'])==text.encode()
with patch.dict(os.environ, {'WINDOWS_STATUS':'37'}):
    assert subprocess.run([str(opening),values[0]]).returncode==37
    assert subprocess.run([str(clipboard),'paste'],stdout=subprocess.DEVNULL).returncode==37
assert not (root/'NEVER').exists() and not (drive/'NEVER').exists()
# All PowerShell call sites use fixed code, separate from path/URL/text data.
calls=[json.loads(line) for line in (log/'calls').read_text().splitlines()]
for name,args in calls:
    if name=='powershell.exe':
        assert os.environ['WSL_DISTRO_NAME'] not in args[-1]
        assert 'touch NEVER' not in args[-1]
PY
# Wiring is local/selected and retains explicit empty and nonempty overrides.
source "$project_root/setup/common.sh"
DOTS_SELECTION=wsl-integration
BROWSER='' GH_BROWSER=custom
alias pbcopy='custom-copy'
source "$project_root/bash/env/os/wsl/aliases.sh"
assert test "$BROWSER" = ''
assert test "$GH_BROWSER" = custom
assert test "$(alias pbcopy)" = "alias pbcopy='custom-copy'"
assert test "$(alias pbpaste)" = "alias pbpaste='windows-clipboard paste'"
assert test "$(alias open)" = "alias open='windows-open'"
(
  unalias pbcopy pbpaste open
  unset BROWSER GH_BROWSER
  SSH_CONNECTION=fixture source "$project_root/bash/env/os/wsl/aliases.sh"
  assert test -z "${BROWSER+x}"
  ! alias pbcopy >/dev/null 2>&1
  DOTS_SELECTION='' source "$project_root/bash/env/os/wsl/aliases.sh"
  assert test -z "${BROWSER+x}"
)
assert test ! -e "$test_root/windows/external-operations"
printf 'windows export test passed\n'
