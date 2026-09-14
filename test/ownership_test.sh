#!/usr/bin/env bash
set -euo pipefail
source "${BASH_SOURCE[0]%/*}/install_test.sh"
fixture ownership
python_test <<'PY'
import json, os, socket, stat, sys
from pathlib import Path
from unittest.mock import patch
sys.path.insert(0, sys.argv[1])
import managed as m
home = Path(os.environ['HOME'])


def case(name):
    root = home/name
    root.mkdir()
    return root, str(root/'state'), str(root/'destination')


def link(p, target='/explicit/stable/source'):
    return dict(kind='link', destination=p, target=target)


def fails(fn, *args, **kwargs):
    try:
        fn(*args, **kwargs)
    except (m.Conflict, OSError):
        return
    raise AssertionError('Expected conservative failure: '+fn.__name__)


def ledger(state):
    return json.loads(Path(state, 'managed.json').read_text())


# All existing filesystem types conflict, including broken and looping links.
for kind in ('file', 'empty-directory', 'directory', 'link', 'broken-link', 'loop', 'fifo', 'socket', 'hardlink'):
    root, state, p = case(kind)
    sock = None
    if kind in ('file', 'hardlink'):
        Path(p).write_text('original secret-ownership-sentinel')
        if kind == 'hardlink': os.link(p, root/'other')
    elif kind in ('empty-directory', 'directory'):
        Path(p).mkdir()
        if kind == 'directory': (Path(p)/'private').write_text('keep')
    elif kind in ('link', 'broken-link', 'loop'):
        target = p if kind == 'loop' else str(root/('referent' if kind == 'link' else 'absent'))
        if kind == 'link': Path(target).write_text('untouched referent')
        os.symlink(target, p)
    elif kind == 'fifo': os.mkfifo(p)
    else:
        # AF_UNIX paths are short enough even with the long approved worktree root.
        sock = socket.socket(socket.AF_UNIX)
        old = os.getcwd()
        os.chdir(root)
        sock.bind('destination')
        os.chdir(old)
    before = m.snapshot(p)
    fails(m.check, [link(p)], 'dotsys', state)
    fails(m.apply, [link(p)], 'dotsys', state)
    assert m.snapshot(p) == before and not Path(state).exists()
    if kind in ('empty-directory', 'directory', 'fifo', 'socket', 'hardlink'):
        fails(m.apply, [link(p)], 'dotsys', state, replace=[p])
        assert m.snapshot(p) == before and not Path(state).exists()
    if sock: sock.close()

# Verified adoption does not churn link identity, then grants exact cleanup.
root, state, p = case('adoption')
os.symlink('/explicit/stable/source', p)
before = m.snapshot(p)
fails(m.apply, [link(p)], 'dotsys', state)
fails(m.apply, [link(p)], 'dotsys', state, adopt=[str(root/'not-the-destination')])
m.apply([link(p)], 'dotsys', state, adopt=[p])
assert m.snapshot(p) == before
saved = Path(state, 'managed.json').read_bytes()
m.apply([link(p)], 'dotsys', state)
assert Path(state, 'managed.json').read_bytes() == saved
m.remove('dotsys', state)
assert not os.path.lexists(p)

# Retargeted or recreated identical-looking links are not unchanged owned links.
for name, target in [('retarget', '/user/target'), ('recreated', '/explicit/stable/source')]:
    root, state, p = case(name)
    m.apply([link(p)], 'dotsys', state)
    os.rename(p, root/'saved-link')  # Keep inode allocated to avoid reuse.
    os.symlink(target, p)
    before = m.snapshot(p)
    fails(m.check, [link(p)], 'dotsys', state)
    fails(m.apply, [], 'dotsys', state)
    fails(m.remove, 'dotsys', state)
    assert m.snapshot(p) == before

