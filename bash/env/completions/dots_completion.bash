# Bash completion for the "dots" command

_dots_completions() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  # Define available commands
  opts="logs update install"

  # Provide command completions if we're on the first argument
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    return 0
  fi

  # Handle specific subcommands (e.g., file paths for 'logs')
  case "$prev" in
  logs)
    # Suggest log file path as completion
    COMPREPLY=($(compgen -f "$DOTFILES_STATE_HOME/dots.log"))
    ;;
  update)
    COMPREPLY=($(compgen -W "--dotbot" -- "$cur"))
    ;;
  install)
    # No additional arguments for "install"
    COMPREPLY=()
    ;;
  *)
    COMPREPLY=()
    ;;
  esac
}

# Attach the completion function to "dots"
complete -F _dots_completions dots
