#!/usr/bin/env bash
# Standalone so this can also be downloaded and reviewed before execution.
set -euo pipefail
set +x
unset BASH_ENV ENV

fail() { printf 'dots remote: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'EOF'
Usage: bash setup/remote/init.sh [--destination ABS] [--source URL_OR_ABS] [-- INSTALL_OPTIONS...]
Acquire public dotfiles and pinned submodules, then run setup/install directly.
Requires a prepared machine (Bash 5, Git, Python and installer filesystem tools).
Default source: https://github.com/davelens/dotfiles.git
Default destination: $HOME/Repositories/davelens/dotfiles
--source accepts that public origin or an explicit absolute local Git source.
Install options pass through unchanged: --select CSV, --save, --adopt PATH,
--replace PATH, --wezterm-destination PATH, --check.
No packages, services, identity setup, implicit updates, or automatic rollback.
EOF
}
source_repo=https://github.com/davelens/dotfiles.git
destination=
while (($#)); do
  case $1 in
    -h|--help) usage; exit 0 ;;
    --destination|--source)
      (($# >= 2)) || fail "Missing value for $1"
      [[ -n $2 ]] || fail "Empty value for $1"
      case $1 in --destination) destination=$2 ;; --source) source_repo=$2 ;; esac
      shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done
((BASH_VERSINFO[0] >= 5)) || fail 'Bash >=5 is required; prepare the machine with dotsys first.'
command -v git >/dev/null 2>&1 || fail 'Git is required; prepare it with dotsys first. No archive fallback.'
[[ ${HOME:-} == /* ]] || fail 'Set an absolute HOME.'
destination=${destination:-$HOME/Repositories/davelens/dotfiles}
[[ $destination == /* && $destination != *$'\n'* && $destination != *$'\r'* ]] || fail 'Supply an absolute destination without line breaks.'
# A symlink destination is never acquisition authority, including a trailing slash.
while [[ $destination == */ && $destination != / ]]; do destination=${destination%/}; done
[[ ! -L $destination ]] || fail 'Refusing a symlink destination; choose a new directory.'
destination=$(realpath -m -- "$destination")
[[ $destination != / && $destination != "$HOME" ]] || fail 'Refusing HOME or the filesystem root as a destination.'
if [[ -e $destination/.git || -L $destination/.git ]]; then
  printf 'dots remote: Existing checkout preserved; no pull or reset performed.\nInstall explicitly: bash %q [INSTALL_OPTIONS...]\nUpdate explicitly: review %q before using dots update from that checkout.\n' "$destination/setup/install" "$destination/README.md" >&2
  exit 1
fi
if [[ -e $destination ]]; then
  [[ -d $destination ]] || fail 'Destination is not a directory; existing content preserved.'
  [[ -z $(find "$destination" -mindepth 1 -maxdepth 1 -print -quit) ]] || fail 'Refusing nonempty non-repository destination; choose an empty/new directory. Existing content preserved.'
fi
case $source_repo in
  https://github.com/davelens/dotfiles.git) ;;
  /*) [[ -d $source_repo ]] && git -C "$source_repo" rev-parse --git-dir >/dev/null 2>&1 || fail 'Local source must be a Git repository.' ;;
  *) fail 'Use the known public HTTPS origin or an absolute local Git source.' ;;
esac
trap 'status=$?; printf "dots remote: Failed; completed changes are preserved. No automatic rollback. Inspect %s and rerun its setup/install explicitly when prepared.\n" "$destination" >&2; exit "$status"' ERR
mkdir -p -- "${destination%/*}"
GIT_TERMINAL_PROMPT=0 git clone --recurse-submodules -- "$source_repo" "$destination"
[[ -f $destination/setup/install ]] || fail 'Acquired source has no setup/install; checkout preserved.'
bash "$destination/setup/install" "$@"
printf 'dots remote: Configuration operation complete. Check runtime readiness separately with setup/check readiness.\n'
