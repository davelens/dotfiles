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
  local path="$1"

  if path_prohibited "$path"; then
    echo -e "x $(fred 'That location is not writeable (or prohibited by me).')\n"
  else
    if [ ! -d "$path" ]; then
      echo -e "✓ $(fgreen "That folder does not exist yet, but I'll create it.")\n"
    else
      if [ -n "$(ls -A "$path")" ]; then
        if [ -f "$path/.git/config" ]; then
          if grep -q "$REPO_URI" "$path/.git/config"; then
            echo -e "✓ $(fgreen "That folder already contains my dotfiles, so I'll update them instead.")\n"
          else
            echo -e "! $(fyellow "Looks like that folder already contains the \`$REPO_URI\` repository.")\n"
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
}

reset_prompt

echo
echo "Hi! My name's Dave. Looks like you're about to install my dotfiles."
echo
echo "By default I keep the repo in $(black "${DEFAULT_REPO_PATH/$HOME/\~}")."
echo

save_cursor
ask_for_repo_namespace "$DEFAULT_REPO_PATH"
unset DEFAULT_REPO_PATH
