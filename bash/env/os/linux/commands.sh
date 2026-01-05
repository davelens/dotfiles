# Use quicklook in debug mode to quickly display file info.
quicklook() {
  qlmanage -p "$1" >&/dev/null
}
