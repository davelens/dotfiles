#!/bin/bash
. ~/.bin/tmux/helpers.sh

battery_info()
{
  # See https://github.com/richo/battery/blob/master/bin/battery
  battery_charging=`battery Charging`
  battery_discharging=`battery Discharging`

  if [[ $battery_charging ]]; then
    echo "$(segment "⚡ $battery_charging%" 220)"
  fi

  if [[ $battery_discharging ]]; then
    bgcolor=''

    if [[ $battery_discharging < 10 ]]; then
      fgcolor=172
      bgcolor=52
    elif [[ $battery_discharging < 25 ]]; then
      fgcolor=172
    elif [[ $battery_discharging < 50 ]]; then
      fgcolor=136
    elif [[ $battery_discharging < 75 ]]; then
      fgcolor=142
    else
      fgcolor=34
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
