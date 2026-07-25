#!/usr/bin/env bash
#v1.01

# This has been tested on Fedora 39 Cinnamon and works well.
# It should work under Ubuntu and downstream with little or no changes.

source /usr/local/lib/display.sh

VERSION="20260725"

show_syntax() {
  echo "Syntax: $(basename $0) <appimage> [command]"
  echo "Where:  <appimage> is the filename (without extension) of the AppImage"
  echo "        [command] is the name used to invoke the program; if omitted,"
  echo "                  it is looked up under /opt from an existing install"
  echo "                  matching this AppImage's base name (ignoring version"
  echo "                  numbers)."
  echo "NOTE:   Must be run as sudo."
  exit
}

# --------------------
# ------- MAIN -------
# --------------------

scriptname=$(basename $0)
if [[ $# < 1 ]]; then
  show_syntax
fi

if [[ "$EUID" = 0 ]]; then
  printx "This must be run as the standard user that will use the device.\nIt will prompt for sudo when it is needed.\n"
  exit
fi

filename=$1
command=$2

# Strip any extension that may've been provided
appname=$(basename $filename .AppImage)

# Confirm the AppImage can be found using the supplied filename
if [ ! -f $filename ]; then
  printx "Unable to locate specified '$filename'"
  exit
fi

# If no command was supplied, look it up under /opt from an existing
# install whose AppImage base name matches (numeric/version suffix ignored)
if [[ -z "$command" ]]; then
  prefix=$(echo "$appname" | sed -E 's/[0-9].*//')
  matches=$(find /opt -maxdepth 2 -iname "${prefix}*.AppImage" 2>/dev/null)
  nmatches=$(echo "$matches" | grep -c .)

  if [[ -z "$matches" ]]; then
    printx "No existing install found under /opt matching '$prefix*'.\nSupply <command> explicitly for a new install."
    exit
  elif [[ "$nmatches" -gt 1 ]]; then
    printx "Multiple existing installs under /opt match '$prefix*':\n$matches\nSupply <command> explicitly to disambiguate."
    exit
  fi

  command=$(basename $(dirname "$matches"))
  printx "Resolved command to '$command' from existing install."
fi

# Create the folder, move the AppImage, make it executable, and create the command
printx "Installing app..."
sudo mkdir -p /opt/$command
sudo rm -f /opt/$command/*.AppImage
sudo cp $filename /opt/$command
sudo chmod +x /opt/$command/$appname.AppImage
sudo chown root /opt/$command/$appname.AppImage
sudo chgrp root /opt/$command/$appname.AppImage
sudo ln -sf /opt/$command/$appname.AppImage /usr/local/bin/$command

# Install in menu
printx "Installing in menu..."
cd /opt/$command
sudo ./$appname.AppImage --appimage-extract 1> /dev/null
sudo chmod +xr -R ./squashfs-root
sudo cp ./squashfs-root/.DirIcon .
desktoppath=$(ls ./squashfs-root/*.desktop)
sudo sed -i "s|Exec=.*|Exec=$command|g" $desktoppath
sudo sed -i "s|Icon=.*|Icon=/opt/$command/.DirIcon|g" $desktoppath
sudo desktop-file-install --dir=/usr/local/share/applications $desktoppath
sudo update-desktop-database
sudo rm -rf ./squashfs-root

printx "Installation complete"
