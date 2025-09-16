ask_for_repo_namespace() {
  local repo_home
  repo_home="$HOME/Repositories/davelens/dotfiles"

  echo
  echo "By default I keep my dotfiles in $(blue "${repo_home/$HOME/\~}")."

  if [ -n "$(ls -A "$repo_home")" ]; then
    echo "It looks like that directory's not empty though. 🤔"
  fi

  echo
  echo -e "Specify where you want to store the dotfiles: \n"

  if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    read -r -e -p "$HOME/" DOTFILES_REPO_HOME
    DOTFILES_REPO_HOME="${repo_home/\~/$HOME}"
  else
    read -r -e -i "$repo_home" -p "" DOTFILES_REPO_HOME
  fi

  if [ -n "$(ls -A "$DOTFILES_REPO_HOME/")" ]; then
    reset_prompt
    # ask_for_repo_namespace
    return
  fi

  DOTFILES_REPO_HOME="${DOTFILES_REPO_HOME:-$repo_home}"
  DOTFILES_REPO_HOME="${DOTFILES_REPO_HOME%/}"

  if [ -f "$DOTFILES_REPO_HOME" ]; then
    echo "The path you provided is a file. Please provide a directory."
    ask_for_repo_namespace && return
  fi

  [ ! -d "$DOTFILES_REPO_HOME" ] && mkdir -p "$DOTFILES_REPO_HOME"
  echo
}

ask_for_repo_namespace
reset_prompt
green "✓ Primed $(repo_home)"
save_cursor
