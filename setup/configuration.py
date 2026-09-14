#!/usr/bin/env python3
"""Private Dotbot-manifest planner. Source inspection and stable link roots differ.

plan(environ) returns managed.py's concrete artifact list, without any writes.
The bootstrap resolves inputs; this module never sources Bash or discovers env.
"""
import argparse
import os
from pathlib import Path
import shlex
from string import Template
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import managed


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
    if env.get('DOTS_WEZTERM_DESTINATION'):
        managed.fail('Windows WezTerm export is not implemented yet; no host files were written.')
    if 'wsl-integration' in selection:
        managed.fail('WSL integration is not implemented yet; no configuration was written.')
    # Only the pinned, initialized parser is used; no package acquisition here.
    if not (source / 'dotbot/lib/pyyaml/lib/yaml/__init__.py').is_file():
        managed.fail('Initialize the selected pinned Dotbot/PyYAML source before installation.')
    from dotbot.config import ConfigReader
    manifests = [source / 'setup/install.conf.yaml']
    if platform in ('arch', 'void'):
        manifests.append(source / 'setup/profiles/native-linux.conf.yaml')
    elif platform == 'macos':
        manifests.append(source / 'setup/profiles/native-macos.conf.yaml')
    manifests += [source / ('setup/profiles/' + s + '.conf.yaml') for s in selection if s != 'wsl-integration']
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
            if os.environ['DOTS_OS'] == 'wsl':
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
