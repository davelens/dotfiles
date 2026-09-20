# Bash completion for the "rofi-start" command

_rofi_start_completions() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  opts="--dmenu --theme --mode"

  case "$prev" in
  --theme)
    COMPREPLY=($(compgen -W "launcher dmenu applet" -- "$cur"))
    return 0
    ;;
  --mode)
    COMPREPLY=($(compgen -W "drun run window ssh filebrowser calc" -- "$cur"))
    return 0
    ;;
  esac

  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

complete -o default -F _rofi_start_completions rofi-start
