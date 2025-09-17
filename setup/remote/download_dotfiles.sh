update() {
  check_repo=$(git config --get remote.origin.url 2>/dev/null |
    sed -E 's#(git@|https://)github.com[:/](.+)(\.git)?#\2#')

  if [[ "$check_repo" =~ $REPO_URI ]]; then
    if command -v git >/dev/null; then
      echo -e "Pulling changes into $DOTFILES_REPO_HOME.\n"
      git -C "$DOTFILES_REPO_HOME" pull
      printf ""
    fi

    return
  fi
}

download() {
  local dotfiles_zip extraction_dir
  dotfiles_zip="$DOTFILES_STATE_HOME/tmp/dotfiles.zip"
  extraction_dir="$(dirname "$dotfiles_zip")"

  echo -e "Alright, I'll download the dotfiles into $(blue "$(repo_home)").\n"

  if command -v git >/dev/null; then
    git clone git@github.com:davelens/dotfiles.git "$DOTFILES_REPO_HOME"
  else
    # TODO: Replace with extracting a tarball when we're starting with releases.
    curl -L -o "$dotfiles_zip" https://github.com/davelens/dotfiles/archive/refs/heads/master.zip
    unzip -o "$dotfiles_zip" -d "$extraction_dir"
    shopt -s dotglob
    mv "$extraction_dir"/dotfiles-master/* "$DOTFILES_REPO_HOME/"
    shopt -u dotglob
  fi
}

# reset_prompt
# green "✓ Downloaded dotfiles into $(repo_home)"
# save_cursor

if [ -d "$DOTFILES_REPO_HOME/.git" ]; then
  update
else
  download
fi
