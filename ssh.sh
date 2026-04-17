#!/usr/bin/env bash
# /usr/local/bin/ssh.sh — Flash-proof version for GNOME Terminal 3.52/VTE 0.76

VERSION="20260416"

TARGET="${1##*@}"
TARGET="${TARGET%%.*}"

case "$TARGET" in
  ardor)  PROFILE="ardor" ;;
  boss)   PROFILE="boss"  ;;
  brawn)  PROFILE="brawn" ;;
  deft)   PROFILE="deft" ;;
  happy)  PROFILE="happy" ;;
  bard)   PROFILE="bard" ;;
  mite)   PROFILE="mite" ;;
  shrek)  PROFILE="shrek" ;;
  *)      PROFILE="Default" ;;
esac

# Magic: -- separates options from command; bash -c ensures valid child process
gnome-terminal --profile="$PROFILE" -- bash -c "ssh \"\$@\"" -- "$@" &
