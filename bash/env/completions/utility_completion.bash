# Cache the current OS (only runs once when this file is sourced)
_UTILITY_CURRENT_OS="$("$XDG_BIN_HOME/os")"

# Filter out OS-specific folders that don't match the current OS
_utility_filter_by_os() {
  local folder os_folders="macos linux wsl freebsd"
  while IFS= read -r folder; do
    if [[ " $os_folders " == *" $folder "* ]]; then
      [[ "$folder" == "$_UTILITY_CURRENT_OS" ]] && echo "$folder"
    else
      echo "$folder"
    fi
  done
}

# Completion function for the `utility` command.
# Note: This runs every time you trigger a completion.
_utility_completions() {
  local input="${COMP_WORDS[COMP_CWORD]}"
  local subcommand="${COMP_WORDS[1]}"
  local utilities_root="$DOTFILES_REPO_HOME/bin/utilities"
  local subcommand_completion_path="$DOTFILES_REPO_HOME/bash/env/completions/${subcommand}_${COMP_WORDS[2]}"

  # We autoload all bash/env/completions/*.bash files, so don't add the .bash
  # extension to specific subcommands' completion files.
  if [[ -f "$subcommand_completion_path" ]]; then
    # NOTE: Because we source the scripts here rather than having them as
    # executables, any functions defined in these files will exist in the
    # global namespace. Remember to unset those functions after use!
    source "$subcommand_completion_path"
    return 0
  fi

  # First argument: list utility categories (subfolders), filtered by OS
  if [[ $COMP_CWORD -eq 1 ]]; then
    local subfolders
    subfolders=$(find -L "$utilities_root" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | _utility_filter_by_os)
    mapfile -t COMPREPLY < <(compgen -W "$subfolders" -- "$input")
    return 0
  fi

  # Second argument: list commands within the selected category
  local folder_path="$utilities_root/$subcommand"
  if [[ -d "$folder_path" ]] && [[ $COMP_CWORD -eq 2 ]]; then
    local scripts
    scripts=$(find -L "$folder_path" -type f ! -name "_*" ! -name "*.sh" -exec basename {} \;)
    mapfile -t COMPREPLY < <(compgen -W "$scripts" -- "$input")
    return 0
  fi

  COMPREPLY=()
}

complete -F _utility_completions u utility
