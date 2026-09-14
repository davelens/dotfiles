source "${BASH_SOURCE[0]%/*}/../../utility-context.sh"

_utility_completions() {
  local input="${COMP_WORDS[COMP_CWORD]}" category="${COMP_WORDS[1]:-}"
  local command="${COMP_WORDS[2]:-}" candidate completion
  COMPREPLY=()
  if (( COMP_CWORD == 1 )); then
    while IFS= read -r candidate; do
      [[ $candidate == "$input"* ]] && COMPREPLY+=("$candidate")
    done < <(utility_categories)
  elif (( COMP_CWORD == 2 )); then
    while IFS= read -r candidate; do
      [[ $candidate == "$input"* ]] && COMPREPLY+=("$candidate")
    done < <(utility_commands "$category")
  elif utility_allowed "$category" "$command" &&
    [[ -f $DOTFILES_REPO_HOME/bin/utilities/$category/$command && -x $DOTFILES_REPO_HOME/bin/utilities/$category/$command ]]; then
    completion="$DOTFILES_REPO_HOME/bash/env/completions/${category}_${command}"
    # Existing command-specific completions remain lazy and category-gated.
    [[ ! -f $completion ]] || source "$completion"
  fi
  return 0
}

complete -F _utility_completions u utility
