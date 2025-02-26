_utility_completions() {
  local cur prev subcommand subcommand_completion_path subfolders scripts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  subcommand="${COMP_WORDS[1]}"
  subcommand_completion_path="$DOTFILES_PATH/bash/completions/${subcommand}_${COMP_WORDS[2]}.bash"

  # Define the root directory for the scripts
  local utilities_root="${DOTFILES_PATH}/bin/utilities"

  if [[ -f $subcommand_completion_path ]]; then
    source $subcommand_completion_path
    return 0
  fi

  # If this is the first argument after "utility", we list the subfolders
  if [[ $COMP_CWORD -eq 1 ]]; then
    # List all subdirectories within ~/.bin/utilities
    subfolders=$(find -L "$utilities_root" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    COMPREPLY=( $(compgen -W "$subfolders" -- "$cur") )
    return 0
  fi

  # If the first argument is already a valid subfolder, list scripts in that folder
  local folder_path="$utilities_root/${COMP_WORDS[1]}"
  if [[ -d "$folder_path" && $COMP_CWORD -eq 2 ]]; then
    # List all files within the specified subfolder
    scripts=$(find -L "$folder_path" -type f ! -name "_*" ! -name "*.sh" -exec basename {} \;)
    COMPREPLY=( $(compgen -W "$scripts" -- "$cur") )
    return 0
  fi

  # If we have more than two arguments, just pass through
  COMPREPLY=()
  return 0
}

# Register the completion function for the `utility` command and its alias `u`.
complete -F _utility_completions u utility
