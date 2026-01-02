# Only declare functions once.
command_exists 'read_packages' && return 0

read_packages() {
  grep -v '^\s*#' "$1" | grep -v '^\s*$' | awk '{print $1}'
}
