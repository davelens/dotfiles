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
CNONE="$(tput sgr0)"     # Unsets color to term's fg color.
CBOLD="$(tput bold)"     # Bold
CEM="$(tput sitm)"       # Start italic mode
CNEM="$(tput ritm)"      # Reset italic mode
CUN="$(tput smul)"       # Start underline mode
CNUN="$(tput rmul)"      # Reset underline mode
CSTR="$(printf '\e[9m')" # Start strikethrough mode
export CNONE CBOLD CEM CNEM CUN CNUN CSTR

# Foreground colors
FGK="$(tput setaf 0)" # black
FGR="$(tput setaf 1)" # red
FGG="$(tput setaf 2)" # green
FGY="$(tput setaf 3)" # yellow
FGB="$(tput setaf 4)" # blue
FGM="$(tput setaf 5)" # magenta
FGC="$(tput setaf 6)" # cyan
FGW="$(tput setaf 7)" # white
export FGK FGR FGG FGY FGB FGM FGC FGW

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

BFGK=$CBOLD$FGK # Bold black
BFGR=$CBOLD$FGR # Bold red
BFGG=$CBOLD$FGG # Bold green
BFGY=$CBOLD$FGY # Bold yellow
BFGB=$CBOLD$FGB # Bold blue
BFGM=$CBOLD$FGM # Bold magenta
BFGC=$CBOLD$FGC # Bold cyan
BFGW=$CBOLD$FGW # Bold white
export BFGK BFGR BFGG BFGY BFGB BFGM BFGC BFGW
