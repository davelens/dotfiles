#!/usr/bin/env python3
"""Small POSIX ownership API shared with dotsys (no provisioning).

check/apply(plan, owner, state_root, adopt=(), replace=()); remove(owner,
state_root, paths=None); restore(owner, state_root, backup_id, replace=()).
Plan: list of {kind, destination, ...}: link/target, file/content (UTF-8),
block/begin/end/content, directory/mode. Optional retain keeps an artifact on
remove (private env). Blocks may set append=True for explicit env saving.
Missing parents require preceding directory artifacts (mode 0700 or 0755).
Callers validate link sources; stable targets may be absent during candidate
checks. check returns observations; mutations return None or raise Conflict /
OSError. Backups require same-filesystem, user-owned, single-link originals.
CLI: managed.py check|apply --plan JSON --owner NAME --state-root PATH
     managed.py remove --owner NAME --state-root PATH [--path PATH ...]
     managed.py restore --owner NAME --state-root PATH --backup ID
All approvals are exact absolute paths, not patterns. check never writes.
State v1: owner, artifacts keyed by destination, backups keyed by UUID.
Completed records carry expected fingerprints/identity and backup IDs. Pending
records fail closed after interrupted writes; never infer ownership from disk.
"""
import argparse
from contextlib import contextmanager, redirect_stdout, redirect_stderr
import hashlib
import io
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
import uuid

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent.parent
sys.path[:0] = [str(ROOT / 'dotbot/src'), str(ROOT / 'dotbot/lib/pyyaml/lib')]


class Conflict(Exception):
    pass


def fail(message):
    raise Conflict(message)


def absolute(path):
    if not isinstance(path, str) or not path.startswith('/') or '\x00' in path or os.path.normpath(path) != path:
        fail('Expected a normalized absolute path.')
    return path


def parents(path):
    """Refuse symlink ancestors; capture identity, not directory timestamps."""
    result = {}
    for p in reversed(Path(path).parents):
        try:
            s = p.lstat()
        except FileNotFoundError:
            continue
        if not stat.S_ISDIR(s.st_mode):
            fail('Non-directory or symlink parent: ' + str(p))
        result[str(p)] = [s.st_dev, s.st_ino]
    return result


def verify_parents(observed):
    for p, expected in observed.items():
        s = os.lstat(p)
        if not stat.S_ISDIR(s.st_mode) or [s.st_dev, s.st_ino] != expected:
            fail('Parent changed: ' + p)


def stat_identity(s):
    return (s.st_dev, s.st_ino, s.st_mode, s.st_uid, s.st_gid,
            s.st_size, s.st_mtime_ns, s.st_ctime_ns)


def snapshot(path):
    try:
        s = os.lstat(path)
    except FileNotFoundError:
        return None
    result = dict(device=s.st_dev, inode=s.st_ino, mode=s.st_mode,
                  uid=s.st_uid, gid=s.st_gid, size=s.st_size, mtime=s.st_mtime_ns)
    if stat.S_ISLNK(s.st_mode):
        result['target'] = os.readlink(path)
    elif stat.S_ISREG(s.st_mode):
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, 'rb') as f:
            if stat_identity(os.fstat(f.fileno())) != stat_identity(s):
                fail('File changed while reading: ' + path)
            result['sha256'] = hashlib.sha256(f.read()).hexdigest()
            if stat_identity(os.fstat(f.fileno())) != stat_identity(s):
                fail('File changed while reading: ' + path)
    elif stat.S_ISDIR(s.st_mode):
        # Only identity matters for directories we create; never inspect trees.
        result.pop('size')
        result.pop('mtime')
    if stat_identity(os.lstat(path)) != stat_identity(s):
        fail('Artifact changed while reading: ' + path)
    return result


def read_bytes(path, observed):
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(fd, 'rb') as f:
        data = f.read()
    if snapshot(path) != observed or hashlib.sha256(data).hexdigest() != observed.get('sha256'):
        fail('File changed while reading: ' + path)
    return data


