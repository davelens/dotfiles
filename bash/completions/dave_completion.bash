#!/bin/bash

_dave_completions() {
  local cur prev subfolders scripts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Define the root directory for the scripts
    local dave_root="./bin/dave-scripts"

    # If this is the first argument after "dave", we list the subfolders
    if [[ $COMP_CWORD -eq 1 ]]; then
      # List all subdirectories within ~/.bin/dave-scripts
      subfolders=$(find "$dave_root" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
      COMPREPLY=( $(compgen -W "$subfolders" -- "$cur") )
      return 0
    fi

    # If the first argument is already a valid subfolder, list scripts in that folder
    local folder_path="$dave_root/${COMP_WORDS[1]}"
    if [[ -d "$folder_path" && $COMP_CWORD -eq 2 ]]; then
      # List all files within the specified subfolder
      scripts=$(find "$folder_path" -type f -exec basename {} \;)
      COMPREPLY=( $(compgen -W "$scripts" -- "$cur") )
      return 0
    fi

    # If we have more than two arguments, just pass through
    COMPREPLY=()
    return 0
  }

# Register the completion function for the "dave" command
complete -F _dave_completions dave
