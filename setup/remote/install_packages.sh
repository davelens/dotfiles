prompt_for_packages() {
  # TODO: Change the `dots` command to git init DOTFILES_REPO_HOME, if necessary.

  prompt="Do you want to proceed installing packages? [y/n] "
  read -n1 -r -p "$prompt" input </dev/tty

  case $input in
  [Yy])
    echo
    install_packages
    ;;
  [Nn]) interrupt_handler ;;
  *)
    reset_prompt
    prompt_for_packages && return
    ;;
  esac
  return
}

# At this point we already updated our pacman/apt-get/brew to latest version.
install_packages() {
  if macos; then
    setup/brew/init.sh --no-confirm
  elif arch; then
    setup/arch/packages.sh
  fi
}

echo
echo "5. $(underline "PACKAGES")"
echo

save_cursor
prompt_for_packages
setup/mise/init.sh

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  reset_prompt
  echo "✓ $(fgreen "Packages installed")"
else
  fail "x $(fred "Something went wrong during step 5.")"
fi
