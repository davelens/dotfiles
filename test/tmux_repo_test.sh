#!/usr/bin/env bash
set -e

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-tmux-repo-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
export HOME="$test_root/home"
export XDG_CONFIG_HOME="$test_root/config" XDG_DATA_HOME="$test_root/data"
export XDG_CACHE_HOME="$test_root/cache" XDG_STATE_HOME="$test_root/state"
export XDG_BIN_HOME="$test_root/bin" XDG_RUNTIME_DIR="$test_root/runtime"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME" "$XDG_RUNTIME_DIR" "$test_root/template"
# Fixture-only Git identity; never read or alter the user's Git configuration.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TEMPLATE_DIR="$test_root/template"
export GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture@example.invalid
export GIT_COMMITTER_NAME=$GIT_AUTHOR_NAME GIT_COMMITTER_EMAIL=$GIT_AUTHOR_EMAIL
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

cat >"$test_root/bin/utility" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$UTILITY_LOG"
exit "${HELPER_STATUS:-0}"
SH
for name in pgrep pg_isready; do
  printf '#!/usr/bin/env bash\nexit 1\n' >"$test_root/bin/$name"
done
for name in systemctl mysql.server sv; do
  printf '#!/usr/bin/env bash\necho forbidden >>"$SERVICE_LOG"\nexit 99\n' >"$test_root/bin/$name"
done
chmod +x "$test_root/bin/"*
export UTILITY_LOG="$test_root/utility.log" SERVICE_LOG="$test_root/service.log"
printf '#!/usr/bin/env bash\nprintf y\n' >"$test_root/prompt"
ensure_db_running mysql
ensure_db_running postgresql
grep -Fxq 'mariadb start' "$UTILITY_LOG"
grep -Fxq 'postgresql start' "$UTILITY_LOG"
export HELPER_STATUS=7
if ensure_db_running mysql; then exit 1; fi
if ensure_db_running postgresql; then exit 1; fi
[[ ! -e $SERVICE_LOG ]]
echo "tmux repo test passed"
