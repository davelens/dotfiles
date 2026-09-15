#!/usr/bin/env bash
set -euo pipefail
project_root=$(cd "${BASH_SOURCE[0]%/*}/.." && pwd)
test_root=$(mktemp -d "$project_root/.tmp-requirements-test.XXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
export HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/config" XDG_DATA_HOME="$test_root/data"
export XDG_CACHE_HOME="$test_root/cache" XDG_STATE_HOME="$test_root/state" XDG_BIN_HOME="$test_root/bin"
export XDG_RUNTIME_DIR="$test_root/runtime" BREW_PATH="$test_root/brew"
export TEST_OS=arch DOTS_INSTALL_SELECTION=''
real_mise=$(type -P mise || true)
source_root="$test_root/source"
tools="$test_root/tools"
mkdir -p "$source_root/setup" "$source_root/bash/env" "$source_root/bin/autoload" \
  "$source_root/config/mise" "$source_root/dotbot/src/dotbot" "$source_root/dotbot/bin" \
  "$XDG_CONFIG_HOME/dots" "$tools" "$HOME"
cp "$project_root/setup/"{common.sh,check,requirements.sh} "$source_root/setup/"
cp "$project_root/bash/env/"{xdg,path,brew}.sh "$source_root/bash/env/"
cp "$project_root/config/mise/config.toml" "$source_root/config/mise/"
cp "$project_root/dotbot/pyproject.toml" "$source_root/dotbot/"
cp "$project_root/dotbot/bin/dotbot" "$source_root/dotbot/bin/"
cp "$project_root/dotbot/src/dotbot/cli.py" "$source_root/dotbot/src/dotbot/"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$TEST_OS"\n' > "$source_root/bin/autoload/os"
cat > "$XDG_CONFIG_HOME/dots/env" <<'SH'
export PRIVATE_SENTINEL=secret-requirements-sentinel
printf '%s\n' "$PRIVATE_SENTINEL"
export MISE_LOG_FILE="$HOME/unsafe.log"
export MISE_ENV_FILE="$HOME/unsafe.env"
export MISE_TRUSTED_CONFIG_PATHS=/
SH
printf 'exit 93\n' > "$HOME/.bash_profile"
printf 'exit 94\n' > "$HOME/.env"
for tool in bash git python3 readlink dirname env realpath cp mv rm mkdir ln stat sed; do
  ln -s "$(type -P "$tool")" "$tools/$tool"
done
# Spies fail if a checker executes any provisioner, service, or ordinary app.
for tool in tmux dvim nvim delta ghostty foot sway swaymsg swaynag rofi rofi-start autotiling-rs \
  swayidle swaylock wl-copy wl-paste wl-clip-persist cliphist kanshi qs dshell systemctl uwsm \
  sv loginctl turnstile-update-runit-env dbus-update-activation-environment borders sketchybar \
  wsl.exe windows-open windows-clipboard wslpath wezterm brew sudo pacman xbps-install curl ssh-add; do
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$0 $*" >> %q\nexit 99\n' "$test_root/operations" > "$tools/$tool"
  chmod +x "$tools/$tool"
done
cat > "$tools/mise" <<'SH'
#!/usr/bin/env bash
[[ $# == 7 && $1 == -C ]] || exit 90
[[ $MISE_SAFE == 1 && $MISE_NO_CONFIG == 1 && $MISE_NO_ENV == 1 && $MISE_NO_HOOKS == 1 && $MISE_OFFLINE == 1 ]] || exit 91
[[ $MISE_CACHE_DIR == /dev/null && $MISE_DATA_DIR == /dev/null && $MISE_STATE_DIR == /dev/null && $MISE_TMP_DIR == /dev/null && $MISE_LOG_FILE == /dev/null ]] || exit 92
[[ -z ${PRIVATE_SENTINEL+x} && -z ${MISE_ENV_FILE+x} && -z ${MISE_TRUSTED_CONFIG_PATHS+x} && -z ${BASH_ENV+x} ]] || exit 93
if [[ $3 == config && $4 == get && $5 == tools && $6 == --file && $7 == "$2/config.toml" ]]; then
  printf 'nodejs = "22.0.0"\ngolang = "latest"\npostgres = "18.6"\n'
elif [[ $3 == ls && $4 == --installed && $5 == --offline && $6 == --json ]]; then
  if [[ $7 == postgres ]]; then
    printf '[{"version":"18.6","installed":true,"active":false}]\n'
  else
    printf '[{"version":"22.0.0","installed":true,"active":false}]\n'
  fi
else
  exit 94
fi
SH
cat > "$tools/powershell.exe" <<'SH'
#!/usr/bin/env bash
[[ $1 == -NoLogo && $2 == -NoProfile && $3 == -NonInteractive && $4 == -Command && $5 == *'Get-Command wezterm.exe -CommandType Application'* ]] || exit 90
[[ ${TEST_WINDOWS_WEZTERM:-0} == 1 ]]
SH
chmod +x "$tools/mise" "$tools/powershell.exe" "$source_root/setup/check"
original_path=$PATH
export PATH="$tools"
assert() { "$@" || { printf 'Assertion failed: %s\n' "$*" >&2; exit 1; }; }
check() { "$tools/bash" --noprofile --norc "$source_root/setup/check" "$@"; }
expect_failure() { if "$@"; then printf 'Expected failure: %s\n' "$*" >&2; exit 1; fi; }
snapshot() {
  PATH="$original_path" find "$test_root" -printf '%P %y %m %l\n' | PATH="$original_path" LC_ALL=C sort
  PATH="$original_path" find "$test_root" -type f -exec sha256sum {} + | PATH="$original_path" LC_ALL=C sort
}
unchanged_check() {
  local before output
  before=$(snapshot)
  output=$("$@" 2>&1) || { printf '%s\n' "$output" >&2; return 1; }
  assert test "$before" = "$(snapshot)"
  assert test "${output/secret-requirements-sentinel/}" = "$output"
  assert test ! -e "$test_root/operations"
}
unchanged_check check prerequisites
unchanged_check "$tools/bash" --noprofile --norc -x "$source_root/setup/check" prerequisites
mv "$XDG_CONFIG_HOME/dots/env" "$test_root/private-env"
ln -s "$test_root/private-env" "$XDG_CONFIG_HOME/dots/env"
unchanged_check check prerequisites
unchanged_check check readiness
(
  cd "$source_root/setup"
  unchanged_check "$tools/bash" --noprofile --norc check prerequisites
)
ln -s source/setup/check "$test_root/check"
unchanged_check "$test_root/check" prerequisites
output=$(check readiness 2>&1)
assert test "${output/Optional command unavailable: starship/}" != "$output"
unchanged_check expect_failure check candidate --install-root "$source_root"
unchanged_check expect_failure check prerequisites --save
mv "$tools/delta" "$test_root/delta"
delta() { exit 95; }
export -f delta
unchanged_check check prerequisites
unchanged_check expect_failure check readiness
mv "$test_root/delta" "$tools/delta"
unset -f delta
printf 'requires-python = ">=99.0"\n' > "$source_root/dotbot/pyproject.toml"
unchanged_check expect_failure check prerequisites
cp "$project_root/dotbot/pyproject.toml" "$source_root/dotbot/pyproject.toml"
mv "$tools/python3" "$test_root/python3"
unchanged_check expect_failure check prerequisites
mv "$test_root/python3" "$tools/python3"
mv "$tools/sed" "$test_root/sed"
printf '#!/usr/bin/env bash\necho BSD sed\n' > "$tools/sed"
PATH="$original_path" chmod +x "$tools/sed"
unchanged_check expect_failure check readiness
rm "$tools/sed"
mv "$test_root/sed" "$tools/sed"
# Missing or malformed runtime reports fail closed without exposing subprocess output.
cp "$tools/mise" "$test_root/mise-stub"
sed 's/"version":"18\.6"/"version":"18.5"/' "$test_root/mise-stub" > "$tools/mise"
unchanged_check expect_failure check readiness
for report in '[{"version":"22.0.0","installed":false}]' '[]' 'secret-requirements-sentinel'; do
  cat_script='#!/usr/bin/env bash
if [[ $3 == config ]]; then
  printf "node = \"22.0.0\"\n"
else'
  printf '%s\n' "$cat_script" > "$tools/mise"
  printf 'printf "%%s\\n" %q\nfi\n' "$report" >> "$tools/mise"
  unchanged_check expect_failure check readiness
done
cp "$test_root/mise-stub" "$tools/mise"

# Installed desktop tools do not imply a running graphical session.
for helper in desktop-session/launch desktop-session/stop desktop-session/finalize kanshi/restart quickshell/restart power/control; do
  mkdir -p "$source_root/bin/utilities/${helper%/*}"
  ln -s "$tools/systemctl" "$source_root/bin/utilities/$helper"
done
unchanged_check check readiness --select sway
mv "$tools/swaylock" "$test_root/swaylock"
unchanged_check expect_failure check readiness --select sway
mv "$test_root/swaylock" "$tools/swaylock"
export TEST_OS=void
unchanged_check check readiness --select sway
rm "$source_root/bin/utilities/kanshi/restart"
unchanged_check expect_failure check readiness --select sway
export TEST_OS=macos
mv "$tools/ghostty" "$test_root/ghostty"
mkdir -p "$HOME/Applications/Ghostty.app/Contents/MacOS" "$HOME/Applications/AeroSpace.app/Contents/MacOS"
ln -s "$tools/systemctl" "$HOME/Applications/Ghostty.app/Contents/MacOS/ghostty"
ln -s "$tools/systemctl" "$HOME/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
unchanged_check check readiness --select macos-desktop
export TEST_OS=wsl TEST_WINDOWS_WEZTERM=0
unchanged_check expect_failure check readiness --select wsl-integration
export TEST_WINDOWS_WEZTERM=1
unchanged_check check readiness --select wsl-integration

# Exercise actual mise only with synthetic installed state and nonmutating queries.
# No host readiness is performed. Its private/cache/trust paths are never supplied.
if [[ -n $real_mise ]]; then
  rm "$tools/mise"
  ln -s "$real_mise" "$tools/mise"
  export TEST_OS=arch
  current_declarations() {
    local output
    if output=$(check readiness 2>&1); then return 1; fi
    [[ $output == *'Missing or mismatched mise tool:'* || $output == *'Cannot query installed mise tool safely:'* ]] ||
      { printf '%s\n' "$output" >&2; return 1; }
  }
  unchanged_check current_declarations
  printf '[tools]\nnode = "22.0.0"\n' > "$source_root/config/mise/config.toml"
  mkdir -p "$XDG_DATA_HOME/mise/installs/node/22.0.0/bin"
  printf 'legacy fixture\n' > "$XDG_DATA_HOME/mise/installs/node/.mise.backend"
  unchanged_check check readiness
  printf '[tools]\nnode = "99.0.0"\n' > "$source_root/config/mise/config.toml"
  unchanged_check expect_failure check readiness
  printf '[tools]\nnodejs = "latest"\ngolang = "1.26.0"\n' > "$source_root/config/mise/config.toml"
  mkdir -p "$XDG_DATA_HOME/mise/installs/go/1.26.0/bin"
  unchanged_check check readiness
  # Both latest absence and incomplete installs remain blockers.
  mv "$XDG_DATA_HOME/mise/installs/node/22.0.0" "$test_root/node-install"
  unchanged_check expect_failure check readiness
  mv "$test_root/node-install" "$XDG_DATA_HOME/mise/installs/node/22.0.0"
  printf 'incomplete\n' > "$XDG_DATA_HOME/mise/installs/node/22.0.0/incomplete"
  unchanged_check expect_failure check readiness
  rm "$XDG_DATA_HOME/mise/installs/node/22.0.0/incomplete"
  for declaration in 'node = ["22.0.0"]' 'node = "22"' 'node = "22.0.0.1"' 'node = { version = "22.0.0" }'; do
    printf '[tools]\n%s\n' "$declaration" > "$source_root/config/mise/config.toml"
    unchanged_check expect_failure check readiness
  done
else
  printf 'Actual mise unavailable; only the query contract was fixture-tested.\n'
fi
printf 'requirements test passed\n'
