#!/bin/bash
. ~/.bin/tmux/helpers.sh

battery_info()
{
  # Slightly modified from https://github.com/richoH/dotfiles/blob/master/bin/battery
  battery_charging=`battery Charging`
  battery_discharging=`battery Discharging`

  if [[ $battery_charging ]]; then
    echo "$(segment "⚡ $battery_charging%" 150)"
  fi

  if [[ $battery_discharging ]]; then
    bgcolor=''

    if [[ $battery_discharging -lt 10 ]]; then
      fgcolor=208
      bgcolor=52
    elif [[ $battery_discharging -lt 25 ]]; then
      fgcolor=208
    elif [[ $battery_discharging -lt 50 ]]; then
      fgcolor=142
    elif [[ $battery_discharging -lt 75 ]]; then
      fgcolor=220
    else
      fgcolor=40
    fi

    echo "$(segment "⚡ $battery_discharging%" $fgcolor $bgcolor)"
  fi
}

song_playing()
{
  song_playing=`~/.bin/tmux/current_track.sh`

  if [[ $song_playing ]]; then
    echo "#[fg=colour30]♫ $song_playing"
  fi
}

mailcount()
{
  mailcount=`~/.bin/tmux/mailcount.sh`

  if [[ $mailcount > 0 ]]; then
    echo "$(segment "✉ $mailcount" 229 10)"
  fi
}

segments=''
segments+=`song_playing`
segments+=`mailcount`
segments+=`battery_info`
echo $segments