# Explicit replacement of a recreated match must renew authority, not skip it.
root, state, p = case('replace-recreated-match')
m.apply([link(p)], 'dotsys', state)
os.rename(p, root/'old-link')
os.symlink('/explicit/stable/source', p)
before = m.snapshot(p)
m.apply([link(p)], 'dotsys', state, replace=[p])
assert ledger(state)['artifacts'][p]['expected'] == m.snapshot(p)
assert ledger(state)['artifacts'][p]['backups']
assert m.snapshot(p) != before
m.remove('dotsys', state)
assert not os.path.lexists(p)

# Replacing symlinks preserves the link itself, not its referent, and metadata.
root, state, p = case('restore-link')
referent = root/'referent'
referent.write_text('private referent')
os.symlink('referent', p)
before = m.snapshot(p)
m.apply([link(p)], 'dotsys', state, replace=[p])
r = ledger(state)['artifacts'][p]
backup = r['backups'][0]
original = Path(state, 'backups', backup, 'original')
assert os.readlink(original) == 'referent' and m.snapshot(str(original)) == before
assert referent.read_text() == 'private referent'
fails(m.restore, 'dotsys', state, backup)
m.restore('dotsys', state, backup, replace=[p])
assert os.readlink(p) == 'referent' and referent.read_text() == 'private referent'
assert p not in ledger(state)['artifacts']
fails(m.restore, 'dotsys', state, backup)

# Generated/copy files track content and identity; updates back up exact originals.
root, state, p = case('files')
Path(p).write_text('original')
os.chmod(p, 0o640)
before = m.snapshot(p)
a = dict(kind='file', destination=p, content='generated')
m.apply([a], 'dots', state, replace=[p])
backup = ledger(state)['artifacts'][p]['backups'][0]
assert m.snapshot(str(Path(state, 'backups', backup, 'original'))) == before
assert Path(p).read_text() == 'generated'
a['content'] = 'updated'
m.apply([a], 'dots', state)
assert Path(p).read_text() == 'updated'
Path(p).write_text('edited')
fails(m.apply, [a], 'dots', state)
fails(m.remove, 'dots', state)
assert Path(p).read_text() == 'edited'
fails(m.restore, 'dots', state, backup)
m.restore('dots', state, backup, replace=[p])
assert Path(p).read_text() == 'original' and stat.S_IMODE(os.lstat(p).st_mode) == 0o640

# A matching unowned file requires adoption; missing state grants no authority.
root, state, p = case('file-adoption')
Path(p).write_text('match')
a = dict(kind='file', destination=p, content='match')
fails(m.apply, [a], 'dots', state)
m.apply([a], 'dots', state, adopt=[p])
Path(state, 'managed.json').unlink()
fails(m.remove, 'dots', state)
fails(m.apply, [a], 'dots', state)
assert Path(p).read_text() == 'match'

# State corruption, wrong owner, insecure modes, symlinks and pending operations.
for name, data in [('json', '{bad'), ('shape', '{"version":1}'),
                   ('container', '{"version":1,"owner":"dots","artifacts":[],"backups":{}}')]:
    root, state, p = case('corrupt-'+name)
    m.apply([link(p)], 'dots', state)
    Path(state, 'managed.json').write_text(data)
    fails(m.check, [link(p)], 'dots', state)
    fails(m.remove, 'dots', state)
    assert os.readlink(p) == '/explicit/stable/source'
root, state, p = case('owner-and-state-identity')
m.apply([link(p)], 'dots', state)
fails(m.remove, 'dotsys', state)
os.chmod(Path(state, 'managed.json'), 0o644)
fails(m.remove, 'dots', state)
os.chmod(Path(state, 'managed.json'), 0o600)
os.rename(Path(state, 'managed.json'), root/'ledger')
os.symlink(root/'ledger', Path(state, 'managed.json'))
fails(m.remove, 'dots', state)
assert os.readlink(p) == '/explicit/stable/source'

# Existing directories are not enrolled, and recorded dirs are removed only empty.
root, state, p = case('directories')
Path(p).mkdir()
existing = dict(kind='directory', destination=p)
created = dict(kind='directory', destination=str(root/'created'))
new_link = link(str(root/'created'/'helper'))
m.apply([existing, created, new_link], 'dotsys', state)
Path(root/'created'/'private').write_text('keep')
m.remove('dotsys', state)
assert Path(p).is_dir() and Path(root/'created'/'private').read_text() == 'keep'
assert not os.path.lexists(new_link['destination'])
Path(root/'created'/'private').unlink()
m.remove('dotsys', state)
assert not Path(root/'created').exists() and Path(p).is_dir()

