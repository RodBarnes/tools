#!/usr/bin/env bash

# This is designed to run on Lenovo IdeaPads which support a limited, binary
# battery conservation mode of either on (stop charging at 60%) or off (allow full charging).
# NOTE: ThinkPads support an increased capability that allows specifying the charging stop and start thresholds.
# NOTE: This scripts requires that crudini be installed.

source /usr/local/lib/display.sh

show_syntax() {
  echo "Syntax: $(basename $0) [-d|--default] [-h|--help]"
  echo "Where:  [-d|--default] will change the default value which is read at boot."
  echo "        [-h|--help] show the syntax."
  echo "        Without this flag, the change is only for the current session."
  exit
}

# --------------------
# ------- MAIN -------
# --------------------

# Get the arguments
arg_short=dh
arg_long=default,help
arg_opts=$(getopt --options "$arg_short" --long "$arg_long" --name "$0" -- "$@")
if [ $? != 0 ]; then
  show_syntax
  exit 1
fi

eval set -- "$arg_opts"
while true; do
  case "$1" in
    -d|--default)
      setdef=true
      shift 1
      ;;
    -h|--help)
      show_syntax
      shift 1
      ;;
    --) # End of options
      shift
      break
      ;;
    *)
      echo "Error parsing arguments: arg=$1"
      exit 1
      ;;
  esac
done

if [[ "$EUID" -ne 0 ]]
then
  echo 'Script must be executed by "root" or with "sudo".'
  exit
fi

states=("disabled" "enabled")

if [ $setdef ]; then
  # Change the default; this will last through a reboot
  CONFIG="/etc/tlp.conf"
  KEY="STOP_CHARGE_THRESH_BAT0"

  curstate=$(sudo crudini --get "$CONFIG" "" "$KEY" 2>/dev/null || echo "")
  if [ -z $curstate ]; then
    curstate=0
  fi
  newstate=$((1 - $curstate ))
  sudo crudini --set "$CONFIG" "" "$KEY" $newstate
  sudo systemctl restart tlp
  echo "Power conservation default has been set to ${states[$newstate]}"
else
  # Temporary change; this will not last through a reboot
  curstate=$(sudo tlp-stat -b | grep conservation_mode | cut -d' ' -f3)
  newstate=$((1 - $curstate ))
  sudo tlp setcharge 0 $newstate BAT0
  echo "Power conservation has been ${states[$newstate]}"
fi

