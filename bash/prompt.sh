# Git branch info for our prompt. Picks up on `git b` if that alias exists.
prompt_branch() {
  # Only write branch info in actual git repos.
  [ ! -d ".git" ] && return
  local git_branch

  if git config --get alias.b &>/dev/null; then
    git_branch=$(git b)
  else
    git_branch=$(git rev-parse --abbrev-ref HEAD)
  fi

  if [ -n "$git_branch" ]; then
    echo "(branch: $git_branch)"
  else
    echo "(no branch selected)"
  fi
}

# Rewrites PWD to something more readable. Example: $REPO_NAMESPACE/blimp/abcd
# if pwdmaxlen=25: $REPO_NAMESPACE/blimp/abcd
# if pwdmaxlen=20: ~/blimp/abcd
prompt_pwd() {
  NEW_PWD=${PWD/${HOME}/"~"} # Replace $HOME with `~`
  local char_limit=25
  local trunc_symbol=".."
  local dir=${PWD##*/} # Remove all characters until the last forward slash.

  # Make sure the last dir does not exceed $char_limit, otherwise take
  # the length of the last dir as new char_limit.
  char_limit=$(((char_limit < ${#dir}) ? ${#dir} : char_limit))

  # Calculate how many characters we have to truncate
  local pwdoffset=$((${#NEW_PWD} - char_limit))

  # If the PWD string is too long, then we will truncate it.
  if [ $pwdoffset -gt "0" ]; then
    NEW_PWD=${NEW_PWD:$pwdoffset:$char_limit}
    NEW_PWD=$trunc_symbol/${NEW_PWD#*/} # Remove until the first forward slash
  fi
}

# Use starship when available, or fall back to my homebrew.
if command -v starship >/dev/null; then
  eval "$(starship init bash)"
else
  # PROMPT_COMMAND comes with bash. It allows you to specify a command or
  # function that gets executed just before the prompt is displayed.
  PROMPT_COMMAND=prompt_pwd

  # Root prompt = red
  UC=$FGC
  # shellcheck disable=SC2034
  [ $UID -eq "0" ] && UC=$FGR

  PS1="$FGG\u@\h> \$NEW_PWD $FGC\$(prompt_branch)$CNONE\n> "
fi
