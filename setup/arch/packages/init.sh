#!/usr/bin/env bash
set -e

usage() {
  echo "Usage: $(basename "$0") [OPTIONS]"
  echo
  echo "Install all packages from dotfiles package lists."
  echo
  echo "Options:"
  echo "  --update    Pull in packages updates before installing"
  exit 0
}

main() {
  UPDATE=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --update)
      UPDATE=true
      shift
      ;;
    -h | --help)
      usage
      ;;
    *)
      usage
      ;;
    esac
  done

  if [[ "$UPDATE" == true ]]; then
    paru -Syu --noconfirm
    flatpak update -y
  fi

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  utility arch pacman --install-from-file "$SCRIPT_DIR/pacman.txt"
  utility arch paru --install-from-file "$SCRIPT_DIR/aur.txt"
  utility arch flatpak --install-from-file "$SCRIPT_DIR/flatpak.txt"
}

main "$@"
