# Largely inspired by http://mywiki.wooledge.org/BashFAQ/037

# This seems to be more consistent than \033[0m
export NONE=$(tput sgr0)      # Unsets color to term's fg color.
export EM=$(tput bold)        # Bold
export EM=$(tput sitm)        # Start italic mode
export NEM=$(tput ritm)       # Reset italic mode
export UN=$(tput smul)        # Start underline mode
export NUN=$(tput rmul)       # Reset underline mode
export STR=$(printf '\e[9m')  # Start strikethrough mode

# Background colors
export BGK=$(tput setab 0)    # black
export BGR=$(tput setab 1)    # red
export BGG=$(tput setab 2)    # green
export BGY=$(tput setab 3)    # yellow
export BGB=$(tput setab 4)    # blue
export BGM=$(tput setab 5)    # magenta
export BGC=$(tput setab 6)    # cyan
export BGW=$(tput setab 7)    # white

export K=$(tput setaf 0)      # black
export R=$(tput setaf 1)      # red
export G=$(tput setaf 2)      # green
export Y=$(tput setaf 3)      # yellow
export B=$(tput setaf 4)      # blue
export M=$(tput setaf 5)      # magenta
export C=$(tput setaf 6)      # cyan
export W=$(tput setaf 7)      # white

export BK=${BOLD}${K}         # Bold black
export BR=${BOLD}${R}         # Bold red
export BG=${BOLD}${G}         # Bold green
export BY=${BOLD}${Y}         # Bold yellow
export BB=${BOLD}${B}         # Bold blue
export BM=${BOLD}${M}         # Bold magenta
export BC=${BOLD}${C}         # Bold cyan
export BW=${BOLD}${W}         # Bold white
