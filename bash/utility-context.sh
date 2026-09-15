# Shared discovery policy. Dependencies and live sessions never affect lists.
utility_name_valid() { [[ -n $1 && $1 != . && $1 != .. && $1 != */* ]]; }

utility_category_allowed() {
  utility_name_valid "$1" || return 1
  case $1 in
    arch) [[ $DOTS_OS == arch || $DOTS_OS == wsl ]] ;;
    macos|void|debian|nixos|fedora|wsl|freebsd|windows) [[ $1 == "$DOTS_OS" ]] ;;
    linux) [[ $DOTS_OS == arch || $DOTS_OS == void || $DOTS_OS == wsl || $DOTS_OS == linux || $DOTS_OS == debian || $DOTS_OS == nixos || $DOTS_OS == fedora ]] ;;
    kanshi|quickshell) dots_selected sway ;;
    desktop-session) dots_selected sway || dots_selected macos-desktop ;;
    *) return 0 ;;
  esac
}

utility_allowed() {
  utility_category_allowed "$1" && utility_name_valid "$2" || return 1
  [[ $2 != _* && $2 != *.sh ]] || return 1
  case "$1/$2" in
    misc/clean-my-mac) [[ $DOTS_OS == macos ]] ;;
    misc/screencast) dots_selected sway ;;
    misc/screenshot|misc/screenshot-test) dots_selected sway || dots_selected macos-desktop ;;
    *) return 0 ;;
  esac
}

utility_commands() {
  local path name
  utility_category_allowed "$1" || return 0
  for path in "$DOTFILES_REPO_HOME/bin/utilities/$1"/*; do
    [[ -f $path && -x $path ]] || continue
    name=${path##*/}
    utility_allowed "$1" "$name" && printf '%s\n' "$name"
  done
  return 0
}

utility_categories() {
  local path name
  for path in "$DOTFILES_REPO_HOME/bin/utilities"/*; do
    [[ -d $path ]] || continue
    name=${path##*/}
    utility_category_allowed "$name" && printf '%s\n' "$name"
  done
  return 0
}

utility_list() {
  local category command
  while IFS= read -r category; do
    while IFS= read -r command; do
      printf '  %s %s\n' "$category" "$command"
    done < <(utility_commands "$category")
  done < <(utility_categories)
}

# Existing desktop conveniences need an applicable live session only on use.
# Dotsys helpers diagnose their own providers and arguments.
utility_require() {
  local command
  local -a commands=()
  case "$1/$2" in
    misc/screenshot|misc/screenshot-test|misc/screencast)
      [[ -z ${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-} ]] || {
        printf 'utility: %s requires a local graphical session.\n' "$2" >&2; return 1;
      }
      if [[ $DOTS_OS != macos && ( -z ${SWAYSOCK:-} || -z ${WAYLAND_DISPLAY:-} ) ]]; then
        printf 'utility: %s requires a running selected Sway session.\n' "$2" >&2
        return 1
      fi
      case $2 in
        screenshot|screenshot-test) commands=(flameshot) ;;
        # The script chooses its recorder; BASH_ENV diagnoses a missing one.
        screencast) commands=(pactl lspci) ;;
      esac ;;
  esac
  for command in "${commands[@]}"; do
    type -P "$command" >/dev/null || {
      printf 'utility: Missing %s for %s %s; prepare it with dotsys.\n' "$command" "$1" "$2" >&2
      return 1
    }
  done
}
