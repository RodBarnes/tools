#!/usr/bin/env bash

VERSION="20260415"

# Designed for getting/setting the brightness from the command-line

if ls /sys/class/backlight/*/brightness &>/dev/null; then
  # Backlit
  backlit=true
  curval=$(cat /sys/class/backlight/*/brightness)
  maxval=$(cat /sys/class/backlight/*/max_brightness)
else
  # Monitor
  backlit=false
  command -v ddcutil &>/dev/null || { echo "ddcutil required for interacting with montiors"; exit 1; }
  line=$(ddcutil getvcp 10)
  curval=$(echo "$line" | grep -oP 'current value =\s*\K\d+')
  maxval=$(echo "$line" | grep -oP 'max value =\s*\K\d+')
fi

echo "brightness: cur=$curval, max=$maxval; enter a new value:"
read newval
[[ -z "$newval" ]] && exit 0
[[ "$newval" =~ ^[0-9]+$ ]] || { echo "Invalid value"; exit 1; }

if [[ "$backlit" == true ]]; then
  echo "$newval" > /sys/class/backlight/*/brightness
else
  ddcutil setvcp 10 "$newval"
fi
