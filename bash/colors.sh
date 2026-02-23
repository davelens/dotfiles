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

# ANSI escape sequences (no subshells needed).
CNONE=$'\e[0m' # Reset all attributes
CBOLD=$'\e[1m' # Bold
CEM=$'\e[3m'   # Start italic mode
CNEM=$'\e[23m' # Reset italic mode
CUN=$'\e[4m'   # Start underline mode
CNUN=$'\e[24m' # Reset underline mode
CSTR=$'\e[9m'  # Start strikethrough mode
export CNONE CBOLD CEM CNEM CUN CNUN CSTR

# Foreground colors
FGK=$'\e[30m' # black
FGR=$'\e[31m' # red
FGG=$'\e[32m' # green
FGY=$'\e[33m' # yellow
FGB=$'\e[34m' # blue
FGM=$'\e[35m' # magenta
FGC=$'\e[36m' # cyan
FGW=$'\e[37m' # white
export FGK FGR FGG FGY FGB FGM FGC FGW

# Background colors
BGK=$'\e[40m' # black
BGR=$'\e[41m' # red
BGG=$'\e[42m' # green
BGY=$'\e[43m' # yellow
BGB=$'\e[44m' # blue
BGM=$'\e[45m' # magenta
BGC=$'\e[46m' # cyan
BGW=$'\e[47m' # white
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
