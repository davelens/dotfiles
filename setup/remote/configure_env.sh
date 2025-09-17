configure_env() {
  echo "TODO: Ask for:"
  echo "- Github username"
  echo "- Github email"
  echo "- Git signing key"
  echo "- GitHub personal access token"
  echo "TODO: Set ENV vars:"
  echo "- REPO_NAMESPACE"
  echo "- GITHUB_USERNAME"
  echo "- GITHUB_EMAIL"
  echo "- GITHUB_SIGNING_KEY"
  echo "- GITHUB_PERSONAL_ACCESS_TOKEN"
  echo "TODO: Ask for OWNER_NAME as well? Potentially useful for bitwarden-cli"
  echo "TODO: Generate $XDG_CONFIG_HOME/git/config.env using setup/gitconfig.env.template"
  echo
}

echo
echo "4. $(underline "CONFIGURE ENVIRONMENT")"
echo

save_cursor

configure_env

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  # TODO: Enable when the step is done.
  # reset_prompt
  echo "✓ $(fgreen "Environment configured! Remember to use $(black "dots update")")$(fgreen " once in a while")"
else
  fail "x $(fred "Something went wrong during step 4.")"
fi
