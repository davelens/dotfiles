DEFAULT_REPO_PATH="$HOME/Repositories/$REPO_URI"

path_writeable() {
  local path="$1"
  if [ -e "$path" ]; then
    [ -w "$path" ] && return 0 || return 1
  else
    local parent
    parent="$(dirname "$path")"
    [ -w "$parent" ] && return 0 || return 1
  fi
}

path_prohibited() {
  local path="$1"
  if ! path_writeable "$path"; then
    return 0
  elif [ "$path" == "$HOME" ]; then
    return 0
  elif [ "$path" == "$HOME/Desktop" ]; then
    return 0
  elif [ -f "$path" ]; then
    return 0
  else
    return 1
  fi
}

validate_path() {
  local repo
  local path="$1"

  if path_prohibited "$path"; then
    echo -e "x $(fred 'That location is not writeable (or prohibited by me).')\n"
  else
    if [ ! -d "$path" ]; then
      echo -e "✓ $(fgreen "That folder does not exist yet, but I'll create it.")\n"
    else
      if [ -n "$(ls -A "$path")" ]; then
        if [ -f "$path/.git/config" ]; then
          repo="$(git -C "$path" repo)"

          if [ "$repo" == "$REPO_URI" ]; then
            echo -e "✓ $(fgreen "That folder already contains my dotfiles, so I'll update them instead.")\n"
          else
            echo -e "!$FGY Looks like that folder already contains the $(black "$repo")$FGY repository$CNONE\n"
          fi
        else
          echo -e "! $(fyellow "That folder is not empty. I might overwrite files. Are you sure?")\n"
        fi
      else
        echo -e "✓ $(fgreen "That folder exists and is empty.")\n"
      fi
    fi
  fi
}

ask_for_repo_namespace() {
  reset_prompt

  echo "I keep my dotfiles repo in $(black "${DEFAULT_REPO_PATH/$HOME/\~}")."
  echo

  local path="$1"
  [ "$path" == "" ] && path="$DEFAULT_REPO_PATH"
  [[ "$path" =~ "~" ]] && path="${path/\~/$HOME}"
  path="${path#\\}"

  validate_path "$path"

  if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    read -r -e -p "$BGK$FGW$path/$CNONE" choice
    choice="${choice/\~/$HOME}"
  else
    read -r -e -i "$path" -p "Please confirm: $FGB" choice
    printf %s "$CNONE"
  fi

  choice="${choice:-$repo_home}"
  [ "$choice" != "/" ] && choice="${choice%/}" # No trailing slash

  if [ "$choice" != "$path" ] || path_prohibited "$choice"; then
    ask_for_repo_namespace "$choice" && return
  fi

  DOTFILES_REPO_HOME="$choice"
}

reset_prompt

echo
echo "1. $(underline "REPO DOWNLOAD LOCATION")"
echo

save_cursor

ask_for_repo_namespace "$DEFAULT_REPO_PATH"
export DOTFILES_REPO_HOME
unset DEFAULT_REPO_PATH

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  reset_prompt
  echo "✓ $(fgreen "Repository will live in $(black "$(repo_home)")")"
else
  fail "x $(fred "Something went wrong during step 1.")"
fi
