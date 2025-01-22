# Function to display status updates
show_status() {
  local status="$1"
  local message="$2"
  local symbol=""

  case "$status" in
    pending)
      symbol="$(pending)"  # Symbol for pending
      ;;
    ok)
      symbol="$(check)"  # Symbol for success (check mark)
      ;;
    error)
      symbol="$(cross)"  # Symbol for failure (cross)
      ;;
    *)
      symbol="[?]"  # Default symbol for unknown status
      ;;
  esac

  printf "\r\033[K\r%s %s" "$symbol" "$message"
}

# To help us centralize how errors look throughout our scripts.
error_handler() {
  local exit_code=$?
  echo "$(error) An error occurred. Check the log file for details: $LOG_FILE"
  exit $exit_code
}

interrupt_handler() {
  echo "$(error) Aborted."
  exit 1
}

check() {
  echo "[$(green ✓)]"
}

cross() {
  echo "[$(red x)]"
}

pending() {
  echo "[$(yellow \~)]"
}

red() {
  colorize 1 "$1"
}

green() {
  colorize 2 "$1"
}

yellow() {
  colorize 3 "$1"
}

colorize() {
  echo "$(tput setaf $1)$2$(tput sgr0)"
}
