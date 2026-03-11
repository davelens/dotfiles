echo "3. $(underline "SYMLINK ALL THE THINGS")"
echo

if "$DOTFILES_REPO_HOME/setup/install"; then
  DOTBOT_RAN=1
  report_step "✓ $(fgreen "Dotfiles installed and symlinked")"
  show_progress
else
  # Keep dotbot output visible so the user can see what went wrong
  fail "x $(fred "Something went wrong during step 3.")"
fi
