# Largely inspired by http://mywiki.wooledge.org/BashFAQ/037

# di = directory
# fi = file
# ln = symbolic link
# pi = fifo file
# so = socket file
# bd = block (buffered) special file
# cd = character (unbuffered) special file
# or = symbolic link pointing to a non-existent file (orphan)
# mi = non-existent file pointed to by a symbolic link (visible when you type ls -l)
# ex = file which is executable (ie. has 'x' set in permissions).
# *.rpm = files with the ending .rpm
if [[ ! "$LS_COLORS" =~ "di=0;34:" ]]; then
  LS_COLORS=$LS_COLORS:"di=0;34:":"*.rb=0;35:"
  export LS_COLORS
fi

# This seems to be more consistent than \033[0m
NONE="$(tput sgr0)"     # Unsets color to term's fg color.
B="$(tput bold)"        # Bold
EM="$(tput sitm)"       # Start italic mode
NEM="$(tput ritm)"      # Reset italic mode
UN="$(tput smul)"       # Start underline mode
NUN="$(tput rmul)"      # Reset underline mode
STR="$(printf '\e[9m')" # Start strikethrough mode
export NONE EM NEM UN NUN STR

# Background colors
BGK="$(tput setab 0)" # black
BGR="$(tput setab 1)" # red
BGG="$(tput setab 2)" # green
BGY="$(tput setab 3)" # yellow
BGB="$(tput setab 4)" # blue
BGM="$(tput setab 5)" # magenta
BGC="$(tput setab 6)" # cyan
BGW="$(tput setab 7)" # white
export BGK BGR BGG BGY BGB BGM BGC BGW

K="$(tput setaf 0)" # black
R="$(tput setaf 1)" # red
G="$(tput setaf 2)" # green
Y="$(tput setaf 3)" # yellow
B="$(tput setaf 4)" # blue
M="$(tput setaf 5)" # magenta
C="$(tput setaf 6)" # cyan
W="$(tput setaf 7)" # white
export K R G Y B M C W

BK=${BOLD}$K   # Bold black
BR=${BOLD}${R} # Bold red
BG=${BOLD}${G} # Bold green
BY=${BOLD}${Y} # Bold yellow
BB=${BOLD}${B} # Bold blue
BM=${BOLD}${M} # Bold magenta
BC=${BOLD}${C} # Bold cyan
BW=${BOLD}${W} # Bold white
export BK BR BG BY BB BM BC BW
