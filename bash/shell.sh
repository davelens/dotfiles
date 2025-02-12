########################################################################
# GENERAL
########################################################################
# dvim is currently the Neovim profile I'm using to port my Vim config to LUA.
export EDITOR=dvim

# This makes it so `gh` will use a bash shell running my default editor.
export GH_EDITOR="bash -c '${EDITOR}'"

# Make ls & grep pretty
export CLICOLOR=1

# PAGER is the path to the program used to list the contents of files through
export PAGER='less --quit-if-one-screen --no-init --ignore-case --RAW-CONTROL-CHARS --quiet --dumb'

# Stop checking shellmail for new messages
unset MAILCHECK

# Ruby GC settings
# See: https://collectiveidea.com/blog/archives/2015/02/19/optimizing-rails-for-memory-usage-part-2-tuning-the-gc
export RUBY_GC_MALLOC_LIMIT=4000100
export RUBY_GC_MALLOC_LIMIT_MAX=16000100
export RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.1
export RUBY_GC_OLDMALLOC_LIMIT=16000100
export RUBY_GC_OLDMALLOC_LIMIT_MAX=16000100

# Erlang history settings to have a cmd history in iex sessions.
export ERL_AFLAGS="-kernel shell_history enabled"

# Get rid of the forking errors triggered by spring
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES

if [ -f “${HOME}/.gpg-agent-info” ]; then
  source “${HOME}/.gpg-agent-info”
  export GPG_AGENT_INFO
  export SSH_AUTH_SOCK
fi

# So GPG signing of git commits works.
export GPG_TTY=$(tty)

# Silences the default confirmation feedback for Slackadays/Clipboard.
export CLIPBOARD_SILENT="1"


########################################################################
# HOMEBREW (the package manager)
########################################################################
# Don't force an update of all packages when target upgrading single packages.
export HOMEBREW_NO_AUTO_UPDATE=1

# Homebrew's location has changed over the years, and I still have several
# setups from different eras:
# On macos with M1 chips: /opt/homebrew
# On macos with Intel chips: /usr/local
# On *nix using Linuxbrew: /home/linuxbrew/.linuxbrew
[[ -f /opt/homebrew/bin/brew ]] && export BREW_PATH=$(/opt/homebrew/bin/brew --prefix)
[[ -f /home/linuxbrew/.linuxbrew/bin/brew ]] && export BREW_PATH=$(/home/linuxbrew/.linuxbrew/bin/brew --prefix)
[[ -f /usr/local/bin/brew ]] && export BREW_PATH=$(/usr/local/bin/brew --prefix)
[[ -f /usr/bin/brew ]] && export BREW_PATH=$(/usr/bin/brew --prefix)

# Load in all necessary brew env vars, because bash completion for `brew` won't 
# work. It specifically needs HOMEBREW_REPOSITORY, but I load in the entire 
# shellenv just in case. See: https://github.com/orgs/Homebrew/discussions/4227
eval "$(${BREW_PATH}/bin/brew shellenv)"


########################################################################
# PATH
########################################################################

# List the directories we want to add to the PATH variable, if they exist.
# The order is important, as the first directory in the list will be the first
# one to be searched (and used) for binaries.
#
# So Homebrew binaries are typically installed in the Cellar/ directory.
# If a package has multiple possible versions however, it will get symlinked 
# into the opt/ directory (e.g. python@3, mysql@8.4, ...).
#
# We *could* load in all homebrew binaries in opt/, but that would be a LOT
# of binaries added to $PATH one by one. That can't be healthy for the shell,
# and at the very least it's not readable for humans. Instead, we add specific
# packages like mysql to $PATH manually.
#
# If you want to load in all of them however, you can use this:
#
#   ${BREW_PATH}/opt/*/bin # All Homebrew binaries
#
paths_to_add=(
  ${BREW_PATH}/opt/openssl@3/bin
  ${BREW_PATH}/opt/mysql@{5.{6,7},8.4}/bin
  ${BREW_PATH}/opt/openjdk/bin
  ${BREW_PATH}/opt/gnu-getopt/{,s}bin
  ${BREW_PATH}/opt/imagemagick@6/bin
  ${BREW_PATH}/opt/bison/bin
  ${BREW_PATH}/opt/libiconv/bin
  ${BREW_PATH}/opt/m4/bin
  ${BREW_PATH}/{,s}bin # unbound in sbin/, most Homebrew binaries in bin/
  ${HOME}/.local/{,s}bin # Neovim configs, homebrew binaries
  /usr/local/{,s}bin # Docker, npm, Private Internet Access,...
  /usr/{,s}bin # User specific system binaries. A *lot* of them.
  /{,s}bin # *nix shells and binaries, and basic commands like ls, cp, echo,...
)

if [[ $OS == 'windows' ]]; then
  paths_to_add+=(
    /mnt/c/Windows/System32
    /mnt/c/Windows/System32/WindowsPowerShell/v1.0
    /mnt/c/Windows/SysWOW64
  )
fi

# Now implode everything into the new PATH variable.
printf -v PATH "%s:" "${paths_to_add[@]}"
export PATH="${PATH%:}"

# Necessary for some software to find the libraries installed by Homebrew
# during compilation.
# Both bison and libiconv are required for PHP to compile with ASDF.
export LDFLAGS="-L${BREW_PATH}/opt/bison/lib"
LDFLAGS="${LDFLAGS} -L${BREW_PATH}/opt/libiconv/lib"
LDFLAGS="${LDFLAGS} -L${BREW_PATH}/opt/mysql@8.4/lib"

