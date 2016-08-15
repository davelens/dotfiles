#!/bin/bash
segment()
{
  text=$1
  fgcolor=$2
  bgcolor=$3

  if [[ "$fgcolor" == "" ]]; then
    bgcolor=23
    fgcolor=37
  fi

  if [[ "$bgcolor" == "" ]]; then
    bgcolor=23
  fi

  echo " #[fg=colour$bgcolor]#[bg=colour$bgcolor,fg=colour$fgcolor] $text"
}

