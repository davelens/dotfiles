###############################################################################
# I try and adhere to the [XDG Base Directory Specification](https://xdgbasedirectoryspecification.com/).
###############################################################################

# These names are "reserved" in XDG, so make sure the dirs exist.
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
# This one isn't directly part of the spec, but I like it.
export XDG_BIN_HOME="$HOME/.local/bin"

[ ! -d "$XDG_CACHE_HOME" ] && mkdir -p "$XDG_CACHE_HOME"
[ ! -d "$XDG_CONFIG_HOME" ] && mkdir -p "$XDG_CONFIG_HOME"
[ ! -d "$XDG_DATA_HOME" ] && mkdir -p "$XDG_DATA_HOME"
[ ! -d "$XDG_STATE_HOME" ] && mkdir -p "$XDG_STATE_HOME"
[ ! -d "$XDG_BIN_HOME" ] && mkdir -p "$XDG_BIN_HOME"

# Load in specific dotfiles paths while adhering to the XDG spec.
export DOTFILES_FOLDER="dots"
export DOTFILES_CONFIG_HOME="$XDG_CONFIG_HOME/$DOTFILES_FOLDER"
export DOTFILES_STATE_HOME="$XDG_STATE_HOME/$DOTFILES_FOLDER"
export DOTFILES_CACHE_HOME="$XDG_CACHE_HOME/$DOTFILES_FOLDER"
export DOTFILES_DATA_HOME="$XDG_DATA_HOME/$DOTFILES_FOLDER"

[ ! -d "$DOTFILES_CONFIG_HOME" ] && mkdir -p "$DOTFILES_CONFIG_HOME"
[ ! -d "$DOTFILES_STATE_HOME" ] && mkdir -p "$DOTFILES_STATE_HOME/tmp"
[ ! -d "$DOTFILES_CACHE_HOME" ] && mkdir -p "$DOTFILES_CACHE_HOME"
[ ! -d "$DOTFILES_DATA_HOME" ] && mkdir -p "$DOTFILES_DATA_HOME"

# Program-specific overrides to let them follow the XDG spec.
# Some of these (HISTFILE, INPUTRC,...) could live in their respective
# categorised files in ./bash/env, but since I've set them to adhere to XDG,
# they can live here.
export ACKRC="$XDG_CONFIG_HOME/ack/ackrc"
export BASHRC="$XDG_CONFIG_HOME/bash/bashrc"
export BASH_PROFILE="$XDG_CONFIG_HOME/bash/bash_profile"
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle"
export BUNDLE_USER_CONFIG="$XDG_CONFIG_HOME/bundle/config"
export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle"
export CARGO_HOME="$XDG_DATA_HOME"/cargo
export CLAUDE_CONFIG_DIR="$XDG_CONFIG_HOME"/claude
export DIALOGRC="${XDG_CONFIG_HOME}/dialog/dialogrc"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export EDITRC="$XDG_CONFIG_HOME/editline/editrc"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export GOBIN="$XDG_BIN_HOME"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export GOPATH="$XDG_DATA_HOME/go"
export HISTFILE="$XDG_STATE_HOME/bash/history"
export INPUTRC="$XDG_CONFIG_HOME/readline/inputrc"
export IRBRC="$XDG_CONFIG_HOME/irb/irbrc"
export KODI_DATA="$XDG_DATA_HOME/kodi"
export MISE_CACHE_DIR="$XDG_CACHE_HOME/mise"
export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
export MIX_XDG="true" # So both mix and hex use XDG
export MYCLIRC="$XDG_CONFIG_HOME/mycli/myclirc"
export MYCLI_HISTFILE="$XDG_DATA_HOME/mycli/mycli-history"
export MYSQL_HISTFILE="$XDG_DATA_HOME/mysql_history"
export NETHACKOPTIONS="$XDG_CONFIG_HOME/nethack/config"
export NODE_REPL_HISTORY="$XDG_DATA_HOME/node_repl_history"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_DATA_HOME="$XDG_DATA_HOME/npm"
export PGPASSFILE="$XDG_CONFIG_HOME/pg/pgpass"
export PGSERVICEFILE="$XDG_CONFIG_HOME/pg/pg_service.conf"
export PSQLRC="$XDG_CONFIG_HOME/pg/psqlrc"
export PSQL_HISTORY="$XDG_STATE_HOME/pg/psql_history"
export REDISCLI_HISTFILE="$XDG_DATA_HOME/redis/rediscli_history"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/config.toml"
export WATSON_DIR="$XDG_CONFIG_HOME/watson"
export WGETRC="$XDG_CONFIG_HOME/wget/config"
export XCOMPOSECACHE="$XDG_CACHE_HOME/X11/xcompose"
export XCOMPOSEFILE="$XDG_CONFIG_HOME/X11/xcompose"
export XINITRC="$XDG_CONFIG_HOME/X11/xinitrc"
export XSERVERRC="$XDG_CONFIG_HOME/X11/xserverrc"

# NixOS-specific XDG settings
if [ -d "$XDG_STATE_HOME/nix" ]; then
  export NIX_STATE_DIR="$XDG_STATE_HOME/nix/profiles/profile"
fi
