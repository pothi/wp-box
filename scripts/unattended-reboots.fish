#!/usr/bin/env fish

set ver 1.0

# Careful when rebooting a server, unattended!

# programming env: these switches turn some bugs into errors
# set -o errexit -o pipefail -o noclobber -o nounset

# what's done here

# variables
set REBOOT_TIME "03:45"

# we used ":" in sed in unattended-upgrades.sh file.
# here, since reboot time has ":" in it, we can't use ":" in sed as separator.
printf '%-72s' "Setting up unattended reboots..."

set apt_file /etc/apt/apt.conf.d/52unattended-reboot
echo > $apt_file

echo '// Automatically reboot *WITHOUT CONFIRMATION* if' >> $apt_file
echo '//  the file /var/run/reboot-required is found after the upgrade' >> $apt_file
echo 'Unattended-Upgrade::Automatic-Reboot "true";' >> $apt_file
echo >> $apt_file

echo '// Automatically reboot even if there are users currently logged in' >> $apt_file
echo '// when Unattended-Upgrade::Automatic-Reboot is set to true' >> $apt_file
echo 'Unattended-Upgrade::Automatic-Reboot-WithUsers "false";' >> $apt_file
echo >> $apt_file

echo '// If automatic reboot is enabled and needed, reboot at the specific' >> $apt_file
echo '// time instead of immediately' >> $apt_file
echo '//  Default: "now"' >> $apt_file
echo "Unattended-Upgrade::Automatic-Reboot-Time \"$REBOOT_TIME\";" >> $apt_file
echo >> $apt_file

echo done.