def split_block(data, artifact):
    begin, end = (artifact[k].encode() for k in ('begin', 'end'))
    lines = data.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.rstrip(b'\r\n') == begin]
    ends = [i for i, line in enumerate(lines) if line.rstrip(b'\r\n') == end]
    # Near-markers are ambiguous too, not permission to append another block.
    if data.count(begin) != len(starts) or data.count(end) != len(ends):
        fail('Malformed managed block: ' + artifact['destination'])
    if not starts and not ends:
        return data, b'', b''
    if len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]:
        fail('Malformed or duplicate managed block: ' + artifact['destination'])
    a, b = starts[0], ends[0] + 1
    return b''.join(lines[:a]), b''.join(lines[a:b]), b''.join(lines[b:])


def block_bytes(a):
    return (a['begin'] + '\n' + a['content'].rstrip('\n') + '\n' + a['end'] + '\n').encode()


def desired(a, observed):
    if a['kind'] == 'block':
        data = read_bytes(a['destination'], observed) if observed else b''
        prefix, old, suffix = split_block(data, a)
        if not old and not a.get('append'):
            return block_bytes(a) + data
        if not old and prefix and not prefix.endswith(b'\n'):
            fail('Cannot append block without changing unrelated final bytes: ' + a['destination'])
        return prefix + block_bytes(a) + suffix
    return a.get('content', '').encode()


def matches(a, observed):
    if observed is None:
        return False
    if a['kind'] == 'link':
        return observed.get('target') == a['target']
    if a['kind'] == 'directory':
        return stat.S_ISDIR(observed['mode'])
    if a['kind'] == 'block':
        if not stat.S_ISREG(observed['mode']):
            return False
        return split_block(read_bytes(a['destination'], observed), a)[1] == block_bytes(a)
    return observed.get('sha256') == hashlib.sha256(a['content'].encode()).hexdigest()


def owned(record, observed):
    if record['kind'] == 'block':
        if not observed or not stat.S_ISREG(observed['mode']):
            return False
        block = split_block(read_bytes(record['destination'], observed), record)[1]
        return hashlib.sha256(block).hexdigest() == record['expected']['sha256']
    return observed == record['expected']


def validate_plan(plan):
    if not isinstance(plan, list):
        fail('Plan must be a list.')
    seen = set()
    for a in plan:
        if not isinstance(a, dict) or a.get('kind') not in ('link', 'file', 'block', 'directory'):
            fail('Invalid artifact kind.')
        p = absolute(a.get('destination'))
        if p in seen:
            fail('Duplicate destination: ' + p)
        seen.add(p)
        allowed = {'kind', 'destination', 'retain'}
        if a['kind'] == 'link':
            absolute(a.get('target'))
            allowed.add('target')
        elif a['kind'] in ('file', 'block'):
            if not isinstance(a.get('content'), str):
                fail('Expected UTF-8 content.')
            allowed.add('content')
            if a['kind'] == 'block':
                allowed.update(('begin', 'end', 'append'))
                if any(not isinstance(a.get(k), str) or not a[k] or '\n' in a[k] for k in ('begin', 'end')) or a['begin'] == a['end']:
                    fail('Invalid block delimiters.')
                if a['begin'] in a['content'] or a['end'] in a['content']:
                    fail('Block content contains delimiters.')
        else:
            allowed.add('mode')
            if a.get('mode', 0o700) not in (0o700, 0o755):
                fail('Unsupported directory mode.')
        if set(a) - allowed:
            fail('Unknown artifact fields.')
    for a in plan:
        if any(str(p) in seen and next(x for x in plan if x['destination'] == str(p))['kind'] != 'directory' for p in Path(a['destination']).parents):
            fail('Artifact overlaps another destination.')


def private(path, directory=False):
    s = os.lstat(path)
    correct = stat.S_ISDIR(s.st_mode) if directory else stat.S_ISREG(s.st_mode)
    if not correct or s.st_uid != os.getuid() or s.st_mode & 0o077:
        fail('State must be private and owned by the invoking user: ' + path)


