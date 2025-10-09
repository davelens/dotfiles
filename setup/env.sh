#! /bin/sh
# $Id: form1-utf8,v 1.7 2010/01/13 10:47:35 tom Exp $

: "${DIALOG=dialog}"

: "${DIALOG_OK=0}"
: "${DIALOG_CANCEL=1}"
: "${DIALOG_HELP=2}"
: "${DIALOG_EXTRA=3}"
: "${DIALOG_ITEM_HELP=4}"
: "${DIALOG_ESC=255}"

: "${SIG_NONE=0}"
: "${SIG_HUP=1}"
: "${SIG_INT=2}"
: "${SIG_QUIT=3}"
: "${SIG_KILL=9}"
: "${SIG_TERM=15}"

case none"$LANG$LC_ALL$LC_CTYPE" in
*UTF-8*) ;;
*)
  echo "This script must be run in a UTF-8 locale"
  exit 1
  ;;
esac

backtitle="2/3: Configure GitHub"

returncode=0
while [ $returncode != 1 ] && [ $returncode != 250 ]; do
  exec 3>&1
  # Each question is its own line, followed by an input field on the next line
  value=$(
    $DIALOG --ok-label "Submit" \
      --backtitle "$backtitle" \
      --form "Please provide the following data:" \
      20 70 0 \
      \
      "1. Your GitHub username:" 1 2 "$GITHUB_USERNAME" 2 2 50 0 \
      "" 3 2 "" 3 2 0 0 \
      "2. The email associated with your GitHub account:" 4 2 "$GITHUB_EMAIL" 5 2 50 0 \
      "" 6 2 "" 6 2 0 0 \
      "3. The key you sign your commits with:" 7 2 "$GITHUB_SIGNING_KEY" 8 2 50 0 \
      "" 9 2 "" 9 2 0 0 \
      "4. Your GitHub Personal Access Token:" 10 2 "$GITHUB_PERSONAL_ACCESS_TOKEN" 11 2 50 0 \
      "" 12 2 "" 12 2 0 0 \
      2>&1 1>&3
  )
  returncode=$?
  exec 3>&-

  # Split the returned values
  GITHUB_USERNAME=$(printf '%s' "$value" | sed -n '1p')
  GITHUB_EMAIL=$(printf '%s' "$value" | sed -n '2p')
  GITHUB_SIGNING_KEY=$(printf '%s' "$value" | sed -n '3p')
  GITHUB_PERSONAL_ACCESS_TOKEN=$(printf '%s' "$value" | sed -n '4p')

  show="\
Username:              $GITHUB_USERNAME\n\
Email:                 $GITHUB_EMAIL\n\
Signing key:           $GITHUB_SIGNING_KEY\n\
Personal Access Token: $GITHUB_PERSONAL_ACCESS_TOKEN"

  case $returncode in
  "$DIALOG_CANCEL")
    "$DIALOG" \
      --clear \
      --backtitle "$backtitle" \
      --yesno "Really quit?" 10 30
    case $? in
    "$DIALOG_OK")
      break
      ;;
    "$DIALOG_CANCEL")
      returncode=99
      ;;
    esac
    ;;
  "$DIALOG_OK")
    "$DIALOG" \
      --clear \
      --backtitle "$backtitle" --no-collapse --cr-wrap \
      --msgbox "The following data will be stored:\n\n$show" 12 70
    ;;
  "$DIALOG_HELP")
    echo "Button 2 (Help) pressed."
    exit
    ;;
  "$DIALOG_EXTRA")
    echo "Button 3 (Extra) pressed."
    exit
    ;;
  *)
    # echo "Return code was $returncode"
    # exit
    ;;
  esac
done
