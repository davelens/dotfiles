#!/usr/bin/env bash
. ~/.local/bin/tmux/helpers.sh

battery_info()
{
  # Slightly modified from https://github.com/richoH/dotfiles/blob/master/bin/battery
  battery_charging=`battery Charging`
  battery_discharging=`battery Discharging`

  if [[ $battery_charging ]]; then
    echo "$(segment "$battery_charging%" 150)"
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

    echo "$(segment "$battery_discharging%" $fgcolor $bgcolor)"
  fi
}

song_playing()
{
  song_playing=`~/.local/bin/tmux/current_track.sh`

  if [[ $song_playing ]]; then
    echo "#[fg=colour30]$song_playing"
  fi
}

segments=''
segments+=`song_playing`
segments+=`battery_info`
segments+=`product-trackers`
segments+=`crypto-tracker`
echo $segments
