# Bash completion for the "rofi-start" command

_rofi_start_completions() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  # Define available options
  opts="--powermenu --dmenu --launcher --theme --mode"

  case "$prev" in
  --launcher)
    # Suggest launcher types (type-1 through type-6 are common)
    COMPREPLY=($(compgen -W "type-1 type-2 type-3 type-4 type-5 type-6" -- "$cur"))
    return 0
    ;;
  --theme)
    # Suggest theme styles (style-1 through style-15)
    COMPREPLY=($(compgen -W "style-1 style-2 style-3 style-4 style-5 style-6 style-7 style-8 style-9 style-10 style-11 style-12 style-13 style-14 style-15" -- "$cur"))
    return 0
    ;;
  --mode)
    # Suggest common rofi modes
    COMPREPLY=($(compgen -W "drun run window ssh filebrowser" -- "$cur"))
    return 0
    ;;
  --powermenu | --dmenu)
    # These are flags, continue with other options
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    return 0
    ;;
  esac

  # Default: suggest all options
  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

# Attach the completion function to "rofi-start"
complete -o default -F _rofi_start_completions rofi-start