# Ancestor symlinks are never followed, even when pointing at a directory.
root, state, p = case('symlink-parent')
(root/'actual').mkdir()
os.symlink(root/'actual', p)
fails(m.apply, [link(p+'/file')], 'dots', state)
assert not list((root/'actual').iterdir()) and not Path(state).exists()

# All known state/parent conflicts precede configuration or state creation.
root, state, p = case('state-overlap')
fails(m.apply, [link(str(root/'nested'))], 'dots', str(root/'nested'/'state'))
assert not (root/'nested').exists()
root, state, p = case('missing-parent')
fails(m.check, [link(str(root/'missing'/'link'))], 'dots', state)
assert not Path(state).exists()
root, state, p = case('unsafe-backup-directory')
m.apply([link(p)], 'dots', state)
(root/'foreign').mkdir()
os.symlink(root/'foreign', Path(state, 'backups'))
new = link(str(root/'new'))
fails(m.apply, [new, link(p, '/changed')], 'dots', state)
assert not os.path.lexists(new['destination'])
assert os.readlink(p) == '/explicit/stable/source'

# A failed backup leaves the original untouched and an incomplete journal blocks retries.
root, state, p = case('backup-failure')
Path(p).write_text('original')
with patch.object(m.os, 'rename', side_effect=OSError('controlled backup failure')):
    fails(m.apply, [link(p)], 'dots', state, replace=[p])
assert Path(p).read_text() == 'original'
fails(m.apply, [link(p)], 'dots', state, replace=[p])

# A failed write does not roll back earlier completed artifacts or claim failed ones.
root, state, p = case('write-failure')
a, b = link(p), link(str(root/'second'))
original_publish = m.publish
def failed_second(artifact, *args, **kwargs):
    if artifact['destination'] == b['destination']: raise OSError('controlled write failure')
    return original_publish(artifact, *args, **kwargs)
with patch.object(m, 'publish', failed_second):
    fails(m.apply, [a, b], 'dots', state)
assert os.readlink(p) == a['target'] and not os.path.lexists(b['destination'])
assert ledger(state)['artifacts'][p]['status'] == 'completed'
assert ledger(state)['artifacts'][b['destination']]['status'] == 'pending'
fails(m.remove, 'dots', state)

# No-clobber publication catches an independently appearing destination.
root, state, p = case('concurrent-publication')
real_link = m.dotbot_link
def intruder(target, stage):
    real_link(target, stage)
    Path(p).write_text('concurrent user file')
with patch.object(m, 'dotbot_link', intruder):
    fails(m.apply, [link(p)], 'dots', state)
assert Path(p).read_text() == 'concurrent user file'
fails(m.apply, [link(p)], 'dots', state)

# A replacement during backup remains recoverable and never becomes owned.
root, state, p = case('concurrent-backup')
Path(p).write_text('original')
real_rename = os.rename
def race(source, destination):
    if source == p:
        real_rename(p, root/'user-original')
        Path(p).write_text('concurrent replacement')
    real_rename(source, destination)
with patch.object(m.os, 'rename', race):
    fails(m.apply, [link(p)], 'dots', state, replace=[p])
assert (root/'user-original').read_text() == 'original'
backups = ledger(state)['backups']
assert len(backups) == 1
key = next(iter(backups))
assert Path(state, 'backups', key, 'original').read_text() == 'concurrent replacement'
assert backups[key]['status'] == 'pending'

# Parent replacement is detected, not used as authority over the new directory.
root, state, p = case('concurrent-parent')
(root/'parent').mkdir()
p = str(root/'parent'/'destination')
def changed_parent(artifact, *args, **kwargs):
    os.rename(root/'parent', root/'old-parent')
    (root/'parent').mkdir()
    return original_publish(artifact, *args, **kwargs)
