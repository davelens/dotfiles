#!/usr/bin/env bash
set -e

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-tmux-repo-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export print_status=true

# shellcheck source=../bin/utilities/tmux/repo
source "$project_root/bin/utilities/tmux/repo"

create_repo "acme/example" "$test_root/acme/example"

test "$(cat "$test_root/acme/example/README.md")" = "# example"
test "$(git -C "$test_root/acme/example" rev-parse --is-inside-work-tree)" = true

echo "tmux repo test passed"
