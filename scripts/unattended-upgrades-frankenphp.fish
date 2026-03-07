#!/usr/bin/env fish

set ver 1.0

set package "FrankenPHP"
set apt_identifier frankenphp

# what's done here

# printf '%-72s' "Setting up unattended upgrade for $package..."
echo
echo "Setting up unattended upgrade for $package..."

set apt_file /etc/apt/apt.conf.d/51unattended-upgrades-$apt_identifier

set apt_origin Static-PHP
set apt_archive php-zts

if not test -f $apt_file
    echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:$apt_archive\"; };" > $apt_file
else
    echo "$apt_file exists."
end

echo
echo 'Unattended upgrade for $package is configured. Test it out with the command `unattended-upgraded --dry-run`.'


echo
echo "To disable unattended upgrades for $package, remove the file $apt_file."
echo

