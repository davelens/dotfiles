#!/usr/bin/env python3
"""Private Dotbot-manifest planner. Source inspection and stable link roots differ.

plan(environ) returns managed.py's concrete artifact list, without any writes.
The bootstrap resolves inputs; this module never sources Bash or discovers env.
"""
import argparse
import base64
import os
from pathlib import Path
import shlex
import re
import stat
import subprocess
from string import Template
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import managed


def windows_export(env, source):
    """Render a copied Windows config; never guess a host profile or create parents."""
    value = env.get('DOTS_WEZTERM_DESTINATION', '')
    if not value:
        return None
    if env['DOTS_OS'] != 'wsl':
        managed.fail('Windows export requires WSL.')
    try:
        destination = subprocess.check_output(['wslpath', '-u', value], text=True).rstrip('\n')
        destination = managed.absolute(destination)
        host = subprocess.check_output(['wslpath', '-w', destination], text=True).rstrip('\n')
        if not re.match(r'^[A-Za-z]:\\', host) or any(c in host for c in '\r\n\x00'):
            managed.fail('Destination must resolve to an explicit Windows drive, not a WSL share.')
        for component in host[3:].split('\\'):
            if (not component or component[-1] in ' .' or
                    any(ord(c) < 32 or c in '<>:"/|?*' for c in component) or
                    re.fullmatch(r'(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?', component, re.I)):
                managed.fail('Invalid Windows destination component (including reserved names or streams).')
        # Round-trip identity, not a guessed /mnt/c or Windows user directory.
        if subprocess.check_output(['wslpath', '-u', host], text=True).rstrip('\n') != destination:
            managed.fail('Windows destination does not round-trip through wslpath.')
        managed.parents(destination)
        parent = Path(destination).parent
        if not parent.is_dir() or not os.access(parent, os.W_OK | os.X_OK) or not parent.stat().st_mode & 0o222:
            managed.fail('Windows destination parent must already exist and be writable.')
        now = managed.snapshot(destination)
        if now and (not stat.S_ISREG(now['mode']) or now['uid'] != os.getuid() or
                    not os.access(destination, os.W_OK) or not now['mode'] & 0o222):
            managed.fail('Windows destination must be a writable user-owned regular file, never a symlink.')
        # Windows junctions/reparse points may not appear as Linux symlinks.
        code = """$ErrorActionPreference = 'Stop';
$p = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String([Console]::In.ReadToEnd()));
while ($p) {
  if (Test-Path -LiteralPath $p) {
    if ((Get-Item -LiteralPath $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { exit 1 }
  }
  $p = Split-Path -LiteralPath $p
}
exit 0"""
        subprocess.run(['powershell.exe', '-NoLogo', '-NoProfile', '-NonInteractive', '-Command', code],
                       input=base64.b64encode(host.encode('utf-8')), stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, check=True)
        distro = env.get('WSL_DISTRO_NAME', '')
        registered = subprocess.check_output(['wsl.exe', '--list', '--quiet'])
        registered = registered.decode('utf-16' if registered.startswith(b'\xff\xfe') else
                                       'utf-16-le' if b'\x00' in registered else 'utf-8')
        if not distro or distro not in registered.splitlines() or any(c in distro for c in '\r\n\x00'):
            managed.fail('Export needs WSL_DISTRO_NAME matching the current registered Arch WSL distribution.')
    except (OSError, UnicodeError, subprocess.CalledProcessError):
        managed.fail('Windows destination/registration probe failed; no configuration was written.')
    # Decimal byte escapes are valid Lua for quotes, backslashes and UTF-8 alike.
    literal = "'" + ''.join('\\%03d' % b for b in distro.encode('utf-8')) + "'"
    content = (source / 'config/wezterm/wezterm.lua').read_bytes().decode('utf-8')
    marker = "'@DOTS_WSL_DISTRIBUTION@'"
    if content.count(marker) != 1:
        managed.fail('Windows configuration requires exactly one distribution placeholder.')
    # Clearing/omitting the destination must never become implicit host cleanup.
    # The existing file ledger owns copies; same-filesystem backup rules still apply.
    return dict(kind='file', destination=destination, content=content.replace(marker, literal), retain=True)


