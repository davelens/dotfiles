# Default command overrides. Generally trying to avoid serious ones, but to
# my knowledge these are not considered harmful.
alias ls='ls -G'
alias nano='vim' # 😬
alias rsync='rsync --exclude-from="${XDG_CONFIG_HOME}/rsyncignore"'
alias vim="$EDITOR" # My usecase here is that I use `dvim` as my Neovim profile.
alias vi='vim'

# Spelling corrections
# NOTE: `timesused <alias>` to find out how many times you made a mistake.
alias gti='git' 
alias sl='ls'
alias docker-compose='docker compose' # They changed it. -.-

# Shortcuts
alias be='bundle exec'
alias cdir='cd "${_%/*}"' # Fix accidentally cd'ing into a filename
alias d="utility tmux repo"
alias dc='docker compose'
alias ds='du -sh */' # Short for "directory sizes"
alias fs="ls -laSh $1 | grep -v ^d | awk '{print \$5 \"\t\" \$9}'"
alias lsa='ls -hal'
alias mysqldump='mysqldump --set-gtid-purged=OFF' # MySQL 5.6 "global-transaction-error on dump"-fix
alias s="exec $SHELL" # Used to source, hence `s`.
alias sp='eval "$(starship init bash)"' # [s]tarship [p]rompt. Trying it out!
alias ta='tmux attach'
alias trim="awk '{\$1=\$1;print}'" # Strip leading/trailing whitespace
alias u='utility'

# Jumpstart aliases for specific projects.
alias dotfiles='bash -c "utility tmux quickstart \"\$@\" -- \"$REPO_NAMESPACE/davelens/dotfiles\"" --'
alias dotvim='bash -c "utility tmux quickstart \"\$@\" -- \"$REPO_NAMESPACE/davelens/dotvim\"" --'

# Generic helpers and custom commands
alias colors='for i in {0..255} ; do printf "\x1b[38;5;${i}mcolour${i}\n"; done'
alias http='ruby -run -ehttpd . -p3000' # Run a quick & basic local HTTP server

# XDG related overrides
alias yarn='yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'
alias wget='wget --hsts-file="$XDG_CACHE_HOME/wget-hsts"'
