install_dotfiles() {
  # TODO: Change the `dots` command to git init DOTFILES_REPO_HOME, if necessary.

  prompt="Do you want to proceed with installing the dotfiles? "
  read -n1 -r -p "$prompt" input

  case $input in
  [Yy])
    echo
    "$DOTFILES_REPO_HOME/setup/install"
    ;;
  [Nn]) interrupt_handler ;;
  *)
    reset_prompt
    install_dotfiles && return
    ;;
  esac
  return
}

install_dotfiles
