#!/usr/bin/env fish

# available in two places
# frankenphp/unattended-upgrades.fish
# wp-box/scripts/unattended-upgrades-frankenphp.fish

set ver 1.1

set package "FrankenPHP"
set apt_identifier frankenphp

# what's done here

# printf '%-72s' "Setting up unattended upgrade for $package..."
echo
echo "Setting up unattended upgrade for $package..."

set apt_file /etc/apt/apt.conf.d/51unattended-upgrades-$apt_identifier

set apt_origin Static-PHP
set apt_archive php-zts

set os (grep -w ID /etc/os-release | awk -F= '{print $2}')

echo "OS: $os"

if not test -f $apt_file
    switch $os
        case ubuntu
            echo "Unattended-Upgrade::Allowed-Origins { \"$apt_origin:$apt_archive\"; };" > $apt_file
        case debian
            echo "Unattended-Upgrade::Origins-Pattern { \"o=$apt_origin,a=$apt_archive\"; };" > $apt_file
        case '*'
            echo >&2 'Unknown OS'
            exit
    end
else
    echo "$apt_file exists."
    cat $apt_file
end

echo
echo 'Unattended upgrade for $package is configured. Test it out with the command `unattended-upgraded --dry-run`.'


echo
echo "To disable unattended upgrades for $package, remove the file $apt_file."
echo

