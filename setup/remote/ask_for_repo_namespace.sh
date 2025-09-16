ask_for_repo_namespace() {
  local repo_home contents
  repo_home="$HOME/Repositories/davelens/dotfiles"
  contents="By default I keep my dotfiles in \Z4${repo_home/$HOME/\~}\Zn.\n"

  if [ -n "$1" ]; then
    contents="\n$1\n"
  elif [ -n "$(ls -A "$repo_home")" ]; then
    contents+="\nIt looks like that directory's not empty though. 🤔\n"
  fi

  contents+="\nSpecify where you want to store the dotfiles:"
  DOTFILES_REPO_HOME=$(dialog --colors --inputbox "$contents" 12 72 "$repo_home" 2>&1 >/dev/tty)

  response=$?
  if [ $response -eq 0 ]; then
    # Use $DOTFILES_REPO_HOME as needed
    :
  else
    echo "Cancelled by user."
    exit 1
  fi

  DOTFILES_REPO_HOME="${DOTFILES_REPO_HOME:-$repo_home}"
  DOTFILES_REPO_HOME="${DOTFILES_REPO_HOME%/}" # No trailing slash

  if [ -f "$DOTFILES_REPO_HOME" ]; then
    ask_for_repo_namespace "The path you provided is a file. Please provide a directory." && return
  fi
}

ask_for_repo_namespace
[ ! -d "$DOTFILES_REPO_HOME" ] && mkdir -p "$DOTFILES_REPO_HOME"
