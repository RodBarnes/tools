#!/usr/bin/env bash

# Use rsync to ship a copy of files from one location to another
# so that the destiination ends up being an exact copy of the source

source /usr/local/lib/display.sh

show_syntax() {
  echo "Syntax: $(basename $0) <source_diretory> [user@system:]<target_directory>"
  echo "Where:  <source_directory> is the full path to the location of the files to be tranferred."
  echo "        <target_directory> is the full path to the where the files should be transferred."
  echo "Notes:  End directory arguments with '/' to denote a directory."
  echo "        This relies upon rsync."
  exit
}

# --------------------
# ------- MAIN -------
# --------------------

if [[ $# < 2 ]]; then
  show_syntax
  exit 1
fi

source=$1
destination=$2

rsync -avz --delete --progress $source $destination
