# Completion for float command - suggests executables from PATH
_float_completions() {
  if [ "${#COMP_WORDS[@]}" -eq 2 ]; then
    COMPREPLY=($(compgen -c -- "${COMP_WORDS[1]}"))
  else
    # For subsequent arguments, use file completion
    COMPREPLY=($(compgen -f -- "${COMP_WORDS[COMP_CWORD]}"))
  fi
}

complete -F _float_completions float