class State:
    def __init__(self, owner, root):
        if not re.fullmatch(r'[a-z][a-z0-9-]*', owner):
            fail('Invalid owner.')
        self.owner, self.root = owner, absolute(root)
        self.path = root + '/managed.json'
        self.ancestors = parents(self.path)
        if os.path.lexists(root):
            private(root, True)
        if os.path.lexists(root + '/backups'):
            private(root + '/backups', True)
        self.observed = snapshot(self.path)
        if self.observed is None:
            self.data = dict(version=1, owner=owner, artifacts={}, backups={})
            return
        private(self.path)
        try:
            self.data = json.loads(read_bytes(self.path, self.observed))
            d = self.data
            if not (set(d) == {'version', 'owner', 'artifacts', 'backups'}):
                raise ValueError
            if not (d['version'] == 1 and d['owner'] == owner):
                raise ValueError
            if not (isinstance(d['artifacts'], dict) and isinstance(d['backups'], dict)):
                raise ValueError
            for path, r in d['artifacts'].items():
                if not (absolute(path) == r['destination'] and r['owner'] == owner):
                    raise ValueError
                if not (r['status'] == 'completed' and r['kind'] in ('link', 'file', 'block', 'directory')):
                    raise ValueError
                if not (isinstance(r['expected'], dict) and isinstance(r['backups'], list)):
                    raise ValueError
                if not (set(r) <= {'destination', 'owner', 'kind', 'status', 'expected', 'backups', 'retain', 'begin', 'end'}):
                    raise ValueError
                if r['kind'] == 'block':
                    if not (isinstance(r['begin'], str) and isinstance(r['end'], str)):
                        raise ValueError
                    if not (re.fullmatch('[0-9a-f]{64}', r['expected']['sha256'])):
                        raise ValueError
                else:
                    expected = r['expected']
                    if not (all(isinstance(expected[k], int) for k in ('device', 'inode', 'mode', 'uid', 'gid'))):
                        raise ValueError
                    if r['kind'] == 'link':
                        if not (stat.S_ISLNK(expected['mode']) and isinstance(expected['target'], str)):
                            raise ValueError
                    elif r['kind'] == 'file':
                        if not (stat.S_ISREG(expected['mode']) and re.fullmatch('[0-9a-f]{64}', expected['sha256'])):
                            raise ValueError
                    else:
                        if not (stat.S_ISDIR(expected['mode'])):
                            raise ValueError
                if not (all(b in d['backups'] for b in r['backups'])):
                    raise ValueError
            for key, b in d['backups'].items():
                if not (re.fullmatch('[0-9a-f]{32}', key)):
                    raise ValueError
                if not (set(b) == {'destination', 'expected', 'status'}):
                    raise ValueError
                absolute(b['destination'])
                if not (b['status'] in ('completed', 'restored') and isinstance(b['expected'], dict)):
                    raise ValueError
        except (ValueError, TypeError, KeyError, AssertionError):
            fail('Corrupt or incomplete ownership state; preserve artifacts and inspect privately: ' + self.path)

    def save(self):
        verify_parents(self.ancestors)
        if snapshot(self.path) != self.observed:
            fail('Ownership state changed concurrently: ' + self.path)
        fd, temp = tempfile.mkstemp(prefix='.ledger-', dir=self.root)
        try:
            with os.fdopen(fd, 'w') as f:
                json.dump(self.data, f, sort_keys=True)
                f.write('\n')
                f.flush()
                os.fsync(f.fileno())
            if snapshot(self.path) != self.observed:
                fail('Ownership state changed concurrently: ' + self.path)
            previous = None
            if self.observed is not None:
                recovery = tempfile.mkdtemp(prefix='.ledger-recovery-', dir=self.root)
                previous = recovery + '/previous'
                os.rename(self.path, previous)
                if snapshot(previous) != self.observed:
                    fail('Ownership state raced; previous ledger preserved privately: ' + recovery)
            # Never clobber a ledger that appeared after the last observation.
            # On failure retain the previous ledger for explicit private recovery.
            verify_parents(self.ancestors)
            os.link(temp, self.path, follow_symlinks=False)
            if snapshot(self.path) != snapshot(temp):
                fail('Published ownership state changed concurrently: ' + self.path)
            self.observed = snapshot(self.path)
            if previous:
                os.unlink(previous)
                os.rmdir(recovery)
        finally:
            if os.path.exists(temp):
                os.unlink(temp)


def mkdirs(path):
    parents(path + '/child')
    if os.path.isdir(path):
        return
    mkdirs(str(Path(path).parent))
    os.mkdir(path, 0o700)


