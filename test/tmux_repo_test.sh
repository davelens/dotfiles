#!/usr/bin/env bash
set -e

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-tmux-repo-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export print_status=true

# shellcheck source=../bin/utilities/tmux/repo
source "$project_root/bin/utilities/tmux/repo"

printf '#!/usr/bin/env bash\nprintf y\n' >"$test_root/prompt"
chmod +x "$test_root/prompt"
export prompt_user="$test_root/prompt"
confirm_repo_creation "acme/example"
printf '#!/usr/bin/env bash\nprintf n\n' >"$test_root/prompt"
if confirm_repo_creation "acme/example"; then
  exit 1
fi

create_repo "acme/example" "$test_root/acme/example"

test "$(cat "$test_root/acme/example/README.md")" = "# example"
test "$(git -C "$test_root/acme/example" rev-parse --is-inside-work-tree)" = true
test "$(git -C "$test_root/acme/example" branch --show-current)" = master
test "$(git -C "$test_root/acme/example" log -1 --format=%s)" = "initial commit"

mkdir "$test_root/bin"
cat >"$test_root/bin/gh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$GH_LOG"
SH
cat >"$test_root/bin/tmux" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TMUX_LOG"
SH
chmod +x "$test_root/bin/gh" "$test_root/bin/tmux"
export PATH="$test_root/bin:$PATH"
export GH_LOG="$test_root/gh.log"
export TMUX_LOG="$test_root/tmux.log"
export EDITOR=nvim

create_github_repo "acme/example" "$test_root/acme/example"
setup_minimal_windows example "$test_root/acme/example" README.md

grep -Fqx "repo create acme/example --private --source $test_root/acme/example --remote origin --push" "$GH_LOG"
grep -Fqx "repo edit acme/example --default-branch master" "$GH_LOG"
grep -Fqx "send-keys -t example:editor clear && nvim README.md C-m" "$TMUX_LOG"

echo "tmux repo test passed"
