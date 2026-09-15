# Defaults apply only to selected local interactive WSL integration.
if dots_selected wsl-integration && [[ -z ${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-} ]]; then
  alias pbcopy >/dev/null 2>&1 || declare -F pbcopy >/dev/null || alias pbcopy='windows-clipboard copy'
  alias pbpaste >/dev/null 2>&1 || declare -F pbpaste >/dev/null || alias pbpaste='windows-clipboard paste'
  alias open >/dev/null 2>&1 || declare -F open >/dev/null || alias open='windows-open'
  export BROWSER="${BROWSER-windows-open}"
  export GH_BROWSER="${GH_BROWSER-windows-open}"
fi
