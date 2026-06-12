#!/usr/bin/env fish

set ver 1.1

# Careful when rebooting a server, unattended!

# TODO
#   + Argument to supply reboot time
#   + Option to self-update
#   + Option to disable unattended reboots (by removing the file)

# variables
set REBOOT_TIME "03:45"
set conf_file /etc/apt/apt.conf.d/52unattended-reboot

printf '%-66s' "Setting up unattended reboots..."

echo > $conf_file

echo '// Automatically reboot *WITHOUT CONFIRMATION* if' >> $conf_file
echo '//  the file /var/run/reboot-required is found after the upgrade' >> $conf_file
echo 'Unattended-Upgrade::Automatic-Reboot "true";' >> $conf_file
echo >> $conf_file

echo '// Automatically reboot even if there are users currently logged in' >> $conf_file
echo '// when Unattended-Upgrade::Automatic-Reboot is set to true' >> $conf_file
echo 'Unattended-Upgrade::Automatic-Reboot-WithUsers "false";' >> $conf_file
echo >> $conf_file

echo '// If automatic reboot is enabled and needed, reboot at the specific' >> $conf_file
echo '// time instead of immediately' >> $conf_file
echo '//  Default: "now"' >> $conf_file
echo "Unattended-Upgrade::Automatic-Reboot-Time \"$REBOOT_TIME\";" >> $conf_file
echo >> $conf_file

echo done.

echo "Reboot Time: $REBOOT_TIME"
# echo To disable unattended reboots, remove the file $conf_file

echo The contents of $conf_file ...
cat $conf_file