export CPPFLAGS="-I${BREW_PATH}/opt/libiconv/include"
CPPFLAGS="${CPPFLAGS} -I${BREW_PATH}/opt/mysql@8.4/include"

export PKG_CONFIG_PATH="${BREW_PATH}/opt/mysql@8.4/lib/pkgconfig"

# Fixes installation of mysql2 gem due to missing openssl lib.
LIBRARY_PATH=${LIBRARY_PATH}:${BREW_PATH}/opt/openssl/lib/

# So software can pick up and load this entire config.
export SHELL=${BREW_PATH}/bin/bash

# node.js modules path
export NODE_PATH="/usr/local/share/npm/lib/node_modules"
# This is to prevent punycode deprecation logging to stderr, in particular.
export NODE_OPTIONS="--no-deprecation"

# Go lang work dir
export GOPATH=${HOME}/.go

# This makes sure asdf can configure Erlang with Homebrew's openssl pkg.
export KERL_CONFIGURE_OPTIONS="--with-ssl=$(brew --prefix openssl)"

# rbenv is a Ruby version manager.
if command -v rbenv &> /dev/null; then
  eval "$(rbenv init -)"
fi

# ASDF is a version manager for multiple languages.
if command -v asdf &> /dev/null; then
  source "${BREW_PATH}/opt/asdf/libexec/asdf.sh"
  source "${BREW_PATH}/opt/asdf/etc/bash_completion.d/asdf.bash"
fi


########################################################################
# HISTORY
########################################################################
# When the command contains an invalid history operation (for instance when
# using an unescaped "!" (I get that a lot in quick e-mails and commit
# messages) or a failed substitution (e.g. "^foo^bar" when there was no "foo"
# in the previous command line), do not throw away the command line, but let me
# correct it.
shopt -s histreedit

# Append to the history file rather than overwriting
shopt -s histappend

# Keep a reasonably long history.
export HISTSIZE=4096

# Keep even more history lines inside the file, so we can still look up
# previous commands without needlessly cluttering the current shell's history.
export HISTFILESIZE=16384

# When executing the same command twice or more in a row, only store it once.
export HISTCONTROL=ignoredups

# Keep track of the time the commands were executed.
# The xterm colour escapes require special care when piping; e.g. "| less -R".
export HISTTIMEFORMAT="${FG_BLUE}${FONT_BOLD}%Y/%m/%d %H:%M:%S${FONT_RESET} "

# let the history ignore the following commands
export HISTIGNORE="ls:lsa:ll:la:pwd:clear:h:j"

# Set up fzf key bindings and fuzzy completion
[[ ! $(which fzf) ]] && eval "$(fzf --bash)"


########################################################################
# LOCALE AND COMPLETION
########################################################################
# General case-insensitive globbing
shopt -s nocaseglob

# Do not autocomplete when accidentally pressing tab on an empty line.
shopt -s no_empty_cmd_completion

# Do not overwrite files when redirecting using ">".
# Note that you can still override this with ">|".
set -o noclobber

# Prefer English and use UTF-8.
printf -v available_locales ' %s ' $(locale -a)

for lang in en_US en_GB en; do
  for locale in "$lang".{UTF-8,utf8}; do
    if [[ "$available_locales" =~ " $locale " ]]; then
      export LC_ALL="$locale"
      export LANG="$lang"
      break 2
    fi
  done
done

unset available_locales lang locale


########################################################################
# BASH AUTOCOMPLETION
########################################################################
# Load bash_completion through brew, when installed
if [ `command -v brew` ]; then
  if [ -r "${BREW_PATH}/etc/profile.d/bash_completion.sh" ]; then
    source "${BREW_PATH}/etc/profile.d/bash_completion.sh"
  fi

  if [ -d "${BREW_PATH}/etc/bash_completion.d/" ]; then
    for completion in "${BREW_PATH}/etc/bash_completion.d/"*; do
      [ -r "${completion}" ] && source "${completion}"
    done
    unset completion
  fi
fi

# Source all downloaded completion files.
for file in "${DOTFILES_PATH}/bash/completions/"*.bash; do
  [ -r "$file" ] && source "$file"
done
unset file


########################################################################
# ENCRYPTED SALT / BITWARDEN (WIP)
########################################################################
# Salt is used to encrypt and decrypt sensitive values or files with a passkey.
#
# TODO: Add a mild warning when the salt file hasn't changed for a while.

# If the salt file is gone, we don't want to keep the old value.
if [[ ! -f "$DOTFILES_SALT_PATH" ]]; then 
  unset DOTFILES_SALT
  unset BW_SESSION
fi

#
# Outside of tmux, we ask for the salt passkey once and store it in an ENV var.
# Because I'm in tmux 24/7 I have access to DOTFILES_SALT in all my panes and 
# windows.
#
# This way we don't need to enter our Bitwarden master password beyond the
# first time, ever.
#
# TODO: This is functional but I've disabled it for now.
#
# The issue is that ENV vars (ie. DOTFILES_SALT) don't persist outside of 
# subshells.
#
# I might have to ask for the passkey to the salt every single time. It won't 
# defeat the purpose of having a salt
#
# `utility misc screenshot` would ask for a passkey every time, for instance.
#
#if [[ -z $TMUX ]]; then
  #salt=$(salt current)

  #if [[ $? -eq 0 ]]; then
    #export DOTFILES_SALT="$salt"

    #if [[ -z $BW_SESSION ]]; then
      #export BW_SESSION="$(utility misc bitwarden unlock)"
    #fi
  #else
    #print-status -i error "Encrypted salt not ready; possibly wrong passkey."
  #fi
#fi
