#!/usr/bin/env bash
# Capabilities, not package lists. Missing optional tools only warn here.

dots_require_command() {
  type -P -- "$1" >/dev/null && return 0
  dots_error "Required command missing: $1; prepare it with dotsys."
}

dots_python() {
  local python metadata="$DOTS_SOURCE_ROOT/dotbot/pyproject.toml"
  python=$(type -P python3 || type -P python) || { dots_error 'Dotbot requires Python; prepare it with dotsys.'; return 1; }
  # Read the selected submodule's floor without importing Dotbot or writing pyc.
  "$python" -I -B - "$metadata" <<'PY' >/dev/null 2>&1
import re, sys
with open(sys.argv[1], encoding="utf-8") as f:
    match = re.search(r'^requires-python\s*=\s*">=([0-9]+(?:\.[0-9]+)*)"\s*$', f.read(), re.M)
if not match:
    sys.exit(1)
floor = tuple(map(int, match.group(1).split('.')))
sys.exit(0 if sys.version_info >= floor else 1)
PY
  if [[ $? != 0 ]]; then
    dots_error 'Python does not satisfy selected Dotbot metadata (or metadata is unavailable); prepare a compatible maintained Python.'
    return 1
  fi
  DOTS_PYTHON=$python
  export DOTS_PYTHON
}

dots_prerequisites() {
  local tool failed=0
  for tool in bash git readlink dirname env; do
    dots_require_command "$tool" || failed=1
  done
  if ! BASH_ENV= ENV= "$(type -P bash)" --noprofile --norc -c '((BASH_VERSINFO[0] >= 5))' </dev/null >/dev/null 2>&1; then
    dots_error 'The Bash executable on PATH must be >=5; prepare it with dotsys.'
    failed=1
  fi
  dots_python || failed=1
  [[ -f $DOTS_SOURCE_ROOT/dotbot/bin/dotbot && -f $DOTS_SOURCE_ROOT/dotbot/src/dotbot/cli.py ]] ||
    { dots_error 'Selected Dotbot source is missing; initialize pinned submodules explicitly.'; failed=1; }
  ((failed == 0))
}

dots_require_gnu() {
  local executable output
  executable=$(type -P -- "$1") || { dots_require_command "$1"; return 1; }
  output=$("$executable" --version 2>/dev/null) && [[ $output == *GNU* ]] ||
    dots_error "Required GNU executable missing or incompatible: $1; put its gnubin directory on PATH."
}

dots_native_app() {
  local command=$1 bundle=$2 executable=$3
  type -P -- "$command" >/dev/null && return 0
  [[ $DOTS_OS == macos ]] || return 1
  [[ -x /Applications/$bundle.app/Contents/MacOS/$executable ||
     -x $HOME/Applications/$bundle.app/Contents/MacOS/$executable ]]
}

dots_windows_wezterm() {
  local powershell
  powershell=$(type -P powershell.exe) || return 1
  # Fixed host query only: no user path interpolated into PowerShell code.
  "$powershell" -NoLogo -NoProfile -NonInteractive -Command \
    'if (Get-Command wezterm.exe -CommandType Application -ErrorAction SilentlyContinue) { exit 0 }; if ($env:ProgramFiles -and (Test-Path -LiteralPath (Join-Path $env:ProgramFiles "WezTerm\wezterm.exe") -PathType Leaf)) { exit 0 }; exit 1' \
    </dev/null >/dev/null 2>&1
}

dots_mise_query() {
  # Verified with mise v2026.8.6. Shared installs are documented read-only and
  # avoid primary-root metadata migration. /dev/null children cannot be written.
  # Config discovery, plugins, env, hooks, network, trust and file logs stay off.
  env -i PATH="$PATH" HOME="$HOME" \
    XDG_CONFIG_HOME="$XDG_CONFIG_HOME" XDG_DATA_HOME="$XDG_DATA_HOME" \
    XDG_CACHE_HOME="$XDG_CACHE_HOME" XDG_STATE_HOME="$XDG_STATE_HOME" \
    XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" \
    MISE_CONFIG_DIR=/dev/null MISE_SYSTEM_CONFIG_FILE=/dev/null \
    MISE_GLOBAL_CONFIG_FILE=/dev/null MISE_NO_CONFIG=1 \
    MISE_DATA_DIR=/dev/null MISE_CACHE_DIR=/dev/null MISE_STATE_DIR=/dev/null \
    MISE_TMP_DIR=/dev/null MISE_SYSTEM_DATA_DIR=/dev/null \
    MISE_SHARED_INSTALL_DIRS="${MISE_INSTALLS_DIR:-$MISE_DATA_DIR/installs}" \
    MISE_SAFE=1 MISE_NO_ENV=1 MISE_NO_HOOKS=1 MISE_OFFLINE=1 \
    MISE_AUTO_INSTALL=0 MISE_AUTO_UPDATE=0 MISE_CACHE_PRUNE_AGE=0s \
    MISE_LOG_FILE=/dev/null MISE_LOG_LEVEL=error MISE_YES=0 \
    "$DOTS_MISE" -C "$DOTS_SOURCE_ROOT/config/mise" "$@" </dev/null 2>/dev/null
}

