# Simplified Git branch info formatted for bash prompts.
# Picks up on `git b` if that alias exists. This way you could inject
# your own branch logic into the prompt.
prompt_branch() {
  # Only write branch info in actual git repos.
  [ ! -d ".git" ] && return

  # The default branch retrieval in case `git b` is not available.
  #
  # Note that in this repo, `git b` is aliased to the same value as this 
  # assignment. No other reason, othern than I like having that alias on hand 
  # regardless of the prompt logic.
  local cmd="git rev-parse --abbrev-ref HEAD"
 
  # If `git b` exists as an alias, use that instead.
  if [ git config --get alias.b &>/dev/null ]; then
    cmd="git b"
  fi

  # Get the current branch or detached HEAD state
  # As an aside; `git b` used to be `git branch --show-current`, which works
  # fine for basic branch retrieval, but would not work when you're in a
  # detached HEAD state.
  current_branch=$($cmd 2>/dev/null)

  if [ "$current_branch" = "HEAD" ]; then # Detached HEAD state
    echo "(no branch selected)"

  elif [ -n "$current_branch" ]; then # Valid branch is valid
    echo "(branch: $current_branch)" 

  else # Fallback, should never see this though.
    echo "(no branch)" 
  fi
}

# This rewrites PWD to something more readable.
#   * The home directory is replaced with a ~
#   * The last pwdmaxlen characters of the PWD are displayed
#   * Leading partial directory names are stripped off
#
# Example: ${REPO_NAMESPACE}/blimp/abcdefghij
# if pwdmaxlen=25: ${REPO_NAMESPACE}/blimp/abcdefghij
# if pwdmaxlen=20: ~/blimp/abcdefghij
rewrite_pwd()
{
  # how many characters of the $PWD should remain visible.
  local pwdmaxlen=25

  # Indicate that dir truncation took place.
  local trunc_symbol=".."
  local dir=${PWD##*/} # Remove all strings until the last forward slash.

  # Make sure the last dir does not exceed $pwdmaxlen, otherwise take
  # the length of the last dir as new pwdmaxlen.
  pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))

  # Substitute $HOME with ~
  NEW_PWD=${PWD/${HOME}/"~"}

  # Calculate how many characters we have to truncate
  local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))

  # If the PWD string is too long, then we will truncate it.
  if [ ${pwdoffset} -gt "0" ]; then
    NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
    NEW_PWD=${trunc_symbol}/${NEW_PWD#*/} # Remove until the first forward slash
  fi
}

# Make sure that whenever our Terminal starts a new session, it sets $NEW_PWD
# and colorizes the prompt. Subsequent commands will pick up any changes in the
# same state we initialize here.
#
# PROMPT_COMMAND is a special environment variable in Bash. It allows you to 
# specify a command or function that gets executed just before the Bash prompt 
# is displayed. I use it to update the active working dir after every cmd.
PROMPT_COMMAND=rewrite_pwd

# Colors the root prompt red.
UC=$C
[ $UID -eq "0" ] && UC=$R

# Override the prompt with readable color vars and git branch info.
PS1="${G}\u@\h> \${NEW_PWD} ${C}\$(prompt_branch)${NONE}\n> "
