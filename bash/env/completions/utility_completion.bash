# Cache the current distro and platform when this file is sourced.
_UTILITY_CURRENT_DISTRO="$("$XDG_BIN_HOME/os")"
_UTILITY_CURRENT_PLATFORM="$("$XDG_BIN_HOME/os" --platform)"

# Keep category gating consistent with bin/utility.
_utility_filter_by_os() {
  local folder
  while IFS= read -r folder; do
    case "$folder" in
      macos | linux | freebsd | windows)
        [[ "$folder" == "$_UTILITY_CURRENT_PLATFORM" ]] || continue
        ;;
      arch | debian | nixos | fedora | wsl)
        [[ "$folder" == "$_UTILITY_CURRENT_DISTRO" ]] || continue
        ;;
    esac
    echo "$folder"
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
    scripts=$(find -L "$folder_path" -maxdepth 1 -type f ! -name "_*" ! -name "*.sh" -exec test -x {} \; -exec basename {} \;)
    mapfile -t COMPREPLY < <(compgen -W "$scripts" -- "$input")
    return 0
  fi

  COMPREPLY=()
}

complete -F _utility_completions u utility
