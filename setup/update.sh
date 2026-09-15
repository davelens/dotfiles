#!/usr/bin/env bash
# Operational scratch only. Git/configuration changes are not a transaction.
set +x
unset BASH_ENV ENV
entry=$(realpath -- "${BASH_SOURCE[0]}") || exit 1
python=$(type -P python3 || type -P python) || { printf 'dots: Python is required for checked updates.\n' >&2; exit 1; }
exec "$python" -I -B - "${entry%/*}/.." "$@" <<'PY'
import argparse
import glob
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile

root = str(Path(sys.argv[1]).resolve())
sys.path.insert(0, root + '/setup')
import managed

parser = argparse.ArgumentParser(description='Clean fast-forward updates; always includes the invoked dotfiles checkout.')
parser.add_argument('--repo', action='append', default=[], metavar='ABSOLUTE_PATH')
parser.add_argument('--select')
parser.add_argument('--wezterm-destination')
args = parser.parse_args(sys.argv[2:])
choices = []
for option in ('select', 'wezterm_destination'):
    value = getattr(args, option)
    if value is not None:
        choices += ['--' + option.replace('_', '-'), value]
# Each child receives the ORIGINAL inputs, not bootstrap's already resolved XDG
# roots/PATH. The trusted env can redirect roots; reloading must be consistent.
original = dict(os.environ, GIT_OPTIONAL_LOCKS='0', PYTHONDONTWRITEBYTECODE='1')


class Blocked(Exception):
    pass


def run(command):
    result = subprocess.run(command, env=original, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, text=True, stdin=subprocess.DEVNULL)
    if result.returncode:
        # Git URLs and trusted subprocess output can contain secrets.
        raise Blocked('Command failed: ' + Path(command[0]).name)
    return result.stdout


def git(repo, *arguments):
    # Update never executes repository hooks (which can activate services).
    return run(['git', '-c', 'core.hooksPath=/dev/null', '-C', repo, *arguments]).rstrip('\n')


def revision(repo):
    try:
        return git(repo, 'rev-parse', '--verify', 'HEAD')
    except Blocked:
        return 'unavailable'


def tracked(repo):
    result = {}
    for entry in git(repo, 'ls-files', '--stage', '-z').split('\0'):
        if entry:
            metadata, path = entry.split('\t', 1)
            mode, rev, stage = metadata.split()
            if stage != '0':
                raise Blocked('Unmerged index.')
            result[path] = (mode, rev)
    return result


def clean(repo, top=True):
    if git(repo, 'rev-parse', '--show-toplevel') != repo:
        raise Blocked('Not the requested repository root.')
    if git(repo, 'status', '--porcelain=v1', '--untracked-files=all', '--ignore-submodules=none'):
        raise Blocked('Worktree/index/untracked or submodule changes; preserved.')
    result = [revision(repo), tracked(repo)]
    index = git(repo, 'rev-parse', '--path-format=absolute', '--git-path', 'index')
    result.append(managed.snapshot(index))
    if top:
        try:
            branch = git(repo, 'symbolic-ref', '--quiet', 'HEAD')
        except Blocked:
            raise Blocked('Detached checkout; select a tracking branch explicitly.')
        try:
            upstream = git(repo, 'rev-parse', '--symbolic-full-name', '@{upstream}')
        except Blocked:
            raise Blocked('Missing upstream; configure tracking explicitly.')
        result += [branch, upstream]
    for path, (mode, rev) in result[1].items():
        if mode != '160000':
            continue
        sub = repo + '/' + path
        # Uninitialized, moved and dirty recursive submodules all fail closed.
        if git(sub, 'rev-parse', '--show-toplevel') != sub or revision(sub) != rev:
            raise Blocked('Submodule is uninitialized or moved; preserved.')
        result.append((path, clean(sub, False)))
    return result


