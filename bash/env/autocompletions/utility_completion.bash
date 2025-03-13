# What is key to understanding completion functions is that they get run
# every time you trigger a completion to occur.
_utility_completions() {
  local input subcommand subcommand_completion_path subfolders scripts
  input="${COMP_WORDS[COMP_CWORD]}"
  subcommand="${COMP_WORDS[1]}"
  subcommand_completion_path="$DOTFILES_PATH/bash/env/autocompletions/${subcommand}_${COMP_WORDS[2]}"

  # Define the root directory for the scripts
  local utilities_root="$DOTFILES_PATH/bin/utilities"

  # We autoload all bash/env/autocompletions/*.bash files, so don't add the .bash
  # extension to specific subcommands' completion files.
  if [ -f "$subcommand_completion_path" ]; then
    # NOTE: Because we source the scripts here rather than having them as
    # executables, any functions defined in these files will exist in the
    # global namespace. Remember to unset those functions after use!
    source "$subcommand_completion_path"
    return 0
  fi

  # If this is the first argument after "utility", we list the subfolders
  if [ "$COMP_CWORD" -eq 1 ]; then
    # List all subdirectories within ~/.bin/utilities
    subfolders=$(find -L "$utilities_root" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    mapfile -t COMPREPLY < <(compgen -W "$subfolders" -- "$input")
    return 0
  fi

  # If the first argument is already a valid subfolder, list scripts in that folder
  local folder_path="$utilities_root/${COMP_WORDS[1]}"
  if [ -d "$folder_path" ] && [ "$COMP_CWORD" -eq 2 ]; then
    # List all files within the specified subfolder
    scripts=$(find -L "$folder_path" -type f ! -name "_*" ! -name "*.sh" -exec basename {} \;)
    mapfile -t COMPREPLY < <(compgen -W "$scripts" -- "$input")
    return 0
  fi

  # If we have more than two arguments, just pass through
  COMPREPLY=()
  return 0
}

# Register the completion function for the `utility` command and its alias `u`.
complete -F _utility_completions u utility
