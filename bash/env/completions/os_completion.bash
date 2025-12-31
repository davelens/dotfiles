# Bash completion for the "os" command

_os_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=($(compgen -W "-p --platform -h --help" -- "$cur"))
  fi
}

complete -F _os_completions os
