# Completion is descriptive only; it never probes/provisions tools.
_dots_completions() {
  local cur=${COMP_WORDS[COMP_CWORD]} prev=${COMP_WORDS[COMP_CWORD-1]} options=
  COMPREPLY=()
  if ((COMP_CWORD == 1)); then
    options='logs update install check setup -h --help'
  else
    case $prev in
      --dotsys|--platform) options='arch void macos wsl' ;;
      --select) options='sway macos-desktop wsl-integration karabiner alfred' ;;
      --user|--wezterm-destination) return 0 ;;
      --adopt|--replace|--helper-adopt|--helper-replace|--install-root|--dotfiles-root|--dotvim-root|--dotshell-root|--home|--xdg-*-home)
        mapfile -t COMPREPLY < <(compgen -f -- "$cur"); return 0 ;;
      *)
        case ${COMP_WORDS[1]} in
          install) options='--check --select --wezterm-destination --save --adopt --replace' ;;
          check) options='prerequisites readiness --select --wezterm-destination' ;;
          setup)
            options='--arch --void --dotsys --dotfiles --dotvim --dotshell --platform --full-machine --dotfiles-root --dotvim-root --dotshell-root --home --user --xdg-config-home --xdg-data-home --xdg-state-home --xdg-cache-home --xdg-bin-home --select --wezterm-destination --save --adopt --replace --helper-adopt --helper-replace -h --help' ;;
        esac ;;
    esac
  fi
  mapfile -t COMPREPLY < <(compgen -W "$options" -- "$cur")
}
complete -F _dots_completions dots