dots_mise_readiness() {
  local declarations requests report tool version failed=0
  local installs="${MISE_INSTALLS_DIR:-$MISE_DATA_DIR/installs}"
  [[ $installs == /* && $installs != *:* ]] ||
    { dots_error 'Mise installs must be an absolute path without the shared-directory colon separator.'; return 1; }
  DOTS_MISE=$(type -P mise) || return 1
  if ! declarations=$(dots_mise_query config get tools --file "$DOTS_SOURCE_ROOT/config/mise/config.toml"); then
    dots_error 'Cannot read source mise declarations safely; prepare a compatible mise with dotsys.'
    return 1
  fi
  # ponytail: Only the current simple pins/latest contract, not a TOML parser.
  # Mise parses TOML and emits canonical strings; new selectors fail closed.
  if ! requests=$("$DOTS_PYTHON" -I -B -c '
import re, sys
lines = [line for line in sys.stdin.read().splitlines() if line.strip()]
if not lines:
    sys.exit(1)
for line in lines:
    m = re.fullmatch(r"([a-zA-Z0-9_-]+) = \"(latest|[0-9]+(?:\.[0-9]+){2})\"", line)
    if not m:
        sys.exit(1)
    print(m[1] + "\t" + m[2])
' <<< "$declarations" 2>/dev/null); then
    dots_error 'Unsupported mise declarations: checks currently accept simple string x.y.z pins or latest only.'
    return 1
  fi
  while IFS=$'\t' read -r tool version; do
    # Per-tool queries let mise resolve aliases (e.g. golang/nodejs) itself.
    if ! report=$(dots_mise_query ls --installed --offline --json "$tool"); then
      dots_error "Cannot query installed mise tool safely: $tool; prepare it with dotsys."
      failed=1
      continue
    fi
    # Latest means a locally installed version, not remote freshness. Mise's
    # installed flag excludes incomplete installs and broken/runtime symlinks.
    if ! "$DOTS_PYTHON" -I -B -c '
import json, sys
try:
    data = json.load(sys.stdin)
    assert isinstance(data, list)
    assert any(v["installed"] is True and isinstance(v["version"], str) and v["version"] and
               (sys.argv[1] == "latest" or v["version"] == sys.argv[1]) for v in data)
except (ValueError, KeyError, TypeError, AssertionError):
    sys.exit(1)
' "$version" <<< "$report" >/dev/null 2>&1; then
      dots_error "Missing or mismatched mise tool: $tool; prepare this source config/mise/config.toml with dotsys."
      failed=1
    fi
  done <<< "$requests"
  ((failed == 0))
}

dots_readiness() {
  dots_prerequisites || return 1
  local failed=0 tool helper
  for tool in tmux mise dvim nvim delta; do
    dots_require_command "$tool" || failed=1
  done
  for tool in realpath cp mv rm mkdir ln readlink stat sed; do
    dots_require_gnu "$tool" || failed=1
  done
  dots_mise_readiness || failed=1
  if dots_selected sway; then
    for tool in ghostty foot sway swaymsg swaynag rofi rofi-start autotiling-rs \
      swayidle swaylock wl-copy wl-paste wl-clip-persist cliphist kanshi qs dshell; do
      dots_require_command "$tool" || failed=1
    done
    case $DOTS_OS in
      arch) for tool in systemctl loginctl uwsm; do dots_require_command "$tool" || failed=1; done ;;
      void) for tool in sv loginctl turnstile-update-runit-env dbus-update-activation-environment; do dots_require_command "$tool" || failed=1; done ;;
    esac
    for helper in desktop-session/launch desktop-session/stop desktop-session/finalize kanshi/restart quickshell/restart power/control; do
      [[ -x $DOTS_INSTALL_ROOT/bin/utilities/$helper ]] ||
        { dots_error "Required dotsys helper missing: $helper; register helpers explicitly."; failed=1; }
    done
  fi
  if dots_selected macos-desktop; then
    dots_native_app ghostty Ghostty ghostty || { dots_error 'Required native app missing: Ghostty.'; failed=1; }
    dots_native_app aerospace AeroSpace AeroSpace || { dots_error 'Required native app missing: AeroSpace.'; failed=1; }
    for tool in borders sketchybar; do dots_require_command "$tool" || failed=1; done
  fi
  if dots_selected wsl-integration; then
    for tool in powershell.exe wsl.exe wslpath python3 windows-open windows-clipboard; do dots_require_command "$tool" || failed=1; done
    dots_windows_wezterm || { dots_error 'Required Windows-host application missing: WezTerm.'; failed=1; }
  fi
  for tool in starship fzf keychain; do
    type -P -- "$tool" >/dev/null || printf 'dots: Optional command unavailable: %s\n' "$tool" >&2
  done
  if dots_selected sway; then
    for tool in grim slurp brightnessctl pactl; do
      type -P -- "$tool" >/dev/null || printf 'dots: Optional command unavailable: %s\n' "$tool" >&2
    done
  fi
  if dots_selected macos-desktop; then
    dots_native_app firefox Firefox firefox || printf 'dots: Optional native app unavailable: Firefox\n' >&2
    dots_native_app discord Discord Discord || printf 'dots: Optional native app unavailable: Discord\n' >&2
  fi
  if [[ $DOTS_OS == wsl ]]; then
    if [[ -n $DOTS_WEZTERM_DESTINATION ]]; then
      "$DOTS_PYTHON" -I -B "$DOTS_SOURCE_ROOT/setup/configuration.py" check || failed=1
    else
      printf 'dots: Windows WezTerm export skipped: no destination supplied.\n' >&2
    fi
  fi
  ((failed == 0))
}
