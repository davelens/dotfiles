#!/usr/bin/env bash

# NOTE: This file is currently only sourced as output for the Bitwarden 
# fzf preview of bin/utilities/bitwarden.
# This keeps that command a bit more readable.

function print_key_value {
  key="$1"
  value="$(eval echo \"\$$key\")"

  if [[ "$key" != "null" && ! "$value" =~ "null" ]]; then
    printf "${EM}${C}%s:${NONE} " "$key"

    if [[ "$value" == -* ]]; then
      printf "\n  %s\n" "${value//$'\n'/$'\n  '}"
    else
      printf "%s\n" "$value"
    fi
  fi
}

function uri_values {
  echo "$1" |
    jq -r "if .login.uris? then .login.uris[].uri else null end" |
    sed "s/^/- /"
}

function main {
  username=$(echo "$item" | jq -r ".login.username")
  password=$(echo "$item" | jq -r ".login.password" | sed 's/./*/g')
  notes=$(echo "$item" | jq -r ".notes")
  creationDate=$(echo "$item" | jq -r ".creationDate")
  revisionDate=$(echo "$item" | jq -r ".revisionDate")
  uris="$(uri_values "$item")"
  totp_available=$(echo "$item" | jq -r ".login.totp != null")

  # TODO: Continue working on this when we make use of totp in the future.
  if [ "$totp_available" = "true" ]; then
    clear
    totp_secret=$(echo "$item" | jq -r ".login.totp")
    if command -v oathtool &> /dev/null; then
      totp=$(oathtool --totp -b "$totp_secret")
    else
      totp=$(bw get totp "$item_id")
    fi
  else
    totp="No TOTP available for this login."
  fi

  print_key_value "username"
  print_key_value "password"
  print_key_value "totp"
  print_key_value "notes"
  print_key_value "creationDate"
  print_key_value "revisionDate"
  print_key_value "uris"
}

main