@contextmanager
def writer(owner, root):
    # ponytail: one owner-state lock; no filesystem-wide transaction is claimed.
    import fcntl
    State(owner, root)  # Validate existing state before any known write.
    mkdirs(root)
    private(root, True)
    lock = root + '/managed.lock'
    fd = os.open(lock, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    try:
        private(lock)
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        yield State(owner, root)
    finally:
        os.close(fd)


def backup_possible(path, observed, root):
    if not observed or not (stat.S_ISREG(observed['mode']) or stat.S_ISLNK(observed['mode'])):
        fail('Cannot safely back up this filesystem type: ' + path)
    if observed['uid'] != os.getuid() or os.lstat(path).st_nlink != 1:
        fail('Cannot preserve foreign ownership or hard-linked original: ' + path)
    existing = Path(root)
    while not existing.exists():
        existing = existing.parent
    if existing.stat().st_dev != observed['device']:
        fail('Backup requires the same filesystem to preserve original metadata: ' + path)


def check(plan, owner, state_root, adopt=(), replace=()):
    validate_plan(plan)
    approvals = [absolute(p) for p in (*adopt, *replace)]
    if set(approvals) - {a['destination'] for a in plan}:
        fail('Approval is not a destination in this plan.')
    state = State(owner, state_root)
    observations = {}
    planned_directories = {str(x) for x in Path(state_root).parents}
    for a in plan:
        p = a['destination']
        if (p == state_root or state_root in [str(x) for x in Path(p).parents]
                or (a['kind'] != 'directory' and p in [str(x) for x in Path(state_root).parents])):
            fail('Artifact overlaps ownership state.')
        parent = parents(p)
        if any(str(x) not in parent and str(x) not in planned_directories for x in Path(p).parents):
            fail('Missing parent must precede its child as a directory artifact: ' + p)
        now = snapshot(p)
        observations[p] = (now, parent)
        r = state.data['artifacts'].get(p)
        if a['kind'] == 'directory':
            if p in approvals:
                fail('Directories are only owned when created; adoption/replacement is unsupported: ' + p)
            planned_directories.add(p)
            if now and not stat.S_ISDIR(now['mode']):
                fail('Directory conflict: ' + p)
            if r and not owned(r, now):
                fail('Recorded directory changed: ' + p)
            continue
        if a['kind'] == 'block':
            if now and not stat.S_ISREG(now['mode']):
                fail('Managed block requires a regular file, not a symlink: ' + p)
            desired(a, now)  # Malformed save conflicts precede all writes.
        if r and owned(r, now):
            if not matches(a, now):
                backup_possible(p, now, state_root)
            continue
        if r and p not in replace:
            fail('Owned artifact changed or disappeared: ' + p)
        if now is None:
            continue
        if matches(a, now) and p in adopt and not r:
            continue
        if a['kind'] == 'block' and a.get('append') and not r and not split_block(read_bytes(p, now), a)[1]:
            backup_possible(p, now, state_root)
            continue
        if p in replace:
            backup_possible(p, now, state_root)
            continue
        fail('Existing artifact requires --adopt (matching) or --replace: ' + p)
    keep = {a['destination'] for a in plan}
    for p, r in state.data['artifacts'].items():
        if p in keep or r.get('retain'):
            continue
        parent, now = parents(p), snapshot(p)
        if not owned(r, now):
            fail('Deselection preserves modified/uncertain artifact: ' + p)
        if r['kind'] != 'directory':
            backup_possible(p, now, state_root)
        observations[p] = (now, parent)
    return observations


def record(state, a, now, backups=()):
    r = {k: a[k] for k in ('kind', 'destination', 'retain', 'begin', 'end') if k in a}
    expected = now
    if a['kind'] == 'block':
        expected = {'sha256': hashlib.sha256(split_block(read_bytes(a['destination'], now), a)[1]).hexdigest()}
    r.update(owner=state.owner, expected=expected, status='completed', backups=list(backups))
    state.data['artifacts'][a['destination']] = r
    state.save()


def revalidate(path, observed, parent):
    verify_parents(parent)
    if snapshot(path) != observed:
        fail('Destination changed concurrently: ' + path)


def backup(state, path, observed, parent):
    backup_possible(path, observed, state.root)
    directory = state.root + '/backups'
    mkdirs(directory)
    private(directory, True)
    key = uuid.uuid4().hex
    location = directory + '/' + key
    os.mkdir(location, 0o700)
    b = dict(destination=path, expected=observed, status='pending')
    state.data['backups'][key] = b
    state.save()
    revalidate(path, observed, parent)
    # Rename preserves the original inode, symlink identity and all metadata.
    # Same-filesystem only; unexpected races remain in this private backup.
    os.rename(path, location + '/original')
    if snapshot(location + '/original') != observed:
        fail('Original changed during backup; preserved uncertain backup: ' + key)
    b['status'] = 'completed'
    state.save()
    return key


def dotbot_link(target, destination):
    from argparse import Namespace
    from dotbot.context import Context
    from dotbot.plugins.link import Link
    # Use the actual pinned engine, with literal resolved paths. _link bypasses
    # handle's second expandvars pass (a user's path may contain a literal $).
    with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
        success = Link(Context(str(ROOT), Namespace(dry_run=False)))._link(
            target, destination, relative=False, canonical_path=False,
            ignore_missing=True, link_type='symlink', assume_gone=False)
    if not success:
        fail('Dotbot link creation failed.')


def publish(a, content, parent, mode=0o600):
    p = a['destination']
    verify_parents(parent)
    with tempfile.TemporaryDirectory(prefix='.dots-write-', dir=str(Path(p).parent)) as temp:
        stage = temp + '/artifact'
        if a['kind'] == 'link':
            dotbot_link(a['target'], stage)
        else:
            fd = os.open(stage, os.O_CREAT | os.O_EXCL | os.O_WRONLY, mode)
            with os.fdopen(fd, 'wb') as f:
                f.write(content)
                f.flush()
                os.fsync(f.fileno())
        expected = snapshot(stage)
        revalidate(p, None, parent)
        os.link(stage, p, follow_symlinks=False)  # Atomic no-clobber publication.
        if snapshot(p) != expected:
            fail('Published artifact changed; preserve uncertain destination: ' + p)
        return expected


def apply(plan, owner, state_root, adopt=(), replace=()):
    observations = check(plan, owner, state_root, adopt, replace)
    state_parents = {str(p) for p in Path(state_root).parents if not os.path.lexists(p)}
    with writer(owner, state_root) as state:
        # Lock serializes installers, revalidation also detects user edits.
        current = check(plan, owner, state_root, adopt, replace)
        for p, (now, ancestors) in current.items():
            previous, old_ancestors = observations[p]
            if now != previous or {k: v for k, v in ancestors.items() if k not in state_parents} != old_ancestors:
                fail('Plan observations changed before installation.')
        observations = current
        created_parents = {}
        for a in plan:
            p = a['destination']
            now, parent = observations[p]
            parent = dict(parent, **{k: v for k, v in created_parents.items() if k in [str(x) for x in Path(p).parents]})
            revalidate(p, now, parent)
            r = state.data['artifacts'].get(p)
            if a['kind'] == 'directory':
                if now is None:
                    state.data['artifacts'][p] = dict(kind='directory', destination=p, status='pending')
                    state.save()
                    revalidate(p, None, parent)
                    os.mkdir(p, a.get('mode', 0o700))
                    created = snapshot(p)
                    created_parents[p] = [created['device'], created['inode']]
                    record(state, a, created)
                continue  # Existing directories are never adopted implicitly.
            if matches(a, now) and ((r and r['kind'] == a['kind'] and owned(r, now)) or (not r and p in adopt)):
                if not r:
                    record(state, a, now)
                continue
            content = desired(a, now)
            backups = list(r['backups']) if r else []
            if now:
                backups.append(backup(state, p, now, parent))
            state.data['artifacts'][p] = dict(kind=a['kind'], destination=p, status='pending')
            state.save()
            expected = publish(a, content, parent)
            record(state, a, expected, backups)
        keep = {a['destination'] for a in plan}
        _remove(state, [p for p, r in state.data['artifacts'].items() if p not in keep and not r.get('retain')])


def _remove(state, paths):
    conflicts = []
    for p in sorted(paths, key=lambda x: (x.count('/'), x), reverse=True):
        r = state.data['artifacts'].get(p)
        if not r or r.get('retain'):
            continue
        parent = parents(p)
        now = snapshot(p)
        if not owned(r, now):
            conflicts.append(p)
            continue
        revalidate(p, now, parent)
        if r['kind'] == 'directory':
            try:
                os.rmdir(p)
            except OSError:
                continue  # Never remove nonempty directories.
        elif r['kind'] == 'block':
            prefix, _, suffix = split_block(read_bytes(p, now), r)
            backup(state, p, now, parent)
            publish(dict(kind='file', destination=p), prefix + suffix, parent)
        else:
            # Quarantine first: a race must never unlink an unexpected artifact.
            key = backup(state, p, now, parent)
            # Retain exact recovery evidence; no broad deletion of old backups.
            state.data['backups'][key]['status'] = 'completed'
        del state.data['artifacts'][p]
        state.save()
    if conflicts:
        fail('Preserved modified/uncertain owned artifacts: ' + ', '.join(conflicts))


def remove(owner, state_root, paths=None):
    state = State(owner, state_root)
    if state.observed is None:
        fail('No ownership ledger; nothing may be removed.')
    with writer(owner, state_root) as state:
        _remove(state, list(state.data['artifacts']) if paths is None else [absolute(p) for p in paths])


def restore(owner, state_root, backup_id, replace=()):
    initial = State(owner, state_root)
    if backup_id not in initial.data['backups']:
        fail('Select an exact completed backup ID; no restore authority is available.')
    if set(replace) - {initial.data['backups'][backup_id]['destination']}:
        fail('Restore approval must name its exact destination.')
    with writer(owner, state_root) as state:
        b = state.data['backups'].get(backup_id)
        if not b or b['status'] != 'completed':
            fail('Select an exact completed backup ID.')
        p = b['destination']
        original = state.root + '/backups/' + backup_id + '/original'
        parents(original)
        if snapshot(original) != b['expected']:
            fail('Recorded backup changed; cannot restore.')
        parent, now = parents(p), snapshot(p)
        if now:
            if p not in replace:
                fail('Restore destination exists; use --replace for this exact path: ' + p)
            backup(state, p, now, parent)
        revalidate(p, None, parent)
        b['status'] = 'pending'
        state.save()
        revalidate(p, None, parent)
        os.link(original, p, follow_symlinks=False)
        if snapshot(p) != b['expected']:
            fail('Restored artifact changed; preserve destination.')
        # Drop the backup's hardlink so subsequent edits cannot alter originals.
        os.unlink(original)
        b['status'] = 'restored'
        state.data['artifacts'].pop(p, None)
        state.save()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('check', 'apply', 'remove', 'restore'))
    parser.add_argument('--owner', required=True)
    parser.add_argument('--state-root', required=True)
    parser.add_argument('--plan')
    parser.add_argument('--adopt', action='append', default=[])
    parser.add_argument('--replace', action='append', default=[])
    parser.add_argument('--path', action='append')
    parser.add_argument('--backup')
    args = parser.parse_args()
    if ((args.action in ('check', 'apply')) != bool(args.plan)
            or (args.action == 'restore') != bool(args.backup)
            or (args.adopt and args.action not in ('check', 'apply'))
            or (args.replace and args.action == 'remove')
            or (args.path is not None and args.action != 'remove')):
        parser.error('Required or applicable lifecycle options: --plan for check/apply, --backup for restore, --path for remove.')
    try:
        if args.action in ('check', 'apply'):
            with open(args.plan) as f:
                plan = json.load(f)
            globals()[args.action](plan, args.owner, args.state_root, args.adopt, args.replace)
        elif args.action == 'remove':
            remove(args.owner, args.state_root, args.path)
        else:
            restore(args.owner, args.state_root, args.backup, args.replace)
    except Conflict as error:
        print('managed: ' + str(error), file=sys.stderr)
        return 1
    except (OSError, ValueError, TypeError, ImportError):
        # Do not expose plan content, private env bytes or exception payloads.
        print('managed: operation failed; artifacts/backups preserved. Inspect private state at ' + args.state_root, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
