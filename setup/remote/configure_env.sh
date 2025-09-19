ask_questions() {
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
  echo "TODO: Generate $XDG_CONFIG_HOME/git/config.env using setup/gitconfig.env.template"
  echo
}

bw_github() {
  bw list items --search "GitHub" --session "$(bw_session)"
}

bw_session() {
  if [ "$(bw status | jq '.status')" == '"unauthenticated"' ]; then
    BW_SESSION=$(bw login --raw)
  fi

  if [ -z "$BW_SESSION" ]; then
    BW_SESSION=$(bw unlock --raw)
    export BW_SESSION
  fi

  echo "$BW_SESSION"
}

use_bitwarden() {
  ! command -v bw >/dev/null && brew install bitwarden-cli

  github_data="$(bw_github)"
  GITHUB_PERSONAL_ACCESS_TOKEN=$(echo "$github_data" | jq -r '.[].fields | map(select(.name == "Personal access token"))[0].value')
  GITHUB_USERNAME=$(echo "$github_data" | jq -r '.[].fields | map(select(.name == "Public username"))[0].value')
  GITHUB_EMAIL=$(echo "$github_data" | jq -r '.[].login.username')
}

main() {
  local env_file="$DOTFILES_CONFIG_HOME/env"

  if [ "$(uname)" == "Darwin" ]; then
    use_bitwarden
  else
    ask_questions
  fi

  declare -p \
    REPO_NAMESPACE \
    DOTFILES_REPO_HOME \
    GITHUB_EMAIL \
    GITHUB_USERNAME \
    GITHUB_PERSONAL_ACCESS_TOKEN |
    sed 's/declare --/declare -x/g' >"$env_file"
}

save_cursor

echo
echo "4. $(underline "CONFIGURE ENVIRONMENT")"
echo

main "$@"

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  # TODO: Enable when the step is done.
  # reset_prompt
  echo "✓ $(fgreen "Environment configured! Remember to use $(black "dots update")")$(fgreen " once in a while")"
else
  fail "x $(fred "Something went wrong during step 4.")"
fi
