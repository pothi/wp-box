#!/usr/bin/env fish

# ref: https://github.com/mvo5/unattended-upgrades
# for external packages: https://askubuntu.com/a/1211880/65814
# https://std.rocks/gnulinux_debian_auto_update.html

set ver 1.0

# programming env: these switches turn some bugs into errors

export DEBIAN_FRONTEND=noninteractive

# what's done here

# variables

set admin_email root

printf '%-72s' "Setting up unattended upgrades..."

#--- Changes in /etc/apt/apt.conf.d/20auto-upgrades ---#
set auto_up_file /etc/apt/apt.conf.d/21auto-upgrades
# echo > $auto_up_file
echo '// Do "apt-get update" automatically every n-days (0=disable)' >> $auto_up_file
echo 'APT::Periodic::Update-Package-Lists "1";' >> $auto_up_file
echo >> $auto_up_file
echo '// Run the "unattended-upgrade" security upgrade script' >> $auto_up_file
echo '// every n-days (0=disabled)' >> $auto_up_file
echo '// Requires the package "unattended-upgrades" and will write' >> $auto_up_file
echo '// a log in /var/log/unattended-upgrades' >> $auto_up_file
echo 'APT::Periodic::Unattended-Upgrade "1";' >> $auto_up_file

#--- Changes in /etc/apt/apt.conf.d/50unattended-upgrades ---#
set apt_file /etc/apt/apt.conf.d/51unattended-upgrades
echo > $apt_file

echo 'Unattended-Upgrade::Allowed-Origins { "${distro_id}:${distro_codename}-updates"; };' >> $apt_file

# email alerts
echo "Unattended-Upgrade::Mail \"$admin_email\";" >> $apt_file

echo '// Set this value to one of:' >> $apt_file
echo '//    "always", "only-on-error" or "on-change"' >> $apt_file
echo 'Unattended-Upgrade::MailReport "only-on-error";' >> $apt_file

# Change #2.1 - compatibility with older versions Ubuntu 20.04 or below
# it is either true or false (default false)
# sed -i '/MailOnlyOnError/ s:^//U:U:' $un_up_file
# sed -i '/MailOnlyOnError/ s:".*":"true":' $un_up_file

# Change #3 - Remove unused kernel
echo 'Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";' >> $apt_file

# Change #4 - apt-get autoremove -y
echo 'Unattended-Upgrade::Remove-New-Unused-Dependencies "true";' >> $apt_file


echo done.

