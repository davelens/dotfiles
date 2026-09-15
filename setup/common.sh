#!/usr/bin/env bash
# Direct bootstrap only: no startup hooks, directory creation, or provisioning.

dots_error() { printf 'dots: %s\n' "$1" >&2; return 1; }

dots_entry_root() {
  local entry=$1 directory count=0
  if [[ $entry != */* ]]; then
    if [[ -f $entry ]]; then entry="./$entry"; else entry=$(type -P -- "$entry") || return 1; fi
  fi
  while :; do
    directory=$(cd -P -- "${entry%/*}" && pwd) || return 1
    entry="$directory/${entry##*/}"
    [[ -L $entry ]] || break
    ((count+=1))
    ((count <= 40)) || return 1
    entry=$(readlink -- "$entry") || return 1
    [[ $entry == /* ]] || entry="$directory/$entry"
  done
  cd -P -- "$directory/.." && pwd
}

dots_selected() { [[ ,$DOTS_SELECTION, == *",$1,"* ]]; }

dots_validate_choices() {
  local addition seen=, value=$DOTS_SELECTION
  [[ -z $value || ( $value != ,* && $value != *, && $value != *,,* ) ]] ||
    { dots_error 'Invalid comma-separated selection.'; return 1; }
  local -a additions=()
  IFS=, read -r -a additions <<< "$value"
  for addition in "${additions[@]}"; do
    case "$addition:$DOTS_OS" in
      sway:arch|sway:void|macos-desktop:macos|karabiner:macos|alfred:macos|wsl-integration:wsl) ;;
      *) dots_error 'Unknown or inapplicable selection; use sway, macos-desktop, wsl-integration, karabiner, alfred on their native targets.'; return 1 ;;
    esac
    [[ $seen != *",$addition,"* ]] || { dots_error 'Duplicate selection.'; return 1; }
    seen+="$addition,"
  done
  if [[ -n $DOTS_WEZTERM_DESTINATION ]]; then
    [[ $DOTS_OS == wsl ]] || { dots_error 'WezTerm host export requires WSL.'; return 1; }
    # Full conversion/access/ownership checks belong to the Windows artifact planner.
    [[ $DOTS_WEZTERM_DESTINATION == /* || $DOTS_WEZTERM_DESTINATION =~ ^[A-Za-z]:[\\/] ]] ||
      { dots_error 'WezTerm destination must be an absolute host path.'; return 1; }
    [[ $DOTS_WEZTERM_DESTINATION != *$'\n'* && $DOTS_WEZTERM_DESTINATION != *$'\r'* ]] ||
      { dots_error 'Invalid WezTerm destination.'; return 1; }
  fi
}

# Usage: dots_bootstrap install|prerequisites|readiness|candidate ENTRY [choices]
# Exports source/install roots separately. Only the installer may act on DOTS_SAVE.
dots_bootstrap() {
  set +x
  ((BASH_VERSINFO[0] >= 5)) || { dots_error 'Bash >=5 is required; prepare it with dotsys.'; return 1; }
  local mode=$1 entry=$2 root env_file input_selection input_destination install_root_supplied=0
  local has_selection=${DOTS_INSTALL_SELECTION+x} has_destination=${DOTS_INSTALL_WEZTERM_DESTINATION+x}
  input_selection=${DOTS_INSTALL_SELECTION-}
  input_destination=${DOTS_INSTALL_WEZTERM_DESTINATION-}
  shift 2
  root=$(dots_entry_root "$entry") || { dots_error 'Cannot locate source checkout.'; return 1; }
  [[ ${HOME:-} == /* ]] || { dots_error 'HOME must be an absolute path.'; return 1; }
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  [[ $XDG_CONFIG_HOME == /* ]] || { dots_error 'XDG_CONFIG_HOME must be absolute.'; return 1; }
  env_file="$XDG_CONFIG_HOME/dots/env"
  unset DOTS_SELECTION DOTS_WEZTERM_DESTINATION
  if [[ -e $env_file || -L $env_file ]]; then
    [[ -f $env_file && -r $env_file ]] || { dots_error 'Trusted dots/env is not a readable file.'; return 1; }
    # Trusted user Bash may have its own effects. Never expose its output/traces.
    if ! { source "$env_file"; } >/dev/null 2>&1; then
      set +x
      dots_error 'Loading trusted dots/env failed.'; return 1
    fi
    set +x
  fi
  source "$root/bash/env/xdg.sh"
  local name
  for name in HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME XDG_BIN_HOME; do
    [[ ${!name} == /* ]] || { dots_error "$name must be absolute."; return 1; }
  done
  [[ -z ${XDG_RUNTIME_DIR:-} || $XDG_RUNTIME_DIR == /* ]] ||
    { dots_error 'XDG_RUNTIME_DIR must be absolute when supplied.'; return 1; }
  DOTS_SOURCE_ROOT=$root
  DOTS_INSTALL_ROOT=$root
  DOTFILES_REPO_HOME=$root
  DOTS_ENV_FILE=$env_file
  DOTS_SELECTION=${DOTS_SELECTION-}
  DOTS_WEZTERM_DESTINATION=${DOTS_WEZTERM_DESTINATION-}
  [[ ! $has_selection ]] || DOTS_SELECTION=$input_selection
  [[ ! $has_destination ]] || DOTS_WEZTERM_DESTINATION=$input_destination
  DOTS_SAVE=0
  while (($#)); do
    case $1 in
      --select|--wezterm-destination|--install-root)
        (($# >= 2)) || { dots_error 'Option requires a value (an explicit empty value is allowed for choices).'; return 1; }
        case $1 in
          --select) DOTS_SELECTION=$2 ;;
          --wezterm-destination) DOTS_WEZTERM_DESTINATION=$2 ;;
          --install-root)
            [[ $mode == candidate && $2 == /* && -d $2 ]] ||
              { dots_error '--install-root requires an existing absolute directory and candidate mode.'; return 1; }
            DOTS_INSTALL_ROOT=$(cd -P -- "$2" && pwd) || return 1
            install_root_supplied=1 ;;
        esac
        shift 2 ;;
      --save)
        [[ $mode == install ]] || { dots_error 'Only install accepts --save; checks are read-only.'; return 1; }
        DOTS_SAVE=1; shift ;;
      *) dots_error 'Unknown bootstrap option.'; return 1 ;;
    esac
  done
  [[ $mode != candidate || $install_root_supplied == 1 ]] ||
    { dots_error 'Candidate checks require --install-root.'; return 1; }
  source "$root/bash/env/brew.sh"
  source "$root/bash/env/path.sh"
  DOTS_OS=$(BASH_ENV= ENV= "$(type -P bash)" --noprofile --norc "$root/bin/autoload/os") ||
    { dots_error 'Cannot detect platform.'; return 1; }
  dots_validate_choices || return 1
  export DOTS_SOURCE_ROOT DOTS_INSTALL_ROOT DOTFILES_REPO_HOME DOTS_ENV_FILE
  export DOTS_SELECTION DOTS_WEZTERM_DESTINATION DOTS_OS DOTS_SAVE
}