def incoming_conflicts(active, candidate):
    """Git ignores private registrations; an incoming tracked path must not."""
    old = tracked(active) if Path(active).is_dir() else {}
    new = tracked(candidate)
    observations = {}
    for path, (mode, _) in new.items():
        destination = active + '/' + path
        if path not in old:
            parents = managed.parents(destination)
            now = managed.snapshot(destination)
            observations[destination] = (now, parents)
            if now is not None:
                raise Blocked('Incoming source conflicts with existing untracked/ignored content.')
        elif old[path][0] != mode and ('160000' in (old[path][0], mode)):
            raise Blocked('Submodule type changes require explicit preparation.')
        if mode == '160000':
            observations.update(incoming_conflicts(destination, candidate + '/' + path))
    if any(mode == '160000' and path not in new for path, (mode, _) in old.items()):
        raise Blocked('Submodule removal requires explicit preparation; local content preserved.')
    return observations


def candidate_check(candidate):
    try:
        return run(['bash', candidate + '/setup/check', 'candidate', '--install-root', root, *choices])
    except Blocked:
        raise Blocked('Candidate requirements/configuration/ownership check rejected (no advancement).')


def retain_message(area, candidate, target, resolved):
    config = candidate + '/config/mise/config.toml'
    delegate = resolved.get('DOTSYS_REPO_HOME') or str(Path(root).parent / 'dotsys')
    if not os.path.isabs(delegate):
        delegate = str(Path(root).parent / 'dotsys')
    print('dots: Retained candidate revision ' + target)
    print('dots: Candidate config: ' + config)
    if Path(candidate + '/setup/check').is_file():
        print('dots: Inspect requirements explicitly: bash ' + shlex.quote(candidate + '/setup/check') +
              ' candidate --install-root ' + shlex.quote(root) +
              ''.join(' ' + shlex.quote(v) for v in choices))
    else:
        print('dots: Candidate checker unavailable; inspect the retained source manually.')
    if Path(config).is_file():
        print('dots: If mise preparation is required (never run by update): bash ' +
              shlex.quote(delegate + '/shared/mise/init.sh') + ' --config ' + shlex.quote(config))
    else:
        print('dots: Candidate has no mise config; runtime preparation is unavailable.')
    print('dots: After inspection/preparation, retry update. Optional cleanup of ONLY this run: rm -rf -- ' + shlex.quote(area))


try:
    if any(original.get(k) for k in ('GIT_DIR', 'GIT_WORK_TREE', 'GIT_INDEX_FILE', 'GIT_COMMON_DIR')):
        raise Blocked('Git location overrides are unsupported.')
    # Capture trusted bootstrap output only in memory; never persist its environment.
    resolved = json.loads(run(['bash', '--noprofile', '--norc', '-c',
        'source "$1/setup/common.sh" || exit; shift; '
        'dots_bootstrap readiness "$1/setup/install" "${@:2}" || exit; '
        'exec "$(type -P python3 || type -P python)" -I -B -c \'import json,os; print(json.dumps(dict(os.environ)))\'',
        'dots-update', root, root, *choices]))
except (Blocked, ValueError, OSError):
    print('dots: Update bootstrap failed; no repositories advanced.', file=sys.stderr)
    sys.exit(1)

repos = [root]
requested = args.repo
if not requested and resolved.get('REPO_NAMESPACE'):
    namespace = resolved['REPO_NAMESPACE']
    if os.path.isabs(namespace):
        for path in sorted(glob.glob(namespace + '/davelens/dot*')):
            try:
                if git(path, 'rev-parse', '--show-toplevel') == str(Path(path).resolve()):
                    requested.append(path)
            except (Blocked, OSError):
                continue
for path in requested:
    if not os.path.isabs(path):
        parser.error('--repo must be absolute')
    path = str(Path(path).resolve())
    if path not in repos:
        repos.append(path)

