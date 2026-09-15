#!/usr/bin/env bash
# Compatibility route; package ownership lives entirely in dotsys.
set -e
set +x
unset BASH_ENV ENV
entry=${BASH_SOURCE[0]}
[[ $entry == */* ]] || entry="./$entry"
count=0
while [[ -L $entry ]]; do
  directory=$(cd -P -- "${entry%/*}" && pwd)
  entry=$(readlink -- "$entry")
  [[ $entry == /* ]] || entry="$directory/$entry"
  ((count+=1))
  ((count <= 40)) || exit 1
done
root=$(cd -P -- "${entry%/*}/../.." && pwd)
delegate_root=${DOTSYS_REPO_HOME:-${root%/*}/dotsys}
[[ $delegate_root == /* && -f $delegate_root/shared/brew/init.sh ]] || {
  printf 'brew init: Missing dotsys shared/brew/init.sh; obtain a stable dotsys checkout and set DOTSYS_REPO_HOME to its absolute path. No packages were installed.\n' >&2
  exit 1
}
exec bash "$delegate_root/shared/brew/init.sh" "$@"
