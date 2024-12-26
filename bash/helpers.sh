# Exports all ENV vars listed in a file. Loads ~/.env by default.
export-env-vars-from-file() {
  env_file=${1:-.env}
  [[ -f $env_file ]] && export $(cat $env_file | grep -v ^\# | xargs)
}

# One generic command to extract most compressed files.
extract() {
  if [ -f $1 ]; then
    case $1 in
      *.tar.bz2)   tar xjf $1     ;;
      *.tar.gz)    tar xzf $1     ;;
      *.bz2)       bunzip2 $1     ;;
      *.rar)       unrar e $1     ;;
      *.gz)        gunzip $1      ;;
      *.tar)       tar xf $1      ;;
      *.tbz2)      tar xjf $1     ;;
      *.tgz)       tar xzf $1     ;;
      *.zip)       unzip $1       ;;
      *.Z)         uncompress $1  ;;
      *.7z)        7z x $1        ;;
      *)     echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Helps us hard stop our custom executables during fails.
fail() {
  printf '%s\n' "$1" >&2 # Sends a message to stderr.
  exit "${2-1}" # Returns a code specified by $2 or 1 by default.
}

# Flattens any string you give it. Made to format user input like Y/N -> y/n.
lowercase()
{
  if [ -n "$1" ]; then
    echo "$1" | tr "[:upper:]" "[:lower:]"
  else
    cat - | tr "[:upper:]" "[:lower:]"
  fi
}

# Find the process ID of a given command. Note that you can use regex as well.
# 
#   pid '/d$/' 
#
# Would find pids of all processes with names ending in 'd'
pid() { 
  lsof -t -c "$@"
}

# A basic spinner to indicate a process is running.
#
# Example usage:
# (sleep 5) &
# pid=$!
# spinner $pid "Processing your request..."
# wait $pid  # Halts the script until the process is done
#
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  local msg="$2"

  # Display spinner while process with PID $pid is running
  echo -n "$msg "

  while [ -d /proc/$pid ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done

  printf "    \b\b\b\b"  # Clear spinner once done
}

# Bootstrap an ssh-agent and add your default key to it.
ssh-agent-bootstrap() {
  # Start the SSH agent unless it's already running.
  [ ! -n "$SSH_AUTH_SOCK" ] && eval $(ssh-agent -s) >/dev/null

  # Only add our key if it's not already added.
  ssh-add -l | grep -q ~/.ssh/id_rsa || ssh-add ~/.ssh/id_rsa >/dev/null 2>&1
}

# Because we all want to know how many times we actually typed "gti" instead 
# of "git".
timesused()
{
  [[ -f ${HOME}/.bash_history ]] && grep -c "^${1}" ${HOME}/.bash_history
}