failed = False
for repo in repos:
    old, area, candidate, target = revision(repo), None, None, None
    outcome = 'blocked'
    advanced = False
    keep = False
    phase = 'repository safety check'
    try:
        if git(repo, 'rev-parse', '--show-superproject-working-tree'):
            raise Blocked('Submodules must follow their superproject; no independent update.')
        initial = clean(repo)
        branch = initial[3][len('refs/heads/'):]
        remote = git(repo, 'config', '--get', 'branch.' + branch + '.remote')
        phase = 'fetch/fast-forward preflight'
        git(repo, 'fetch', '--no-recurse-submodules', '--', remote)
        target = git(repo, 'rev-parse', '@{upstream}')
        try:
            git(repo, 'merge-base', '--is-ancestor', old, target)
        except Blocked:
            raise Blocked('Local history diverges from or is ahead of upstream; preserved.')
        if clean(repo) != initial:
            raise Blocked('Active revision/branch/index changed during fetch.')
        if old == target:
            outcome = 'unchanged'
        else:
            # Private clone, not an active worktree: no active index/worktree changes,
            # no ignored state copies, and candidate submodules follow its gitlinks.
            phase = 'candidate staging/preflight'
            state = resolved['XDG_STATE_HOME'] + '/dots'
            managed.State('dots', state)
            managed.mkdirs(state)
            managed.private(state, True)
            area = tempfile.mkdtemp(prefix='update-', dir=state)
            candidate = area + '/source'
            git(repo, 'clone', '--no-hardlinks', '--no-checkout', '--', repo, candidate)
            git(candidate, 'fetch', '--no-recurse-submodules', '--', repo, target)
            git(candidate, 'checkout', '--detach', target)
            # Resolve relative submodule URLs against the actual upstream, not scratch.
            url = git(repo, 'remote', 'get-url', remote) if remote != '.' else repo
            git(candidate, 'remote', 'set-url', 'origin', url)
            git(candidate, 'submodule', 'update', '--init', '--recursive', '--checkout')
            conflicts = incoming_conflicts(repo, candidate)
            if repo == root:
                keep = True  # Preserve every rejected check, including unmet mise pins.
                before = candidate_check(candidate)
                if candidate_check(candidate) != before:
                    raise Blocked('Machine/configuration inputs changed before advancement.')
            if clean(repo) != initial or incoming_conflicts(repo, candidate) != conflicts:
                raise Blocked('Active repository or source conflicts changed before advancement.')
            if git(repo, 'rev-parse', '@{upstream}') != target:
                raise Blocked('Upstream changed concurrently.')
            keep = False
            phase = 'fast-forward'
            git(repo, 'merge', '--ff-only', '--no-edit', '--no-overwrite-ignore', target)
            advanced = True
            phase = 'pinned submodule update'
            git(repo, 'submodule', 'update', '--init', '--recursive', '--checkout')
            if repo == root:
                phase = 'configuration reinstall'
                run(['bash', root + '/setup/install', *choices])
                phase = 'post-advance readiness'
                run(['bash', root + '/setup/check', 'readiness', *choices])
            outcome = 'updated'
    except (Blocked, managed.Conflict, OSError, ValueError, KeyError) as error:
        failed = True
        advanced = advanced or revision(repo) != old
        outcome = 'PARTIAL advancement; no rollback' if advanced else 'blocked; preserved'
        detail = str(error) if isinstance(error, Blocked) else 'Safety/state check failed.'
        print('dots: ' + phase + ': ' + detail, file=sys.stderr)
        if keep and area and candidate and target:
            retain_message(area, candidate, target, resolved)
    finally:
        if area and not keep:
            # Only our exact mkdtemp result, never a repository/state-wide cleanup.
            try:
                shutil.rmtree(area)
            except OSError:
                failed = True
                outcome += '; scratch cleanup failed'
                print('dots: Exact private run area needs cleanup: ' + area, file=sys.stderr)
        print('dots: ' + repo + ': ' + old + ' -> ' + revision(repo) + ': ' + outcome, flush=True)
sys.exit(1 if failed else 0)
PY
