#!/usr/bin/env bash
. ~/.bin/tmux/helpers.sh

segments=''
bgcolor=''
fgcolor=23

status=`cd $TMUX_PATH && hub ci-status`

fail() {
  segment "CI: $status" 208 52 'left'
}

pending() {
  segment "CI: $status" 142 30 'left'
}

success() {
  segment "CI: $status" 40 30 'left'
}

case $status in
  'failure' ) segments+=`fail`; bgcolor=52;;
  'pending' ) segments+=`pending`; bgcolor=30;;
  'success' ) segments+=`success`; bgcolor=30;;
esac

echo "#[fg=colour$fgcolor,bg=colour$bgcolor]$segments"
