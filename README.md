# tools
A collection of `bash` scripts for working with Linux systems.  They have been written for and tested on Linux Mint but should work on most Debian-based distros (and probably most others).  Each is intended to be instantiated within the `$PATH`, set as executable, and without the `.sh` extension.  The recommended location is `/usr/local/bin` for most of these as they are user-level tools -- exceptions noted for others.  Many (all?) of these rely upon library scripts expected to be in `/usr/local/lib`.

## appimage-install.sh
Usage: `appimage-install <name> <path_to_appimage>`

Installs the AppImage under `/opt` and adds an entry to the menu based upon the information and icon found in the AppImage.

## appimage-remove.sh
Usage: `appimage-remove <name>`

Uninstall an AppImage matching `name` that was installed using `appimage-install`.  This also removes the menu entry that was created.

## appimage-reset.sh
Usage: `appimage-reset <name>`

Resets the AppImage matching `name` that was installed using `appimage-install`.  This removes the menu entry that was created and reinstalls the AppImage.

## blkdevinfo.sh
Usage: `blkdevinfo [drive]`

Uses `smartctl` to display information about the non-removable drives found on the system.  If no drive is specified, it iterates all the drives.

## cpumode.sh
Usage: `sudo cpumode [powersave|performance|current]`

Sets or shows the current cpumode.

This should be in `/usr/local/sbin` as it is a sysadmin tool.

## device.sh
A library that includes functions for managing devices.  It is expected to be placed in `/usr/local/lib`.

## display.sh
A library that sets up some colors and functions for text.  It is expected to be placed in `/usr/local/lib`.

## devid.sh
Usage: `devid <device_label>`

Displays the corresponding device id (e.g., sda1) that matches the specified label as reported by `blikid`.

## dksm-unzstd.sh
Usage: `dkms-unzstd [<kernel>]`  If the kernel is not specified, it acts upon the current running kernel (`uname -r`).

Uncompress dkms modules and update initramfs.

The final investigation (documented in launchpad [2154307](https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2154307)) concluded the only thing needed as a workround was to uncompress the `*.ko.ztd` and then update initramfs.

## howlong.sh
Usage: `howlong <program_name> [<user>]`

Displays how long any matching process has been running.

## kernel-cleanup.sh
Usage: `sudo kernel-cleanup [--run]`

Identifies and removes orphaned kernel artifacts left behind after kernel upgrades or failed removals.  The authoritative list of kernels to retain is derived from `dpkg` (fully installed `ii`-status `linux-image-*` packages) plus the currently running kernel.  Anything not on that list is a candidate for removal.

By default the script runs in dry-run mode, displaying candidates grouped by kernel version with the source of each artifact tagged as `[apt]`, `[mod]`, or `[boot]`.  Pass `--run` to execute the cleanup: purging residual apt package fragments (`rc`-status), removing orphaned directories under `/usr/lib/modules/`, and deleting leftover files in `/boot/` (including `.dpkg-bak` and `.new` artifacts).  Files in `/boot/` that are targets of the `vmlinuz.old` or `initrd.img.old` symlinks are protected from removal.

This should be in `/usr/local/sbin` as it is a sysadmin tool.

## launch_gateway.sh
Usage: `nohup launch_gateway {browser} 2\> /dev/null`

This script can be used to bring up the gateway for logging in when that is required to connect to the internet; e.g., with hotel networks.  (With some Linux OS, this does not happen automatically.)  It is recommended this be added to a short-cut key for easy access.

## nlog.sh
Usage: `nlog <path_to_log>`

On LinuxMint, notifications are displayed but not logged.  If they aren't seen, there is no way to find out what was the notification. This captures the output into a log that is cleared when the process is started.

## session-buddy-zip & session-buddy-unzip
Usage: `session-buddy-zip <name>` or `session-buddy-unzip <name>`

Paired tools to zip or unzip the contents of the Session Buddy extension for copying to another system using the specified name.

## show_crontab_users.sh
Usage: `show_crontab_users`

Show a list of users running crontab tasks.

## show_volume_device.sh
Usage: `show_volume_device <device_label>`

Show the full device path for the device with the specified label.  This is similar to `devid.sh`

## usbinfo.sh
Usage: `usbinfo`

Select a USB from the menu and display the USB info -- size, spec, etc. -- for that device.  This relies upon `lsusb` for obtaining the info and `hdparm` for determining the speed.

## vmtoggle.sh
Usage: `vmtoggle <name>`

Specify a VM by its name and start it up or power it down.