def plan(env):
    source = Path(managed.absolute(env['DOTS_SOURCE_ROOT']))
    stable = Path(managed.absolute(env['DOTS_INSTALL_ROOT']))
    selection = env['DOTS_SELECTION'].split(',') if env['DOTS_SELECTION'] else []
    platform = env['DOTS_OS']
    allowed = {'arch': {'sway'}, 'void': {'sway'},
               'macos': {'macos-desktop', 'karabiner', 'alfred'},
               'wsl': {'wsl-integration'}}
    if len(set(selection)) != len(selection) or set(selection) - allowed.get(platform, set()):
        managed.fail('Unknown or inapplicable selection.')
    export = windows_export(env, source)
    # Only the pinned, initialized parser is used; no package acquisition here.
    if not (source / 'dotbot/lib/pyyaml/lib/yaml/__init__.py').is_file():
        managed.fail('Initialize the selected pinned Dotbot/PyYAML source before installation.')
    from dotbot.config import ConfigReader
    manifests = [source / 'setup/install.conf.yaml']
    if platform in ('arch', 'void'):
        manifests.append(source / 'setup/profiles/native-linux.conf.yaml')
    elif platform == 'macos':
        manifests.append(source / 'setup/profiles/native-macos.conf.yaml')
    manifests += [source / ('setup/profiles/' + s + '.conf.yaml') for s in selection]
    artifacts, directories = {}, set()
    try:
        tasks = ConfigReader([str(p) for p in manifests]).get_config()
    except Exception:
        managed.fail('Cannot parse selected public Dotbot manifests.')
    for task in tasks:
        if not isinstance(task, dict) or len(task) != 1:
            managed.fail('Expected a single explicit manifest directive.')
        if 'link' in task and isinstance(task['link'], dict):
            for destination, relative in task['link'].items():
                if not isinstance(relative, str) or Path(relative).is_absolute() or '..' in Path(relative).parts or any(c in relative for c in '*?['):
                    managed.fail('Expected an explicit public source file.')
                inspected = source / relative
                if not inspected.is_file() or inspected.is_symlink():
                    managed.fail('Public manifest source is missing or not a regular file: ' + relative)
                p = managed.absolute(Template(destination).substitute(env))
                a = dict(kind='link', destination=p, target=str(stable / relative))
                if p in artifacts and artifacts[p] != a:
                    managed.fail('Conflicting manifest destinations: ' + p)
                artifacts[p] = a
        elif 'create' in task and isinstance(task['create'], list):
            directories.update(managed.absolute(Template(p).substitute(env)) for p in task['create'])
        else:
            managed.fail('Only explicit link/create manifests are supported.')
    if export:
        if export['destination'] in artifacts:
            managed.fail('Windows export overlaps another configuration artifact.')
        artifacts[export['destination']] = export
    ssh = env['HOME'] + '/.ssh/config'
    artifacts[ssh] = dict(kind='block', destination=ssh, begin='# BEGIN dots SSH',
                          end='# END dots SSH', content='Include dots-client.conf')
    if env.get('DOTS_SAVE') == '1':
        p = env['DOTS_ENV_FILE']
        artifacts[p] = dict(kind='block', destination=p, begin='# BEGIN dots installer',
                            end='# END dots installer', append=True, retain=True,
                            content='DOTS_SELECTION=' + shlex.quote(env['DOTS_SELECTION']) + '\n' +
                            'DOTS_WEZTERM_DESTINATION=' + shlex.quote(env['DOTS_WEZTERM_DESTINATION']))
    for p in list(artifacts) + list(directories):
        directories.update(str(parent) for parent in Path(p).parents if str(parent) != '/')
    # Private state infrastructure persists and is created by the state writer,
    # not subject to configuration deselection/removal.
    state_root = Path(env['XDG_STATE_HOME']) / 'dots'
    directories -= {str(state_root), *(str(p) for p in state_root.parents)}
    result = [dict(kind='directory', destination=p, mode=0o700)
              for p in sorted(directories, key=lambda p: (p.count('/'), p))]
    result += list(artifacts.values())
    managed.validate_plan(result)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('install', 'check', 'uninstall', 'restore'))
    parser.add_argument('--adopt', action='append', default=[])
    parser.add_argument('--replace', action='append', default=[])
    parser.add_argument('--backup')
    args = parser.parse_args()
    if (args.backup and args.action != 'restore') or (args.adopt and args.action not in ('install', 'check')) or (args.replace and args.action == 'uninstall'):
        parser.error('Lifecycle option is not applicable to this action.')
    root = os.environ['XDG_STATE_HOME'] + '/dots'
    try:
        if args.action in ('install', 'check'):
            artifacts = plan(os.environ)
            action = managed.apply if args.action == 'install' else managed.check
            action(artifacts, 'dots', root, args.adopt, args.replace)
            if os.environ['DOTS_OS'] == 'wsl' and not os.environ.get('DOTS_WEZTERM_DESTINATION'):
                print('dots: Windows WezTerm export skipped: no destination supplied.')
        elif args.action == 'uninstall':
            managed.remove('dots', root)
        else:
            if not args.backup:
                managed.fail('Restore requires an exact --backup ID from the private ledger.')
            managed.restore('dots', root, args.backup, args.replace)
    except managed.Conflict as error:
        print('dots: ' + str(error), file=sys.stderr)
        return 1
    except (OSError, ValueError, TypeError, KeyError, ImportError):
        print('dots: Operation failed; completed artifacts and private recovery state remain at ' + root, file=sys.stderr)
        return 1
    print('dots: ' + args.action + ' completed (configuration only).')
    return 0


if __name__ == '__main__':
    sys.exit(main())
