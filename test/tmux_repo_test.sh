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

echo "tmux repo test passed"
