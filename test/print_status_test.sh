#!/usr/bin/env bash
set -e

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-print-status-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT

cat >"$test_root/cursor" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$CURSOR_LOG"
SH
chmod +x "$test_root/cursor"
export cursor="$test_root/cursor"
export CURSOR_LOG="$test_root/cursor.log"

env -u BASH_ENV cursor="$cursor" CURSOR_LOG="$CURSOR_LOG" \
  "$project_root/bin/utilities/bash/print_status" -ni "Cloning..." >/dev/null
grep -Fqx "move-up:1 move-start clear-down" "$CURSOR_LOG"

echo "print status test passed"