with patch.object(m, 'publish', changed_parent):
    fails(m.apply, [link(p)], 'dots', state)
assert not os.path.lexists(p)

# Newly created ancestors also retain identity across subsequent artifacts.
root, state, p = case('concurrent-created-parent')
parent = str(root/'created')
a = dict(kind='directory', destination=parent)
real_record = m.record
def replace_created(state, artifact, *args, **kwargs):
    real_record(state, artifact, *args, **kwargs)
    if artifact['destination'] == parent:
        os.rename(parent, root/'old-parent')
        Path(parent).mkdir()
with patch.object(m, 'record', replace_created):
    fails(m.apply, [a, link(parent+'/helper')], 'dots', state)
assert not os.path.lexists(parent+'/helper')

# Concurrent ledger replacement is not silently overwritten.
root, state, p = case('concurrent-ledger')
m.apply([link(p)], 'dots', state)
s = m.State('dots', state)
real_mkstemp = m.tempfile.mkstemp
def changed_ledger(*args, **kwargs):
    result = real_mkstemp(*args, **kwargs)
    os.rename(Path(state, 'managed.json'), root/'old-ledger')
    Path(state, 'managed.json').write_text('concurrent ledger')
    return result
with patch.object(m.tempfile, 'mkstemp', changed_ledger):
    fails(s.save)
assert Path(state, 'managed.json').read_text() == 'concurrent ledger'

# A ledger race at the publication boundary preserves the competing ledger.
root, state, p = case('ledger-publication-race')
m.apply([link(p)], 'dots', state)
s = m.State('dots', state)
real_link_call = os.link
def race_ledger(source, destination, **kwargs):
    if destination == s.path:
        Path(destination).write_text('concurrent ledger at publication')
    return real_link_call(source, destination, **kwargs)
with patch.object(m.os, 'link', race_ledger):
    fails(s.save)
assert Path(s.path).read_text() == 'concurrent ledger at publication'

# A held installer lock blocks a second writer, but read-only check needs no lock.
import fcntl
root, state, p = case('lock')
m.apply([link(p)], 'dots', state)
with open(Path(state, 'managed.lock'), 'r+') as f:
    fcntl.flock(f, fcntl.LOCK_EX)
    m.check([link(p)], 'dots', state)
    fails(m.apply, [link(p)], 'dots', state)

# Unsafe cross-filesystem backup is rejected before touching an original.
root, state, p = case('cross-device')
Path(p).write_text('original')
observed = m.snapshot(p)
observed['device'] += 1
fails(m.backup_possible, p, observed, state)
assert Path(p).read_text() == 'original'
# The CLI is the dotsys seam; optimization must never disable ledger validation.
import subprocess
root, state, p = case('cli')
plan_file = root/'plan.json'
plan_file.write_text(json.dumps([link(p)]))
cli = [sys.executable, '-I', '-B', '-O', str(Path(sys.argv[1])/'managed.py')]
def run(action, *args, success=True):
    result = subprocess.run(cli+[action, '--owner', 'dotsys', '--state-root', state, *args], capture_output=True)
    assert (result.returncode == 0) == success
    assert b'secret-ownership-sentinel' not in result.stdout + result.stderr
run('check', '--plan', str(plan_file))
assert not Path(state).exists()
run('apply', '--plan', str(plan_file))
assert os.readlink(p) == '/explicit/stable/source'
run('remove', '--replace', p, success=False)
run('remove', '--path', p)
key = next(iter(ledger(state)['backups']))
run('restore', '--backup', key)
assert os.readlink(p) == '/explicit/stable/source'
run('apply', '--plan', str(plan_file), '--adopt', p)
data = ledger(state)
data['owner'] = 'wrong-owner'
Path(state, 'managed.json').write_text(json.dumps(data))
run('remove', success=False)
assert os.readlink(p) == '/explicit/stable/source'
print('ownership API scenarios passed')
PY
assert test ! -e "$test_root/ownership/external-operations"
printf 'ownership test passed\n'
