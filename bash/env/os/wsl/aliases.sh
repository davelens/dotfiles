# PORT-DESKTOP supplies the path-safe Windows bridge entry points.
if dots_selected wsl-integration && [[ -z ${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-} ]]; then
  alias pbcopy >/dev/null 2>&1 || declare -F pbcopy >/dev/null || alias pbcopy='clip.exe'
  alias pbpaste >/dev/null 2>&1 || declare -F pbpaste >/dev/null || alias pbpaste="powershell.exe -NoProfile -Command Get-Clipboard"
fi
