#!/bin/bash

segments=''
# See https://github.com/richo/battery/blob/master/bin/battery
battery_charging=`battery Charging`
battery_discharging=`battery Discharging`
song_playing=`~/.bin/tmux/current_track.sh`

if [[ $song_playing ]]; then
  segments+="#[fg=cyan]♫ $song_playing"
fi

if [[ $battery_charging ]]; then
  segments+=" #[fg=yellow]#[fg=default]#[bg=yellow] ⚡ $battery_charging%#[fg=green] "
fi

if [[ $battery_discharging ]]; then
  segments+=" #[fg=red]#[bg=red,fg=white] ⚡ $battery_discharging%#[bg=red] "
fi

echo $segments
