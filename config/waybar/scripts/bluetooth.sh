#!/usr/bin/env bash
#
# Original script taken from Jesse Mirabel, then changed to have a direct
# d-bus integration, and an expanded bluetooth device list.
#
# Requirements:
#   bluetoothctl (bluez-utils)
#   fzf
#   notify-send (libnotify)

RED="\e[31m"
RESET="\e[39m"

TIMEOUT=10

# Wrapper for bluetoothctl that works reliably after sleep
# Uses interactive mode with piped commands instead of one-shot mode
btctl() {
  echo "$1" | bluetoothctl 2>/dev/null | grep -v '^\[' | grep -v '^Agent' | grep -v '^Waiting'
}

# Get property from D-Bus (more reliable than bluetoothctl after sleep)
get_adapter_property() {
  busctl get-property org.bluez /org/bluez/hci0 org.bluez.Adapter1 "$1" 2>/dev/null | awk '{print $2}'
}

get_device_property() {
  local mac="$1" prop="$2"
  local path="/org/bluez/hci0/dev_${mac//:/_}"
  busctl get-property org.bluez "$path" org.bluez.Device1 "$prop" 2>/dev/null | sed 's/^[bs] "\?\([^"]*\)"\?$/\1/' | xargs -0 printf '%b'
}

ensure-on() {
  local powered
  powered=$(get_adapter_property "Powered")

  if [[ "$powered" == "false" ]]; then
    # Check if soft-blocked
    if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
      rfkill unblock bluetooth
      sleep 1
    fi

    btctl "power on" >/dev/null

    local i
    for ((i = 1; i <= TIMEOUT; i++)); do
      printf "\rPowering on Bluetooth... (%d/%d)" $i $TIMEOUT
      powered=$(get_adapter_property "Powered")
      if [[ "$powered" == "true" ]]; then
        break
      fi
      sleep 1
    done

    if [[ "$powered" != "true" ]]; then
      notify-send "Bluetooth" "Failed to power on" -i "package-purge"
      return 1
    fi

    notify-send "Bluetooth On" -i "network-bluetooth-activated" \
      -h string:x-canonical-private-synchronous:bluetooth
  fi
}

get-device-list() {
  # Start scanning - keep bluetoothctl running to maintain scan
  coproc BTSCAN { bluetoothctl; }
  echo "scan on" >&"${BTSCAN[1]}"

  local i num
  for ((i = 1; i <= TIMEOUT; i++)); do
    printf "\rScanning for devices... (%d/%d)\n" $i $TIMEOUT
    printf "%bPress [q] to stop%b\n" "$RED" "$RESET"

    # Count devices via D-Bus
    num=$(busctl tree org.bluez 2>/dev/null | grep -c '/org/bluez/hci0/dev_')
    printf "\nDevices: %s" "$num"
    printf "\e[0;0H"

    read -rsn 1 -t 1
    if [[ $REPLY == [Qq] ]]; then
      break
    fi
  done

  # Stop scanning
  echo "scan off" >&"${BTSCAN[1]}"
  echo "exit" >&"${BTSCAN[1]}"
  wait "$BTSCAN_PID" 2>/dev/null

  printf "\n%bScanning stopped.%b\n\n" "$RED" "$RESET"

  # Get device list via D-Bus
  local list_connected="" list_other=""
  local devices
  devices=$(busctl tree org.bluez 2>/dev/null | grep -oP '/org/bluez/hci0/dev_[A-F0-9_]+' | sort -u)

  for dev in $devices; do
    local mac name connected paired rssi
    mac=$(echo "$dev" | grep -oP 'dev_\K[A-F0-9_]+' | tr '_' ':')
    name=$(busctl get-property org.bluez "$dev" org.bluez.Device1 Alias 2>/dev/null | sed 's/^s "\(.*\)"$/\1/' | xargs -0 printf '%b')
    [[ -z "$name" ]] && name="Unknown"

    connected=$(busctl get-property org.bluez "$dev" org.bluez.Device1 Connected 2>/dev/null | awk '{print $2}')
    paired=$(busctl get-property org.bluez "$dev" org.bluez.Device1 Paired 2>/dev/null | awk '{print $2}')
    rssi=$(busctl get-property org.bluez "$dev" org.bluez.Device1 RSSI 2>/dev/null | awk '{print $2}')
    [[ -z "$rssi" ]] && rssi="-999"

    if [[ "$connected" == "true" ]]; then
      list_connected+="$mac [connected] $name"$'\n'
    elif [[ "$paired" == "true" ]]; then
      # Use rssi for sorting (pad with leading zeros for proper sort)
      printf -v rssi_padded "%04d" $((rssi + 1000))
      list_other+="${rssi_padded}|$mac [paired]    $name"$'\n'
    else
      printf -v rssi_padded "%04d" $((rssi + 1000))
      list_other+="${rssi_padded}|$mac            $name"$'\n'
    fi
  done

  # Sort by RSSI (descending - strongest first) and remove sort key
  list_other=$(echo -n "$list_other" | sort -t'|' -k1 -rn | cut -d'|' -f2-)

  list="${list_connected}${list_other}"
  list="${list%$'\n'}"

  if [[ -z "$list" ]]; then
    notify-send "Bluetooth" "No devices found" -i "package-broken"
    return 1
  fi
}

select-device() {
  local header
  header=$(printf "%-17s %-11s %s" "Address" "Status" "Name")

  local options=(
    "--border=sharp"
    "--border-label= Bluetooth Devices "
    "--ghost=Search"
    "--header=$header"
    "--height=~100%"
    "--highlight-line"
    "--info=inline-right"
    "--pointer="
    "--reverse"
  )

  address=$(fzf "${options[@]}" <<<"$list" | awk '{print $1}')
  if [[ -z $address ]]; then
    return 1
  fi

  local connected
  connected=$(get_device_property "$address" "Connected")

  if [[ $connected == "true" ]]; then
    notify-send "Bluetooth" "Already connected to this device" \
      -i "package-install"
    return 1
  fi
}

pair-and-connect() {
  local paired connected
  paired=$(get_device_property "$address" "Paired")

  if [[ $paired == "false" ]]; then
    printf "Connecting (will pair if needed)..."

    # Try connect first - many devices (like Apple keyboards) pair implicitly
    timeout $TIMEOUT bash -c "echo 'connect $address' | bluetoothctl" >/dev/null 2>&1
    sleep 1

    connected=$(get_device_property "$address" "Connected")
    if [[ $connected == "true" ]]; then
      notify-send "Bluetooth" "Successfully connected" -i "package-install"
      return 0
    fi

    # If connect failed, try explicit pair then connect
    printf "\nDirect connect failed, trying explicit pair..."
    timeout $TIMEOUT bash -c "echo 'pair $address' | bluetoothctl" >/dev/null 2>&1
    sleep 1

    paired=$(get_device_property "$address" "Paired")
    if [[ $paired == "false" ]]; then
      notify-send "Bluetooth" "Failed to pair" -i "package-purge"
      return 1
    fi
  fi

  printf "\nConnecting..."

  timeout $TIMEOUT bash -c "echo 'connect $address' | bluetoothctl" >/dev/null 2>&1
  sleep 1

  connected=$(get_device_property "$address" "Connected")
  if [[ $connected != "true" ]]; then
    notify-send "Bluetooth" "Failed to connect" -i "package-purge"
    return 1
  fi

  notify-send "Bluetooth" "Successfully connected" -i "package-install"
}

main() {
  printf "\e[?25l"
  ensure-on || exit 1
  get-device-list || exit 1
  printf "\e[?25h"
  select-device || exit 1
  pair-and-connect || exit 1
}

main
