#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export PROJECT_ROOT="$project_root"
test_root=$(mktemp -d "$project_root/.tmp-phoenix-db-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/app/config" "$test_root/bin"
printf '%s\n' '{:postgrex, ">= 0.0.0"}' >"$test_root/app/mix.exs"

cat >"$test_root/bin/utility" <<'SH'
#!/usr/bin/env bash
script="$PROJECT_ROOT/bin/utilities/$1/$2"
shift 2
exec bash "$script" "$@"
SH
chmod +x "$test_root/bin/utility"
export PATH="$test_root/bin:$PATH"
unset BASH_ENV

for format in multiline inline; do
  cat >"$test_root/app/config/config.exs" <<'EX'
config :sample, Sample.Repo,
  database: "common_dev",
  username: "sample_user",
  password: System.get_env("SAMPLE_DB_PASSWORD", "sample_password"),
  hostname: "localhost",
  port: 5433
config :sample, SampleWeb.Endpoint, server: false
EX
  if [[ "$format" == multiline ]]; then
    printf '%s\n' 'config :sample, Sample.Repo,' '  database: "sample_dev",' >"$test_root/app/config/dev.exs"
  else
    printf '%s\n' 'config :sample, Sample.Repo, database: "sample_dev",' >"$test_root/app/config/dev.exs"
  fi
  cat >>"$test_root/app/config/dev.exs" <<'EX'
  username: "sample_user",
  password: System.get_env("SAMPLE_DB_PASSWORD", "sample_password"),
  hostname: "localhost",
  port: 5433
config :sample, SampleWeb.Endpoint, server: false
EX

  database=$(utility phoenix db-credentials --app="$test_root/app" --key=database)
  test "$database" = sample_dev
  url=$(utility phoenix db-connection-url --app="$test_root/app")
  test "$url" = 'postgres://sample_user:sample_password@localhost:5433/sample_dev?sslmode=disable'
  echo "$format credentials and URL passed"
done

printf '%s\n' 'config :sample, Sample.Repo, database: "sample_dev"' >"$test_root/app/config/dev.exs"
test "$(utility phoenix db-credentials --app="$test_root/app" --key=database)" = sample_dev
# Several keys on one line plus a non-credential key, as in a real test.exs; comments are ignored.
printf '%s\n' 'config :sample, Sample.Repo, database: "sample_test", pool: Ecto.Adapters.SQL.Sandbox, port: 5434' \
  '# hostname: "commented-out"' >"$test_root/app/config/test.exs"
test "$(utility phoenix db-connection-url --app="$test_root/app" --test)" = 'postgres://sample_user:sample_password@localhost:5434/sample_test?sslmode=disable'
printf '%s\n' 'config :sample, Sample.Repo, database: System.get_env("DATABASE_URL")' >"$test_root/app/config/dev.exs"
if utility phoenix db-credentials --app="$test_root/app" --key=database >/dev/null 2>&1; then
  echo 'Unsupported credential expression unexpectedly succeeded' >&2
  exit 1
fi
# An unsupported expression in the common config must fail the URL instead of defaulting the user.
printf '%s\n' 'config :sample, Sample.Repo, username: System.fetch_env!("DB_USER"), database: "common_dev"' >"$test_root/app/config/config.exs"
printf '%s\n' 'config :sample, Sample.Repo, database: "sample_dev"' >"$test_root/app/config/dev.exs"
if utility phoenix db-connection-url --app="$test_root/app" >/dev/null 2>&1; then
  echo 'Unsupported common credential expression unexpectedly produced a URL' >&2
  exit 1
fi
echo 'Inline override, environment selection, and unsupported expressions passed'
