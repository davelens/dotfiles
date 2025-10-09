install_dotfiles() {
  # TODO: Change the `dots` command to git init DOTFILES_REPO_HOME, if necessary.

  prompt="Do you want to proceed with installing the dotfiles? [y/n] "
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

echo
echo "3. $(underline "SYMLINK ALL THE THINGS")"
echo

save_cursor

install_dotfiles

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  reset_prompt
  echo "✓ $(fgreen "Dotfiles installed and symlinked")"
else
  fail "x $(fred "Something went wrong during step 3.")"
fi
