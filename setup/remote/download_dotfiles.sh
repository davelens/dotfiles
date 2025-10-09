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

  echo -e "Alright, I'll download the dotfiles into $(black "$(repo_home)").\n"

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

echo
echo "2. $(underline "CLONING REPOSITORY")"
echo

save_cursor

if [ -d "$DOTFILES_REPO_HOME" ]; then
  if [ ! -d "$DOTFILES_REPO_HOME/.git" ]; then
    echo -e "No .git folder present at this location, will attempt to init.\n"
    echo -e "! $(fyellow "Continuing might override files and result in data loss.")\n"

    read -n 1 -r -p "Do you want to continue? [y/n]: " yn
    case $yn in
    [Yy]*)
      echo
      git -C "$DOTFILES_REPO_HOME" init
      git -C "$DOTFILES_REPO_HOME" remote add origin git@github.com:"$REPO_URI".git
      git -C "$DOTFILES_REPO_HOME" fetch origin
      git -C "$DOTFILES_REPO_HOME" reset --hard origin/master
      git -C "$DOTFILES_REPO_HOME" branch --set-upstream-to=origin/master
      ;;
    [Nn]*) interrupt_handler ;;
    esac
  fi

  update
else
  download
fi

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  reset_prompt
  echo "✓ $(fgreen "Dotfiles are in place at $(black "$(repo_home)")")"
else
  fail "x $(fred "Something went wrong during step 2.")"
fi
