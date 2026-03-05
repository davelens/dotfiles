# Bash completion for the "dots" command

_dots_completions() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  # Define available commands
  opts="logs update install setup"

  # Provide command completions if we're on the first argument
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    return 0
  fi

  # Determine the subcommand (first argument after "dots")
  local subcmd="${COMP_WORDS[1]}"

  case "$subcmd" in
  logs)
    COMPREPLY=($(compgen -f "$DOTFILES_STATE_HOME/dots.log"))
    ;;
  update)
    COMPREPLY=($(compgen -W "--dotbot" -- "$cur"))
    ;;
  install)
    COMPREPLY=()
    ;;
  setup)
    if [[ "$prev" == "--dotsys" ]]; then
      COMPREPLY=($(compgen -W "arch macos wsl" -- "$cur"))
    else
      # Collect already-used flags to avoid suggesting them again
      local used_flags=""
      for word in "${COMP_WORDS[@]}"; do
        case "$word" in
        --dotsys | --dotshell | --dotvim) used_flags+="$word " ;;
        esac
      done

      local available=""
      for flag in --dotsys --dotshell --dotvim; do
        [[ "$used_flags" != *"$flag"* ]] && available+="$flag "
      done

      COMPREPLY=($(compgen -W "$available" -- "$cur"))
    fi
    ;;
  *)
    COMPREPLY=()
    ;;
  esac
}

# Attach the completion function to "dots"
complete -F _dots_completions dots
