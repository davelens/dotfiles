#!/usr/bin/env bash
segment()
{
  text=$1
  fgcolor=$2
  bgcolor=$3
  lr=$4

  if [[ "$fgcolor" == "" ]]; then
    bgcolor=23
    fgcolor=37
  fi

  if [[ "$bgcolor" == "" ]]; then
    bgcolor=23
  fi

  if [[ "$lr" == 'left' ]]; then
    echo "#[bg=colour$bgcolor,fg=colour$fgcolor] $text #[bg=colour0,fg=colour$bgcolor]"
  else
    echo " #[fg=colour$bgcolor]#[bg=colour$bgcolor,fg=colour$fgcolor] $text"
  fi
}
