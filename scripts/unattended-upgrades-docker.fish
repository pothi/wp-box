#!/usr/bin/env fish

set ver 1.0

# what's done here

printf '%-72s' "Setting up unattended upgrade for Docker ..."

set apt_file /etc/apt/apt.conf.d/51unattended-upgrades-docker

set apt_origin Docker
# set apt_archive $(lsb_release -sc)

echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:\${distro_codename}\"; };" > $apt_file
# echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:$apt_archive\"; };" > $apt_file

echo done.
