###############################################################################
# I try and adhere to the [XDG Base Directory Specification](https://xdgbasedirectoryspecification.com/).
###############################################################################

# Calculate locations only; the configuration installer owns directory creation.
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# This one isn't directly part of the spec, but I like it.
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# Load in specific dotfiles paths while adhering to the XDG spec.
export DOTFILES_FOLDER="dots"
export DOTFILES_CONFIG_HOME="$XDG_CONFIG_HOME/$DOTFILES_FOLDER"
export DOTFILES_STATE_HOME="$XDG_STATE_HOME/$DOTFILES_FOLDER"
export DOTFILES_CACHE_HOME="$XDG_CACHE_HOME/$DOTFILES_FOLDER"
export DOTFILES_DATA_HOME="$XDG_DATA_HOME/$DOTFILES_FOLDER"

# Program-specific overrides to let them follow the XDG spec.
# Some of these (HISTFILE, INPUTRC,...) could live in their respective
# categorised files in ./bash/env, but since I've set them to adhere to XDG,
# they can live here.
export ACKRC="${ACKRC:-$XDG_CONFIG_HOME/ack/ackrc}"
export BASHRC="${BASHRC:-$XDG_CONFIG_HOME/bash/bashrc}"
export BASH_PROFILE="${BASH_PROFILE:-$XDG_CONFIG_HOME/bash/bash_profile}"
export BUNDLE_USER_CACHE="${BUNDLE_USER_CACHE:-$XDG_CACHE_HOME/bundle}"
export BUNDLE_USER_CONFIG="${BUNDLE_USER_CONFIG:-$XDG_CONFIG_HOME/bundle/config}"
export BUNDLE_USER_PLUGIN="${BUNDLE_USER_PLUGIN:-$XDG_DATA_HOME/bundle}"
export CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
export CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$XDG_CONFIG_HOME/claude}"
export DIALOGRC="${DIALOGRC:-${XDG_CONFIG_HOME}/dialog/dialogrc}"
export DOCKER_CONFIG="${DOCKER_CONFIG:-$XDG_CONFIG_HOME/docker}"
export EDITRC="${EDITRC:-$XDG_CONFIG_HOME/editline/editrc}"
export GNUPGHOME="${GNUPGHOME:-$XDG_DATA_HOME/gnupg}"
export GOBIN="${GOBIN:-$XDG_BIN_HOME}"
export GOMODCACHE="${GOMODCACHE:-$XDG_CACHE_HOME/go/mod}"
export GOPATH="${GOPATH:-$XDG_DATA_HOME/go}"
export HISTFILE="${HISTFILE:-$XDG_STATE_HOME/bash/history}"
export INPUTRC="${INPUTRC:-$XDG_CONFIG_HOME/readline/inputrc}"
export IRBRC="${IRBRC:-$XDG_CONFIG_HOME/irb/irbrc}"
export KODI_DATA="${KODI_DATA:-$XDG_DATA_HOME/kodi}"
export MISE_CACHE_DIR="${MISE_CACHE_DIR:-$XDG_CACHE_HOME/mise}"
export MISE_DATA_DIR="${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}"
export MIX_XDG="${MIX_XDG:-true}" # So both mix and hex use XDG
export MYCLIRC="${MYCLIRC:-$XDG_CONFIG_HOME/mycli/myclirc}"
export MYCLI_HISTFILE="${MYCLI_HISTFILE:-$XDG_DATA_HOME/mycli/mycli-history}"
export MYSQL_HISTFILE="${MYSQL_HISTFILE:-$XDG_DATA_HOME/mysql_history}"
export NETHACKOPTIONS="${NETHACKOPTIONS:-$XDG_CONFIG_HOME/nethack/config}"
export NODE_REPL_HISTORY="${NODE_REPL_HISTORY:-$XDG_DATA_HOME/node_repl_history}"
export NPM_CONFIG_USERCONFIG="${NPM_CONFIG_USERCONFIG:-$XDG_CONFIG_HOME/npm/npmrc}"
export NPM_DATA_HOME="${NPM_DATA_HOME:-$XDG_DATA_HOME/npm}"
export PGPASSFILE="${PGPASSFILE:-$XDG_CONFIG_HOME/pg/pgpass}"
export PGSERVICEFILE="${PGSERVICEFILE:-$XDG_CONFIG_HOME/pg/pg_service.conf}"
export PI_CODING_AGENT_DIR="${PI_CODING_AGENT_DIR:-$XDG_CONFIG_HOME/pi}"
export PSQLRC="${PSQLRC:-$XDG_CONFIG_HOME/pg/psqlrc}"
export PSQL_HISTORY="${PSQL_HISTORY:-$XDG_STATE_HOME/pg/psql_history}"
export QS_CONFIG_PATH="${QS_CONFIG_PATH:-$XDG_CONFIG_HOME/dotshell}"
export REDISCLI_HISTFILE="${REDISCLI_HISTFILE:-$XDG_DATA_HOME/redis/rediscli_history}"
export RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$XDG_CONFIG_HOME/starship/config.toml}"
export WATSON_DIR="${WATSON_DIR:-$XDG_CONFIG_HOME/watson}"
export WGETRC="${WGETRC:-$XDG_CONFIG_HOME/wget/config}"
export XCOMPOSECACHE="${XCOMPOSECACHE:-$XDG_CACHE_HOME/X11/xcompose}"
export XCOMPOSEFILE="${XCOMPOSEFILE:-$XDG_CONFIG_HOME/X11/xcompose}"
export XINITRC="${XINITRC:-$XDG_CONFIG_HOME/X11/xinitrc}"
export XSERVERRC="${XSERVERRC:-$XDG_CONFIG_HOME/X11/xserverrc}"
