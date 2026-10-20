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
EX

  database=$(utility phoenix db-credentials --app="$test_root/app" --key=database)
  test "$database" = sample_dev
  url=$(utility phoenix db-connection-url --app="$test_root/app")
  test "$url" = 'postgres://sample_user:sample_password@localhost:5433/sample_dev?sslmode=disable'
  echo "$format credentials and URL passed"
done

printf '%s\n' 'config :sample, Sample.Repo, database: "sample_dev"' >"$test_root/app/config/dev.exs"
test "$(utility phoenix db-credentials --app="$test_root/app" --key=database)" = sample_dev
echo 'Standalone inline database passed'
